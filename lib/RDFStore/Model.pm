# *
# *	Copyright (c) 2000 Alberto Reggiori <areggiori@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.jrc.it/LICENSE
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *		- fixed bug in new() to check if triples is HASH ref when passed by user
# *		- fixed bug in find() do avoid to  return instances of SetModel (see SchemaModel.pm also)
# *		  Now result sets are put in an object(model) of the the same type - see find()
# *             - modified add() remove() clone() duplicate() and added toString() makePrivate()
# *		  getNamespace() getLocalName() methods accordingly to rdf-api-2000-10-30
# *		- modifed new(), duplicate(), clone() and find() to support cloned models
# *		  Due the fact that Data::MagicTie does not support the clone method, when
# *		  either the triples or the index are duplicated (or cloned) the user could
# *		  specify on which HASH(es) (tied or not) to store the results (see duplicate())
# *		- modified find() to manage normal Models and indexed Models differently
# *		- added optional indirect indexing to find() i.e. the FindIndex stores just digested keys
# *		  and not the full BLOB; fetch from an index then require an additional look up in triples
# *     version 0.3
# *		- fixed bug in find(). Check the type of $t before using methods on it
# *		- added toStrawmanRDF() to serialise the model in strawman RDF for RDFStore::Parser::OpenHealth
# *		- fixed bug in create()
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *             - modified updateDigest() method accordingly to rdf-api-2000-11-13
# *     version 0.31
# *		- commented out isEmpty() check in find() due to DBMS(3) efficency problems
# *		- fixed bug in add() when adding statements with a Literal value
# *		- updated toStrawmanRDF() method
# *		- modifed add() to avoid update of existing statements
# *     version 0.4
# *		- modifed add() to return undef if the triples exists already in the database
# *		- changed way to return undef in subroutines
# *		- renamed triples hash to store
# *		- adapted to use the new Data::MagicTie interface
# *		- complete re-design of the indexing and storage method
# *		- added getOptions() method
# *		- Devon Smith <devon@taller.pscl.cwru.edu> changed getDigestBytes() to generate digests and hashes
# *               that match Stanford java ones exactly
# *		- added inheritance from RDFStore::Stanford::Digest::Digestable
# *		- removed RDFStore::Stanford::Resource inheritance
# *

package RDFStore::Model;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use Carp;
use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Digest::Digestable;
use RDFStore::Stanford::Model;
use RDFStore::Literal;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Stanford::Digest::Util;
use Data::MagicTie;

@RDFStore::Model::ISA = qw( RDFStore::Stanford::Model RDFStore::Stanford::Digest RDFStore::Stanford::Digest::Digestable );

sub new {
	my ($pkg,%params) = @_;

    	my $self = {};

    	# first find operation creates lookup table
    	$self->{nodeFactory}=(	(exists $params{nodeFactory}) &&
				(defined $params{nodeFactory}) && 
				(ref($params{nodeFactory})) &&
				($params{nodeFactory}->isa("RDFStore::Stanford::NodeFactory")) ) ? 
				$params{nodeFactory} : new RDFStore::NodeFactory();

	eval {
		# I am quite sure that Data::MagicTie and RDFStore::Model can be "merged" in the next release...
		my $shared = $params{Shared}
			if(	(exists $params{Shared}) &&
				(defined $params{Shared}) &&
				(ref($params{Shared})) &&
				($params{Shared}->isa("RDFStore::Model")) );

		# lookup tables
		$self->{resources}={}; # contains a look-up table hashCode -->URI String
		$self->{sp2o}={}; # all human sensible/readable stuff goes here  - values are bare bone strings :)
		$self->{po2s}={}; # values are first key in resources table
		$self->{so2p}={}; # values are first key in resources table

		my $orig_name = $params{Name}
			if(	(exists $params{Name}) &&
				(defined $params{Name}) &&
				($params{Name} ne '') &&
				($params{Name} !~ m/^\s+$/) );

		#unique
		delete($params{Duplicates});
		$params{Name} = $orig_name.'/resources'
			if(defined $orig_name);

		$params{Shared} = $shared->{resources_db}
			if(defined $shared);
        	$self->{resources_db} = tie %{$self->{resources}},'Data::MagicTie',%params;
		$params{Resources}=$self->{resources_db}->get_Options;

		#use duplicates for these
		$params{Duplicates}=1;

		$params{Name} = $orig_name.'/index1'
			if(defined $orig_name);
		$params{Shared} = $shared->{sp2o_db}
			if(defined $shared);
        	$self->{sp2o_db} = tie %{$self->{sp2o}},'Data::MagicTie',%params;
		$params{Index1}=$self->{sp2o_db}->get_Options;

		$params{Name} = $orig_name.'/index2'
			if(defined $orig_name);
		$params{Shared} = $shared->{po2s_db}
			if(defined $shared);
        	$self->{po2s_db} = tie %{$self->{po2s}},'Data::MagicTie',%params;
		$params{Index2}=$self->{po2s_db}->get_Options;

		$params{Name} = $orig_name.'/index3'
			if(defined $orig_name);
		$params{Shared} = $shared->{so2p_db}
			if(defined $shared);
        	$self->{so2p_db} = tie %{$self->{so2p}},'Data::MagicTie',%params;
		$params{Index3}=$self->{so2p_db}->get_Options;

		#we should either separate the Data::MagicTie options or zap the ones not needed
		delete($params{Duplicates});

		$self->{options} = \%params;

		# we keep IDs of queries :)
		$self->{result}={};
		$self->{result_db} = tie %{$self->{result}},'Data::MagicTie', Duplicates => 1;
	};
	croak "Cannot tie my database storage ".$params{Name}." :( - $! $@\n"
		if $@;

	$self->{copies}=0;

    	bless $self,$pkg;
};

sub getOptions {
	return %{$_[0]->{'options'}};
};

sub getNamespace {
        return;
};

sub getLocalName {
        return $_[0]->getURI();
};

sub toString {
        return "Model[".$_[0]->getSourceURI()."]";
};

# Set a base URI
sub setSourceURI {
	$_[0]->{uri}=$_[1];
};

# Returns current base URI setting
sub getSourceURI {
	return $_[0]->{uri};
};

# Model access
#
# Number of triples in the model
sub size {
	if(	(exists $_[0]->{options}->{Shared}) &&
		(defined $_[0]->{options}->{Shared}) ) {
		my @ids = $_[0]->{result_db}->get_dup('subjects');
		return $#ids;
	} else {
		# really not efficient :-(
		my $size = keys %{$_[0]->{po2s}}; #reset iterator
		return scalar keys %{$_[0]->{po2s}}; #count elements
	};
};

sub isEmpty {
	my $fk;
	if(	(exists $_[0]->{options}->{Shared}) &&
		(defined $_[0]->{options}->{Shared}) ) {
		$fk = $_[0]->{result_db}->{subjects}; # should be one in-memory fetch
	} else {
		#reset iterator
		my $size = keys %{$_[0]->{po2s}}; #reset iterator
		$fk = $_[0]->{po2s_db}->FIRSTKEY(); #FIRSTKEY
	};
	return (defined $fk) ? 0 : 1;
};

sub elements {
	# the problem now is with reading in-memory all the results in both cases :(
	# but we could return a tied Data::MagciTie per component that actually fetch things...
	#

	my @statements;
	if(	(exists $_[0]->{options}->{Shared}) &&
		(defined $_[0]->{options}->{Shared}) ) {
		#to be finished.....
	} else {
		my $object_code;
		foreach $object_code ( keys %{$_[0]->{sp2o}} ) {
			my $object=$_[0]->{sp2o}->{$object_code}; #FETCH
               		if(     (defined $object) &&
                		(       (ref($object)) ||
                       		( ($object =~ s/^\"//) && ($object =~ s/\"$//) ) ) ) {
                		$object = $_[0]->{nodeFactory}->createLiteral($object);
                	} elsif(        (defined $object) &&
                			(int($object)) ) {
                		$object = $_[0]->{resources}->{ $object }; #FETCH
                       		$object = $_[0]->{nodeFactory}->createResource($object)
                			if(defined $object);
                	} else {
				next;
                	};
			my ($subject_code,$predicate_code)=$_[0]->_getValuesFromLookup($object_code);
			my $subject=$_[0]->{resources}->{$subject_code}; #FETCH
			my $predicate=$_[0]->{resources}->{$predicate_code}; #FETCH
			$subject=$_[0]->{nodeFactory}->createResource($subject);
			$predicate=$_[0]->{nodeFactory}->createResource($predicate);
			push @statements, $_[0]->{nodeFactory}->createStatement($subject,$predicate,$object);
		};
	};
	return wantarray ? @statements : $statements[0];
};

# Tests if the model contains the given triple.
sub contains {
	return (	(defined $_[1]) && (ref($_[1])) && 
			($_[1]->isa("RDFStore::Stanford::Statement")) &&
			(exists($_[0]->{po2s}->{  #EXISTS
				$_[0]->_getLookupValue(  
						scalar($_[1]->predicate->hashCode()),
						scalar($_[1]->object->hashCode()) ) })) ) ? 1 : 0;
};

# Model manipulation: add, remove, find
#
# Adds a new triple to the model
sub add {
	my ($class, $subject,$predicate,$object) = @_;

	croak "Subject or Statement ".$subject." is not either instance of RDFStore::Stanford::Statement or RDFStore::Stanford::Resource"
                unless(	(defined $subject) && 
			(ref($subject)) && 
			(	($subject->isa('RDFStore::Stanford::Resource')) || 
				($subject->isa('RDFStore::Stanford::Statement')) ) );
	croak "Predicate ".$predicate." is not instance of RDFStore::Stanford::Resource"
                unless(	(not(defined $predicate)) || 
			(	(defined $predicate) &&
				(ref($predicate)) && 
				($predicate->isa('RDFStore::Stanford::Resource')) &&
				($subject->isa('RDFStore::Stanford::Resource')) ) );
	croak "Object ".$object." is not instance of RDFStore::Stanford::RDFNode"
                unless(	(not(defined $object)) || 
			( ( ( (defined $object) && 
                              (ref($object)) && 
                              ($object->isa('RDFStore::Stanford::RDFNode'))) ||
			    ( (defined $object) && 
                              ($object !~ m/^\s+$/)) ) && #should work also for BLOBs
			  ($subject->isa('RDFStore::Stanford::Resource')) &&
			  ($predicate->isa('RDFStore::Stanford::Resource')) ) );

	if( 	(defined $subject) &&
		(ref($subject)) && 
		($subject->isa("RDFStore::Stanford::Statement")) ) {
		($subject,$predicate,$object) = ($subject->subject, $subject->predicate, $subject->object);
	} elsif(	(defined $object) && 
			(!(ref($object))) ) {
			$object = $class->{nodeFactory}->createLiteral($object);
	};

	my ($subject_code,$predicate_code,$object_code) = (
                        (defined $subject) ? scalar($subject->hashCode()) : undef,
                        (defined $predicate) ? scalar($predicate->hashCode()) : undef,
                        (defined $object) ? scalar($object->hashCode()) : undef );

	my $sp_code = $class->_getLookupValue($subject_code,$predicate_code);
	my $po_code = $class->_getLookupValue($predicate_code,$object_code);
	my $so_code = $class->_getLookupValue($subject_code,$object_code);

	# store them
	# store resources if necessary - an EXISTS operation is always required
	$class->{resources}->{$subject_code} = $subject->toString		#STORE
		unless(exists $class->{resources}->{$subject_code}); 		#EXISTS
	$class->{resources}->{$predicate_code} = $predicate->toString 		#STORE
		unless(exists $class->{resources}->{$predicate_code}); 		#EXISTS

	#object_code is the same either for RDFStore::Literal or RDFStore::Resource
	$class->{resources}->{$object_code} = $object->toString			#STORE
		if(	($object->isa("RDFStore::Stanford::Resource")) &&
			(!(exists $class->{resources}->{$object_code})) );	#EXISTS

	# store indexes - we AVOID repeated values per multiple key for indexes
	# NOTE: fetch in-memory internally in Data::MagicTie if style DBMS :(
	my $obj_value = (	(ref($object)) && 
				($object->isa("RDFStore::Stanford::Resource")) ) ?
				scalar($object->hashCode()) :
				(ref($object->toString)) ?
					$object->toString : # store generic BLOBs by using Data::MagicTie :)
					'"'.$object->toString.'"';
	$class->{sp2o}->{ $sp_code } = $obj_value #STORE
		if($class->{sp2o_db}->find_dup($sp_code,$obj_value)==1); #find_dup
	$class->{po2s}->{ $po_code } = scalar($subject->hashCode()) #STORE
		if($class->{po2s_db}->find_dup($po_code,scalar($subject->hashCode()))==1); #find_dup
	$class->{so2p}->{ $so_code } = scalar($predicate->hashCode())	#STORE
		if($class->{so2p_db}->find_dup($so_code,scalar($predicate->hashCode()))==1); #find_dup

	if(	(exists $class->{options}->{Sync}) &&
		(defined $class->{options}->{Sync}) ) {
		#sync :(
		$class->{resources_db}->sync();
		$class->{sp2o_db}->sync();
		$class->{po2s_db}->sync();
		$class->{so2p_db}->sync();
	};

	$class->updateDigest($subject,$predicate,$object);
};

sub updateDigest {
	delete $_[0]->{digest};

      	#return
	#	unless(defined $_[0]->{digest});
	# see http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31
	#my $digest = $_[1]->getDigest();
      	#RDFStore::Stanford::Digest::Util::xor($_[0]->{digest}->getDigestBytes(),$digest->getDigestBytes());
};

# Removes the triple from the model
sub remove {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
                unless(	(defined $_[1]) && 
			(ref($_[1])) && 
			($_[1]->isa('RDFStore::Stanford::Statement')) );

	# NOTE: it is not really safe here - we might need to lock all the three DBs, del statement, unlock and return (TXP) :)
	# we do not zap any resource...it does not matter for the moment due we should save a lot of disk space anyway :)
	$_[0]->{sp2o_db}->del_dup( 
		$_[0]->_getLookupValue(	
			scalar($_[1]->subject->hashCode()),
			scalar($_[1]->predicate->hashCode()) ),
				(	(ref($_[1]->object)) && 
					($_[1]->object->isa("RDFStore::Stanford::Resource")) ) ?
					scalar($_[1]->object->hashCode()) :
					(ref($_[1]->object->toString)) ?
					$_[1]->object->toString : #zap BLOBs
					'"'.$_[1]->object->toString.'"' );
	$_[0]->{po2s_db}->del_dup( 
		$_[0]->_getLookupValue(	
			scalar($_[1]->predicate->hashCode()),
			scalar($_[1]->object->hashCode()) ),
				scalar($_[1]->subject->hashCode()) );
	$_[0]->{so2p_db}->del_dup( 
		$_[0]->_getLookupValue(	
			scalar($_[1]->subject->hashCode()),
			scalar($_[1]->object->hashCode()) ),
				scalar($_[1]->predicate->hashCode()) );

	if(	(exists $_[0]->{options}->{Sync}) &&
		(defined $_[0]->{options}->{Sync}) ) {
		#sync :(
		#$_[0]->{resources_db}->sync();
		$_[0]->{sp2o_db}->sync();
		$_[0]->{po2s_db}->sync();
		$_[0]->{so2p_db}->sync();
	};

	$_[0]->updateDigest($_[1]);
};

sub isMutable {
	return 1;
};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: $result = $m->find( undef, $RDF::type, new RDFStore::Resource("http://...#MyClass") );
# finds all instances of in the model
sub find {
	my ($class,$subject,$predicate,$object) = @_;

	croak "Subject ".$subject." is not instance of RDFStore::Stanford::Resource"
                unless(	(not(defined $subject)) || 
				( 	(defined $subject) &&
					(ref($subject)) && 
					($subject->isa('RDFStore::Stanford::Resource')) ) );
        croak "Predicate ".$predicate." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $predicate)) || 
				(	(defined $predicate) &&
					(ref($predicate)) && 
					($predicate->isa('RDFStore::Stanford::Resource')) ) );
        croak "Object ".$object." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $object)) || 
				(	(defined $object) &&
					(ref($object)) && 
					($object->isa('RDFStore::Stanford::RDFNode')) ) );

	# we have the same problem like in Pen - a result set must be a model/collection :-)
	my $res = $class->create(); #EMPTY MODEL

	# we avoid this because is doing a FK :) - this is check might be safely skipped anyway
        #return $res if($class->isEmpty());

	return $class->duplicate()
		if(	(not(defined $subject)) && 
			(not(defined $predicate)) && 
			(not(defined $object)) );

	# add results to the query model
	map {
#print STDERR "model_find: '".$_->toString."'\n";
		if(	(defined $subject) &&
			(defined $predicate) ) {
			$res->add($subject,$predicate,$_);
		} elsif(	(defined $subject) &&
				(defined $object) ) {
			$res->add($subject,$_,$object);
		} elsif(	(defined $predicate) &&
				(defined $object) ) {
			$res->add($_,$predicate,$object);
		};
	} $_[0]->fetchRDFNode($subject,$predicate,$object);

        return $res;
};

# Clone the model - So due that copy is epensive we use sharing :)
sub duplicate {
	my ($class) = @_;

	# create and return a model that shares store and lookup with this model
	my $self=ref($class);
	my $new = $self->new( Shared => $class ); # Shared here means a little bit different than Data::MagicTie
	return $new;
};

# Creates in-memory empty model
sub create {
	my $self = ref(shift);
	return $self->new(); #no Data::MagicTie options passed through for the moment
};

sub getNodeFactory {
	return $_[0]->{nodeFactory};	
};

sub getLabel {
	return $_[0]->getURI;
};

sub getDigest {
	return $_[0];
};

sub getURI {
	if($_[0]->isEmpty()) {
      		return $_[0]->{nodeFactory}->createUniqueResource()->toString();
    	} else {
		return "urn:rdf:".
				$_[0]->getDigestAlgorithm ."-".
				RDFStore::Stanford::Digest::Util::toHexString( $_[0]->getDigest() );
      	};
};

sub getDigestAlgorithm {
	return &RDFStore::Stanford::Digest::Util::getDigestAlgorithm();
};

sub getDigestBytes {
	unless ( defined $_[0]->{digest} ) {
        	sub digest_sorter {
            		my @a1 = unpack "c*", ${ $a->getDigest()->getDigestBytes() };
            		my @b1 = unpack "c*", ${ $b->getDigest()->getDigestBytes() };
            		my $i;
            		for ($i=0; $i < $#a1 +1; $i++) {
              			return $a1[$i] - $b1[$i] unless ord $a1[$i] == ord $b1[$i];
            		};
            		return 0;
          	};
        	my $t;
        	my $digest_bytes;
        	for  $t ( sort digest_sorter $_[0]->elements ){
          		$digest_bytes .= $ { $t->getDigest()->getDigestBytes() };
        	};
        	$_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest($_[0]->getDigestAlgorithm,
					$digest_bytes);
	};
	return $_[0]->{digest}->getDigestBytes();
};

#serialise model to strawman syntax - see XML::Parser::OpenHealth(3)
# it could return a kind of tied filehandle/stream :)
sub toStrawmanRDF {
	# here we should use RDFStore::Stanford::Vocabulary::RDF definitions....
	my $rdf= '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE rdf:RDF [ <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#"> ]><rdf:RDF xmlns:rdf="&rdf;">';
	$rdf .= "\n";

	# when here we do not have an index set :(
	foreach( $_[0]->elements ) {
		$rdf .= '<rdf:Statement rdf:ID="'.$_->getURI().'">'."\n";

		$rdf .= "\t".'<rdf:subject rdf:resource="'.$_->subject()->toString.'" />'."\n";
		$rdf .= "\t".'<rdf:predicate rdf:resource="'.$_->predicate()->toString.'" />'."\n";
		my $object = $_->object();
		# binary data is a still a problem. We might use MIME::Base64 or URI::data
		if( (defined $object) && (ref($object)) && ($object->isa("RDFStore::Stanford::Literal")) ) {
			my $s = $_->object()->toString;
			$rdf .= "\t".'<rdf:object'.
					( ($s =~ /[\&\<\>]/) ? ' xml:space="preserve"><![CDATA['.$s.']]>' : '>'.$s ).'</rdf:object>'."\n";
		} else {
			$rdf .= "\t".'<rdf:object rdf:resource="'.$_->object()->toString.'" />'."\n";
		};

		$rdf .= '</rdf:Statement>'."\n";
       	};
	$rdf .= '</rdf:RDF>';

	return $rdf;
};


#Storage related part

# NOTE: RDFStore::Literal and RDFStore::Resource generate the dame hashCode() for URI strings
sub _getLookupValue {
	my ($class) = shift;

	return join('-', map { int($_) } @_);
};

sub _getValuesFromLookup {
	my ($class) = shift;

	return split('-',$_[0]);
};

# return a list of RDFNode objects for a given (sp), (po) or (so) couple
sub fetchRDFNode {
	my ($class,$s,$p,$o) = @_;

	if(	(defined $s) &&
		($s->isa("RDFStore::Stanford::Resource")) &&
		(defined $p) &&
		($p->isa("RDFStore::Stanford::Resource")) ) {
		my $code = $class->_getLookupValue(scalar($s->hashCode()),scalar($p->hashCode()));
		# Literals are one fetch away :)
		return map {
			if(	(defined $_) &&
				(	(ref($_)) ||
					( (s/^\"//) && (s/\"$//) ) ) ) {
				$_ = $class->{nodeFactory}->createLiteral($_);
			} elsif(	(defined $_) &&
					(int($_)) ) {
				$_ = $class->{resources}->{ $_ }; #FETCH
				$_ = $class->{nodeFactory}->createResource($_)
					if(defined $_);
			} else {
				return;
			};
		} $class->{sp2o_db}->get_dup( $code );
	} elsif(	(defined $p) &&
			($p->isa("RDFStore::Stanford::Resource")) &&
			(defined $o) &&
			($o->isa("RDFStore::Stanford::RDFNode")) ) {
		my $code = $class->_getLookupValue(scalar($p->hashCode()),scalar($o->hashCode()));
		return map {
			if(	(defined $_) &&
				(int($_)) ) {
				$_ = $class->{resources}->{ $_ }; #FETCH
				$_ = $class->{nodeFactory}->createResource($_)
					if(defined $_);
			} else {
				return;
			};
		} $class->{po2s_db}->get_dup( $code );
	} elsif(	(defined $s) &&
			($s->isa("RDFStore::Stanford::Resource")) &&
			(defined $o) &&
			($o->isa("RDFStore::Stanford::RDFNode")) ) {
		my $code = $class->_getLookupValue(scalar($s->hashCode()),scalar($o->hashCode()));
		return map {
			if(	(defined $_) &&
				(int($_)) ) {
				$_ = $class->{resources}->{ $_ }; #FETCH
				$_ = $class->{nodeFactory}->createResource($_)
					if(defined $_);
			} else {
				return;
			};
		} $class->{so2p_db}->get_dup( $code );
	};
};

sub DESTROY {
	my ($class) = shift;

	undef $class->{resources_db};
	untie %{$class->{resources}};
	undef $class->{sp2o_db};
	untie %{$class->{sp2o}};
	undef $class->{po2s_db};
	untie %{$class->{po2s}};
	undef $class->{so2p_db};
	untie %{$class->{so2p}};
	undef $class->{result_db};
	untie %{$class->{result}};
};

1;
};

__END__

=head1 NAME

RDFStore::Model - An implementation of the Model RDF API

=head1 SYNOPSIS

	use RDFStore::Model;
	use RDFStore::FindIndex;
	use RDFStore::NodeFactory;
	use Data::MagicTie;

	my $factory= new RDFStore::NodeFactory();
	my $statement = $factory->createStatement(
                        	$factory->createResource('http://perl.org'),
                        	$factory->createResource('http://iscool.org/schema/1.0/','label'),
                        	$factory->createLiteral('Cool Web site')
                                );
	my $statement1 = $factory->createStatement(
				$factory->createResource("http://www.altavista.com"),
				$factory->createResource("http://pen.jrc.it/schema/1.0/','author'),
				$factory->createLiteral("Who? :-)")
				);

	my $statement2 = $factory->createStatement(
				$factory->createUniqueResource(),
				$factory->createUniqueResource(),
				$factory->createLiteral("")
				);

	my $model = new RDFStore::Model( Name => 'store', Split => 20 );

	$model->add($statement);
	$model->add($statement1);
	$model->add($statement2);
	my $model1 = $model->duplicate();

	print $model1->getDigest->equals( $model1->getDigest );
	print $model1->getDigest->hashCode;

	my $found = $model->find($statement2->subject,undef,undef);

	#get Statements
	foreach ( $found->elements ) {
        	print $_->getLabel(),"\n";
	};

	#get RDFNodes
	foreach ( keys %{$found->elements}) {
        	print $found->elements->{$_}->getLabel(),"\n";
	};

=head1 DESCRIPTION

An RDFStore::Stanford::Model implementation using Data::MagicTie tied arrays and hashes to store triplets. The actual store could be tied either to an in-memory, a local or remote database - see Data::MagicTie(3).

This modules implements a storage and iterator by leveraging on perltie(3) and the Data::MagicTie(3) interface.

=head1 CONSTRUCTORS
 
The following methods construct/tie RDFStore::Model storages and objects:

=item $model = new RDFStore::Model( %whateveryoulikeit );
 
Create an new RDFStore::Model object and tie up a serie of Data::MagicTie hash databases to read/write/query RDFStore::RDFNode. The %whateveryoulikeit hash contains a set of configuration options about how and where store actual data. Most of the options correspond to the Data::MagicTie ones - see Data::MagicTie(3)
Possible additional options are the following:
 
=over 4
 
=item Name
 
This is a label used to identify a B<Persistent> storage by name. It might correspond to a physical file system directory containing the indexes DBs. By default if no B<Name> option is given the storage is assumed to be B<in-memory> (e.g. RDFStore::Storage::find method return result sets as in-memory models by default unless specified differently). For local persistent storages a directory named liek this option is created in the current working directory with mode 0666)

=item Sync

Sync the RDFStore::Model with the underling Data::MagciTie GDS after each add() or remove().

=item Resources, Index1, Index2 and Index3

These parameters point to the Data::MagicTie options of the underlying database.

=head1 SEE ALSO

Data::MagicTie(3) Digest(3) RDFStore::Stanford::Digest::Digestable(3) RDFStore::Stanford::Digest(3) RDFStore::RDFNode RDFStore::Resource RDFStore::FindIndex(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
