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
# *     version 0.41
# *             - updated _getLookupValue() and _getValuesFromLookup() to consider negative hashcodes
# *     version 0.42
# *		- complete redesign of the indexing method up to free-text search on literals
# *		- added tied array iterator RDFStore::Model::Statements to allow fetching results one by one
# *		- modified find() to allow a 4th paramater to make free-text search over literals
# *
# *

package RDFStore::Model;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.42';

use Carp;
use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Digest::Digestable;
use RDFStore::Stanford::Model;
use RDFStore::Literal;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Stanford::Digest::Util;
use Data::MagicTie; # the storge module

@RDFStore::Model::ISA = qw( RDFStore::Stanford::Model RDFStore::Stanford::Digest RDFStore::Stanford::Digest::Digestable );

sub new {
        my ($pkg,%params) = @_;
 
        my $self = {};
 
        # first operation creates lookup table
        $self->{nodeFactory}=(  (exists $params{nodeFactory}) &&
                                (defined $params{nodeFactory}) &&
                                (ref($params{nodeFactory})) &&
                                ($params{nodeFactory}->isa("RDFStore::Stanford::NodeFactory")) ) ?
                                $params{nodeFactory} : new RDFStore::NodeFactory();
	
        $self->{options} = \%params;

        bless $self,$pkg;
};

# connect/create/attach to the database
sub _tie {
        my ($class) = @_;
 
	return $_[0]->{Shared}->_tie
		if(	(exists $_[0]->{Shared}) &&
			(defined $_[0]->{Shared}) );
        eval {
                # lookup tables
                $class->{literals} = {}; # literals
                $class->{resources} = {}; #resources
                $class->{namespaces} = {}; #namespaces
                $class->{statements} = {}; #statements
                $class->{Windex} = {}; # a sparse 3 dimensional matrix that apply a free-text like indexing to triples
		my $orig_name = $class->{options}->{Name}
                        if(     (exists $class->{options}->{Name}) &&
                                (defined $class->{options}->{Name}) &&
                                ($class->{options}->{Name} ne '') &&
                                ($class->{options}->{Name} !~ m/^\s+$/) );
 
                #we separate the Data::MagicTie options and zap the ones not needed
                my %params = %{$class->{options}};
 
                $params{Name} = $orig_name.'/literals'
                        if(defined $orig_name);
                $class->{literals_db} = tie %{$class->{literals}},'Data::MagicTie',%params;
                $class->{options}->{Literals}=$class->{literals_db}->get_Options;

		$params{Name} = $orig_name.'/resources'
                        if(defined $orig_name);
                $class->{resources_db} = tie %{$class->{resources}},'Data::MagicTie',%params;
                $class->{options}->{Resources}=$class->{resources_db}->get_Options;
 
                $params{Name} = $orig_name.'/namespaces'
                        if(defined $orig_name);
                $class->{namespaces_db} = tie %{$class->{namespaces}},'Data::MagicTie',%params;
                $class->{options}->{Namespaces}=$class->{namespaces_db}->get_Options;

		$params{Name} = $orig_name.'/statements'
                        if(defined $orig_name);
                $class->{statements_db} = tie %{$class->{statements}},'Data::MagicTie',%params;
                $class->{options}->{Statements}=$class->{statements_db}->get_Options;
 
                #initialize statements counter(s) if necessary
                my $cnt = $class->{statements}->{add_counter}; #FETCH
                $class->{statements}->{add_counter}=-1 #STORE
                        unless(	(defined $cnt) &&
				(int($cnt)) );
                $cnt = $class->{statements}->{remove_counter}; #FETCH
                $class->{statements}->{remove_counter}=-1 #STORE
                        unless(	(defined $cnt) &&
				(int($cnt)) );
 
                $params{Name} = $orig_name.'/Windex'
                        if(defined $orig_name);
                $class->{Windex_db} = tie %{$class->{Windex}},'Data::MagicTie',%params;
                $class->{options}->{Windex}=$class->{Windex_db}->get_Options;
        };
        if($@) {
                warn "Cannot tie my database storage ".$class->{options}->{Name}." :( - $! $@\n";
                return;
        } else {
                return $class;
        };
};     

# diconnect from the database
sub _untie {
	return $_[0]->{Shared}->_untie
		if(	(exists $_[0]->{Shared}) &&
			(defined $_[0]->{Shared}) );

        delete $_[0]->{literals_db};
        untie %{$_[0]->{literals}};
        delete $_[0]->{resources_db};
        untie %{$_[0]->{resources}};
        delete $_[0]->{namespaces_db};
        untie %{$_[0]->{namespaces}};
        delete $_[0]->{statements_db};
        untie %{$_[0]->{statements}};
        delete $_[0]->{Windex_db};
        untie %{$_[0]->{Windex}};
}; 

# check if the database is connected
sub _tied {
	return $_[0]->{Shared}->_tied
		if(	(exists $_[0]->{Shared}) &&
			(defined $_[0]->{Shared}) );

        return (        (tied %{$_[0]->{literals}}) &&
                        (tied %{$_[0]->{resources}}) &&
                        (tied %{$_[0]->{namespaces}}) &&
                        (tied %{$_[0]->{statements}}) &&
                        (tied %{$_[0]->{Windex}}) ) ? 1 : 0;
};

# return model options
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

# Set a base URI for the model
sub setSourceURI {
	$_[0]->{uri}=$_[1];
};

# Returns current base URI for the model
sub getSourceURI {
	return $_[0]->{uri};
};

# model access methods

# return the number of triples in the model
sub size {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		if(exists $_[0]->{query_model_statement_ids}) {
			if($#{$_[0]->{query_model_statement_ids}}>=0) {
				return $#{$_[0]->{query_model_statement_ids}}+1; #save a FETCH
			} else {
				return 0; #got an empty query
			};
		} else {
			return $_[0]->{Shared}->size; #i.e. shared model coming from a duplicate()
		};
	};

        $_[0]->_tie
               	unless($_[0]->_tied);

        (	($_[0]->{statements}->{add_counter}+1)-($_[0]->{statements}->{remove_counter}+1)); #FETCH*2
};

# check whether or not the model is empty
sub isEmpty {
        return ($_[0]->size() > 0) ? 0 : 1;
};

# return a tied ARRAY (iterator) of statements actually in the database - see RDFStore::Model::Statements(3)
sub elements {
	my ($class,@ids) = @_;

	@ids=() #hack
		unless((caller)[0]=~/RDFStore::Model/);

	my $statements;
	if(	(exists $class->{Shared}) &&
		(defined $class->{Shared}) ) {
		return
			if(	(exists $class->{query_model_statement_ids}) &&
				($#{$class->{query_model_statement_ids}}<0) ); #we do not return empty queries

		($statements)=$class->{Shared}->elements( 
			($#ids>=0) ? 
				@ids : 
				(	(exists $class->{query_model_statement_ids}) ?
						@{$class->{query_model_statement_ids}} : () )
		);
	} else {
        	$class->_tie
        		unless($class->_tied);

		$statements=[];
        	tie @{$statements},"RDFStore::Model::Statements",$class,@ids;
	};

        return wantarray ? $statements : $statements->[0]; #FETCH one single statement in scalar context
};

# tests if the model contains a given statement
sub contains {
	if(	(exists $_[0]->{Shared}) &&
		(defined $_[0]->{Shared}) ) {
		if(exists $_[0]->{query_model_statement_ids}) {
			if($#{$_[0]->{query_model_statement_ids}}<0) {
				return 0; #got an empty query
			} else {
				my ($subject_localname_code,$subject_namespace_code) = map {
                			$_[0]->_getLookupValue($_); } $_[1]->subject->hashCode();
        			my ($predicate_localname_code,$predicate_namespace_code) = map {
                			$_[0]->_getLookupValue($_); } $_[1]->predicate->hashCode();
        			my ($object_localname_code,$object_namespace_code,$object_literal_code);
        			if(     (defined $_[1]->object) &&
                			($_[1]->object->isa("RDFStore::Stanford::Resource")) ) {
                			($object_localname_code,$object_namespace_code) = map {
                        		$_[0]->_getLookupValue($_); } $_[1]->object->hashCode();
        			} elsif(defined $_[1]->object) {
                			$object_literal_code = $_[0]->_getLookupValue($_[1]->object->hashCode());
        			};
        			my($num)=$_[0]->{Shared}->_fetchRDFNode(	$subject_localname_code,
						$subject_namespace_code,
						$predicate_localname_code,
						$predicate_namespace_code,
						$object_localname_code,
						$object_namespace_code,
						$object_literal_code);
				return (grep /^$num$/,@{$_[0]->{query_model_statement_ids}}) ? 1 : 0;
			};
		} else {
			return $_[0]->{Shared}->contains($_[1]); #i.e. shared model coming from a duplicate()
		};
	};

        $_[0]->_tie
                unless($_[0]->_tied);
 
        if(	(defined $_[1]) &&
                (ref($_[1])) &&
                ($_[1]->isa("RDFStore::Stanford::Statement")) ) {
		my ($subject_localname_code,$subject_namespace_code) = map {
                	$_[0]->_getLookupValue($_); } $_[1]->subject->hashCode();
        	my ($predicate_localname_code,$predicate_namespace_code) = map {
                	$_[0]->_getLookupValue($_); } $_[1]->predicate->hashCode();
        	my ($object_localname_code,$object_namespace_code,$object_literal_code);
        	if(     (defined $_[1]->object) &&
                	($_[1]->object->isa("RDFStore::Stanford::Resource")) ) {
                	($object_localname_code,$object_namespace_code) = map {
                        	$_[0]->_getLookupValue($_); } $_[1]->object->hashCode();
        	} elsif(defined $_[1]->object) {
                	$object_literal_code = $_[0]->_getLookupValue($_[1]->object->hashCode());
        	};
        	return ($_[0]->_fetchRDFNode(	$subject_localname_code,
						$subject_namespace_code,
						$predicate_localname_code,
						$predicate_namespace_code,
						$object_localname_code,
						$object_namespace_code,
						$object_literal_code)) ? 1 : 0;
	} else {
		return 0;
	};
};

# Model manipulation: add, remove, find
#
# NOTE: it is not really safe here - we might need to lock all DBs, add statement, unlock and return (TXP) :)
#
# Adds a new triple to the model
sub add {
        my ($class, $subject,$predicate,$object) = @_;

        croak "Subject or Statement ".$subject." is either not instance of RDFStore::Stanford::Statement or RDFStore::Stanford::Resource"
                unless( (defined $subject) &&
                        (ref($subject)) &&
                        (       ($subject->isa('RDFStore::Stanford::Resource')) ||
                                ($subject->isa('RDFStore::Stanford::Statement')) ) );
	croak "Predicate ".$predicate." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $predicate)) ||
                        (       (defined $predicate) &&
                                (ref($predicate)) &&
                                ($predicate->isa('RDFStore::Stanford::Resource')) &&
                                ($subject->isa('RDFStore::Stanford::Resource')) ) );
        croak "Object ".$object." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $object)) ||
                        ( ( ( (defined $object) &&
                              (ref($object)) &&
                              ($object->isa('RDFStore::Stanford::RDFNode'))) ||
                            ( (defined $object) &&
                              ($object !~ m/^\s+$/)) ) && #should work also for BLOBs
                          ($subject->isa('RDFStore::Stanford::Resource')) &&
                          ($predicate->isa('RDFStore::Stanford::Resource')) ) );

        if(     (defined $subject) &&
                (ref($subject)) &&
                ($subject->isa("RDFStore::Stanford::Statement")) ) {
                ($subject,$predicate,$object) = ($subject->subject, $subject->predicate, $subject->object);
        } elsif(        (defined $object) &&
                        (!(ref($object))) ) {
                        $object = $class->{nodeFactory}->createLiteral($object);
        };

        my ($subject_localname_code,$subject_namespace_code) = map {
                        $class->_getLookupValue($_); } $subject->hashCode();

        my ($predicate_localname_code,$predicate_namespace_code) = map {
                        $class->_getLookupValue($_); } $predicate->hashCode();

        my ($object_localname_code,$object_namespace_code,$object_literal_code);
        if($object->isa("RDFStore::Stanford::Resource")) {
                ($object_localname_code,$object_namespace_code) = map {
                        $class->_getLookupValue($_); } $object->hashCode();
	} else {
                $object_literal_code = $class->_getLookupValue($object->hashCode());
        };

	#we do not want want duplicates
	return
		if($class->_fetchRDFNode(	$subject_localname_code,
						$subject_namespace_code,
						$predicate_localname_code,
						$predicate_namespace_code,
						$object_localname_code,
						$object_namespace_code,
						$object_literal_code));

	$class->_tie
                unless($class->_tied);
 
	# copy across stuff if necessary
	$class->_copyOnWrite
		if(	(exists $class->{Shared}) &&
                	(defined $class->{Shared}) );

	# store the STATEMENT
	#
        # I.e.
        #
        # $class->{statements}->{ $st_num*8 } = (
        #       $subject_localname_code,
        #       $subject_namespace_code,
        #       $predicate_localname_code,
        #       $predicate_namespace_code,
        #       $object_localname_code,
        #       $object_namespace_code,
        #       $object_literal_code
	#	[,$context]	# id of statement giving context
        # );
        #
	# $class->{namespaces}->{ $predicate_namespace_code } = 'http://dublincore.org/elements/1.1/';
	#
	# $class->{resources}->{ $predicate_localname_code } = 'creator';
	#
	# $class->{literals}->{ $object_literal_code } = 'webmaster@somewhere.org';
	#
	# $class->{Windex}->{ $subject_localname_code } = 76453; # 3D sparse matrix
	# $class->{Windex}->{ $subject_namespace_code } = 24999; # and so on....
	
        # count one more - it must be atomic/fault tolerant
        my $st_id = $class->{statements_db}->inc('add_counter'); #inc

	#use 8 slots
        my $bitno=$st_id*8;
 
	# store subject LOCALNAME
        $class->{resources}->{$subject_localname_code} = $subject->getLocalName         #STORE
               	if(     (defined $subject_localname_code) &&
                       	(!(exists $class->{resources}->{$subject_localname_code})) );   #EXISTS

	# store subject NAMESPACE
       	$class->{namespaces}->{$subject_namespace_code} = $subject->getNamespace        #STORE
               	if(     (defined $subject_namespace_code) &&
                       	(!(exists $class->{namespaces}->{$subject_namespace_code})) );  #EXISTS
 
	# store predicate LOCALNAME
        $class->{resources}->{$predicate_localname_code} = $predicate->getLocalName       #STORE
               	if(     (defined $predicate_localname_code) &&
                       	(!(exists $class->{resources}->{$predicate_localname_code})) );   #EXISTS

	# store predicate NAMESPACE
       	$class->{namespaces}->{$predicate_namespace_code} = $predicate->getNamespace      #STORE
               	if(     (defined $predicate_namespace_code) &&
                       	(!(exists $class->{namespaces}->{$predicate_namespace_code})) );  #EXISTS
 
        if($object->isa("RDFStore::Stanford::Resource")) {
		# store object LOCALNAME
        	$class->{resources}->{$object_localname_code} = $object->getLocalName        #STORE
        		if(     (defined $object_localname_code) &&
               			(!(exists $class->{resources}->{$object_localname_code})) ); #EXISTS

		# store object NAMESPACE
       		$class->{namespaces}->{$object_namespace_code} = $object->getNamespace         #STORE
        		if(     (defined $object_namespace_code) &&
               			(!(exists $class->{namespaces}->{$object_namespace_code})) );  #EXISTS
	} else {
                # store LITERAL/BLOB
                $class->{literals}->{$object_literal_code} = $object->getContent                #STORE (BLOBs also :)
                        if(     (defined $object_literal_code) &&
                                (!(exists $class->{literals}->{$object_literal_code})) );       #EXISTS

		#free-text search on literals stuff
		if(	(!(ref($object->getContent))) &&
			($object->getContent ne '') &&
			(	(exists $class->{options}->{FreeText}) &&
				($class->{options}->{FreeText}==1) ) ) {
        		my $Windex;
			foreach my $word (grep !/\s+/, split /\b/m,$object->getContent) { #do not consider white spaces
				$Windex='';
				$Windex=(	(exists $class->{options}->{Compression}) &&  
						($class->{options}->{Compression}==1) ) ?
					$class->_decode( $class->{Windex}->{$word} ) :
					$class->{Windex}->{$word} #FETCH
					if(exists $class->{Windex}->{$word}); #EXISTS
				vec($Windex,$bitno+6,1)|=1;

				$class->{Windex}->{$word}=(	(exists $class->{options}->{Compression}) &&
								($class->{options}->{Compression}==1) ) ?
						$class->_encode($Windex) :
						$Windex; #STORE
			};
		};
	};

#print STDERR "add) CODES($subject_localname_code,$subject_namespace_code,$predicate_localname_code,$predicate_namespace_code,$object_localname_code,$object_namespace_code,$object_literal_code)\n";

        my $Windex;
	foreach my $idx ( 	$subject_localname_code, 	#0
				$subject_namespace_code,	#1
				$predicate_localname_code,	#2
				$predicate_namespace_code,	#3
				$object_localname_code,		#4
				$object_namespace_code,		#5
				$object_literal_code ) {	#6
		if(defined $idx) {
			$class->{statements}->{$class->_getLookupValue($bitno)} = $idx		# STORE
                		if(!(exists $class->{statements}->{$class->_getLookupValue($bitno)}));	#EXISTS

			# store WINDEX
#print STDERR "B) ($st_id/$bitno)-->unpacked='",unpack("b*",$class->_decode( $class->{Windex}->{$idx} )),"'\n";

        		$Windex='';
			$Windex=(      (exists $class->{options}->{Compression}) &&  
                                        ($class->{options}->{Compression}==1) ) ?
					$class->_decode( $class->{Windex}->{$idx} ) :
					$class->{Windex}->{$idx} #FETCH
				if(exists $class->{Windex}->{$idx}); #EXISTS
			vec($Windex,$bitno,1)|=1;

#print STDERR "B1) ($st_id/$bitno)-->unpacked='",unpack("b*",$Windex),"'\n";

			$class->{Windex}->{$idx}=(      (exists $class->{options}->{Compression}) &&  
                                        		($class->{options}->{Compression}==1) ) ?
							$class->_encode($Windex) :
							$Windex; #STORE

#print STDERR "A) ($st_id/$bitno)-->unpacked='",unpack("b*",$class->_decode( $class->{Windex}->{$idx} )),"'\n\n";
		};
		$bitno++;
	};

#print STDERR $st_id,"/",$bitno-1,"\n";
 
        if(     (exists $class->{options}->{Sync}) &&
                (defined $class->{options}->{Sync}) ) {
                #sync :(
                $class->{literals_db}->sync();
                $class->{resources_db}->sync();
                $class->{namespaces_db}->sync();
                $class->{statements_db}->sync();
                $class->{Windex_db}->sync();
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
# NOTE: it is not really safe here - we might need to lock all DBs, del statement, unlock and return (TXP) :)
sub remove {
        croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
                unless( (defined $_[1]) &&
                        (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::Statement')) );
 
        $_[0]->_tie
                unless($_[0]->_tied);
 
	# copy across stuff if necessary
	$_[0]->_copyOnWrite
		if(	(exists $_[0]->{Shared}) &&
                	(defined $_[0]->{Shared}) );

	# remove the STATEMENT
	#
	# I.e.
	#	1) find the statement
	#	2) if the statement is *unique* remove it
	#
	#	NOTE: unique means that no other statements have *exaclty* the same properties
	#

	my ($subject_localname_code,$subject_namespace_code) = map {
               	$_[0]->_getLookupValue($_); } $_[1]->subject->hashCode();
        my ($predicate_localname_code,$predicate_namespace_code) = map {
               	$_[0]->_getLookupValue($_); } $_[1]->predicate->hashCode();
        my ($object_localname_code,$object_namespace_code,$object_literal_code);
        if(     (defined $_[1]->object) &&
               	($_[1]->object->isa("RDFStore::Stanford::Resource")) ) {
               	($object_localname_code,$object_namespace_code) = map {
                       	$_[0]->_getLookupValue($_); } $_[1]->object->hashCode();
        } elsif(defined $_[1]->object) {
               	$object_literal_code = $_[0]->_getLookupValue($_[1]->object->hashCode());
        };
	my($st_id)=$_[0]->_fetchRDFNode(	$subject_localname_code,
						$subject_namespace_code,
						$predicate_localname_code,
						$predicate_namespace_code,
						$object_localname_code,
						$object_namespace_code,
						$object_literal_code);
	if(defined $st_id) {
#print STDERR "Removing ",$_[1]->toString,"($st_id)....";

		#removed one statement
		$_[0]->{statements_db}->inc('remove_counter'); #inc

		#remove  subject localname
		my $bitno=$st_id*8;
		my $id=$_[0]->_getLookupValue($bitno);
		my $oid;
        	my $Windex;
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode($oid))>1) {
					delete($_[0]->{resources}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&  
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  subject namespace
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode(undef,$oid))>1) {
					delete($_[0]->{namespaces}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  predicate localname
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode(undef,undef,$oid))>1) {
					delete($_[0]->{resources}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  predicate namespace
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode(undef,undef,undef,$oid))>1) {
					delete($_[0]->{namespaces}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  object localname
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode(undef,undef,undef,undef,$oid))>1) {
					delete($_[0]->{resources}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  object namespace
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				unless(scalar($_[0]->_fetchRDFNode(undef,undef,undef,undef,undef,$oid))>1) {
					delete($_[0]->{namespaces}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero the right bit

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE
			};
		};
		#remove  object literal
		$id=$_[0]->_getLookupValue(++$bitno);
		if($oid = $_[0]->{statements}->{$id}) { #FETCH
			delete($_[0]->{statements}->{$id}); #DELETE
			if(defined $oid) {
				my $content;
				unless(scalar($_[0]->_fetchRDFNode(undef,undef,undef,undef,undef,undef,$oid))>1) {
					$content=$_[0]->{literals}->{$oid} #additional FETCH
						if(	(exists $_[0]->{options}->{FreeText}) &&
                                			($_[0]->{options}->{FreeText}==1) );
					delete($_[0]->{literals}->{$oid}); #DELETE
				};

        			$Windex='';
				$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
					$_[0]->_decode( $_[0]->{Windex}->{$oid} ) :
					$_[0]->{Windex}->{$oid} #FETCH
					if(exists $_[0]->{Windex}->{$oid}); #EXISTS
				vec($Windex,$bitno,1)&=0; #reset to zero

				$_[0]->{Windex}->{$oid}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
						$_[0]->_encode($Windex) :
						$Windex; #STORE

				#remove free-text search stuff for literals
                		if(     (defined $content) &&
					(!(ref($content))) &&
					($content ne '') &&
					(     (exists $_[0]->{options}->{FreeText}) &&
                                                        ($_[0]->{options}->{FreeText}==1) ) ) {
                        		foreach my $word (grep !/\s+/, split /\b/m,$content) { #do not consider white spaces
						if(scalar($_[0]->_fetchRDFNode(undef,undef,undef,undef,undef,undef,undef,$word))>1) {
                                			$Windex='';
                                			$Windex=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
                                        			$_[0]->_decode( $_[0]->{Windex}->{$word} ) :
                                        			$_[0]->{Windex}->{$word} #FETCH
                                        			if(exists $_[0]->{Windex}->{$word}); #EXISTS
                                			vec($Windex,$bitno,1)&=0; #reset to zero

                                			$_[0]->{Windex}->{$word}=(      (exists $_[0]->{options}->{Compression}) &&
                                        ($_[0]->{options}->{Compression}==1) ) ?
                                                		$_[0]->_encode($Windex) :
                                                		$Windex; #STORE
						} else {
							delete($_[0]->{Windex}->{$word}); #DELETE
						};
                        		};
                		};
			};
		};

#print STDERR "DONE!\n";
	};
	
	if(     (exists $_[0]->{options}->{Sync}) &&
                (defined $_[0]->{options}->{Sync}) ) {
                #sync :(
                $_[0]->{literals_db}->sync();
                $_[0]->{resources_db}->sync();
                $_[0]->{namespaces_db}->sync();
                $_[0]->{statements_db}->sync();
                $_[0]->{Windex_db}->sync();
        };
 
        $_[0]->updateDigest($_[1]);
};

sub isMutable {
	return 1;
};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: $result = $m->find( undef, $RDF::type, new RDFStore::Resource("http://...#MyClass"), [word] );
# finds all instances in the model
sub find {
        my ($class,$subject,$predicate,$object,$object_literal_word) = @_;

        croak "Subject ".$subject." is not instance of RDFStore::Stanford::Resource"
                unless(	(not(defined $subject)) ||
                        (       (defined $subject) &&
                                (ref($subject)) &&
				($subject->isa('RDFStore::Stanford::Resource')) ) );
        croak "Predicate ".$predicate." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $predicate)) ||
                                (       (defined $predicate) &&
                                        (ref($predicate)) &&
                                        ($predicate->isa('RDFStore::Stanford::Resource')) ) );
        croak "Object ".$object." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $object)) ||
                                (       (defined $object) &&
                                        (ref($object)) &&
                                        ($object->isa('RDFStore::Stanford::RDFNode')) ) );

	return
		if(	(defined $object) &&
			(defined $object_literal_word) &&
			(     (exists $class->{options}->{FreeText}) &&
                              ($class->{options}->{FreeText}==1) ) );

	# e.g. $class->find($subject,$predicate,$object)->find(....) and so on
	# NOTE: this could be much improved avoid DB operations using shared_ids of properties.....
	if(	(exists $class->{Shared}) &&
		(defined $class->{Shared}) ) {
		$class->{Shared}->{sharing_query_model_statement_ids}=$class->{query_model_statement_ids}
			if(	(exists $class->{query_model_statement_ids}) &&
				($#{$class->{query_model_statement_ids}}>=0) );
		return $class->{Shared}->find($subject,$predicate,$object,$object_literal_word);
	};

	$class->_tie
                unless($class->_tied);

        # we have the same problem like in Pen - a result set must be a model/collection :-)
        my $res = $class->create(); #EMPTY MODEL

	# we keep numbers of shared statements for queries :)
	# NOTE: it is much better to keep in-memory just IDs of queries instead of add() full-blown statements
	# it might be that a query model module or cache one would be preferred here in the future.....
        $res->{query_model_statement_ids}=[];

        return $res
		if($class->isEmpty());

	if(     (exists $class->{options}->{FreeText}) &&
                              ($class->{options}->{FreeText}==1) ) {
        	return $class->duplicate()
                	if(     (not(defined $subject)) &&
                        	(not(defined $predicate)) &&
                        	(not(defined $object)) &&
                        	(not(defined $object_literal_word)) );
	} else {
        	return $class->duplicate()
                	if(     (not(defined $subject)) &&
                        	(not(defined $predicate)) &&
                        	(not(defined $object)) );
	};

	#share IDs till first write operation such as add() or remove() on query result model
	# NOTE: sharing avoid add() full-blown statements to the result model
	$res->{Shared}=$class;

	my ($subject_localname_code,$subject_namespace_code) = map {
                        $class->_getLookupValue($_); } $subject->hashCode()
		if(defined $subject);
        my ($predicate_localname_code,$predicate_namespace_code) = map {
                        $class->_getLookupValue($_); } $predicate->hashCode()
		if(defined $predicate);
        my ($object_localname_code,$object_namespace_code,$object_literal_code);
        if(     (defined $object) &&
        	($object->isa("RDFStore::Stanford::Resource")) ) {
                ($object_localname_code,$object_namespace_code) = map {
                                $class->_getLookupValue($_); } $object->hashCode();
        } elsif(defined $object) {
        	$object_literal_code = $class->_getLookupValue($object->hashCode());
        };

        # fetch results keeping track of IDs
	my(@ids);
        map {
                push @ids,$_;
        } $class->_fetchRDFNode(	$subject_localname_code,
					$subject_namespace_code,
					$predicate_localname_code,
					$predicate_namespace_code,
					$object_localname_code,
					$object_namespace_code,
					$object_literal_code,
					$object_literal_word);

	if(exists $class->{sharing_query_model_statement_ids}) {
		map {
			my $a=$_;
			push @{$res->{query_model_statement_ids}}, $a
				if(grep /^$a$/,@ids);
			} @{$class->{sharing_query_model_statement_ids}};
		delete($class->{sharing_query_model_statement_ids});
	} else {
		push @{$res->{query_model_statement_ids}},@ids;
	};

        return $res;
};

# clone the model - So due that copy is expensive we use sharing :)
sub duplicate {
	my ($class) = @_;

        my $new = $class->create();

        # return a model that shares store and lookup with this model
        # delegate read operations till first write operation such as add() or remove()
	# NOTE: sharing avoid to copy right the way the whole original model that could be very large :)
        $new->{Shared} = $class;

        return $new;
};

# Creates in-memory empty model with the same options but Sync
sub create {
        my($class) = shift;

        my $self = ref($class);
        my $new = $self->new();

	$new->{options}->{Compression}=$class->{options}->{Compression}
		if(exists $class->{options}->{Compression});
	$new->{options}->{Freetext}=$class->{options}->{FreeText}
		if(exists $class->{options}->{FreeText});

        return $new;
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
                return "uuid:rdf:".
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
                for  $t ( sort digest_sorter @{$_[0]->elements} ){ #this still fetches all statements in-memory :(
                        $digest_bytes .= $ { $t->getDigest()->getDigestBytes() };
                };
                $_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest($_[0]->getDigestAlgorithm, $digest_bytes);
        };
        return $_[0]->{digest}->getDigestBytes();
};

#serialise model to strawman syntax - see XML::Parser::OpenHealth(3)
# it could return a kind of tied filehandle/stream :)
sub toStrawmanRDF {

	$_[0]->_tie
                unless($_[0]->_tied);

	# here we should use RDFStore::Stanford::Vocabulary::RDF definitions....
	my $rdf= '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE rdf:RDF [ <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#"> ]><rdf:RDF xmlns:rdf="&rdf;">';
	$rdf .= "\n";

	# when here we do not have an index set :(
	my($elements)=$_[0]->elements;
	for my $ii ( 0..$#{$elements} ) {
		my $st=$elements->[$ii]; #FETCH one by one

		$rdf .= '<rdf:Statement rdf:ID="'.$st->getURI().'">'."\n";

		$rdf .= "\t".'<rdf:subject rdf:resource="'.$st->subject()->toString.'" />'."\n";
		$rdf .= "\t".'<rdf:predicate rdf:resource="'.$st->predicate()->toString.'" />'."\n";
		my $object = $st->object();
		# binary data is a still a problem. We might use MIME::Base64 or URI::data
		if( (defined $object) && (ref($object)) && ($object->isa("RDFStore::Stanford::Literal")) ) {
			my $s = $st->object()->toString;
			$rdf .= "\t".'<rdf:object'.
					( ($s =~ /[\&\<\>]/) ? ' xml:space="preserve"><![CDATA['.$s.']]>' : '>'.$s ).'</rdf:object>'."\n";
		} else {
			$rdf .= "\t".'<rdf:object rdf:resource="'.$st->object()->toString.'" />'."\n";
		};

		$rdf .= '</rdf:Statement>'."\n";
       	};
	$rdf .= '</rdf:RDF>';

	return $rdf;
};


# Storage related part

# copy shared statements across
sub _copyOnWrite {
	my($class) = @_;
 
	return
        	unless( (exists $class->{Shared}) &&
                	(defined $class->{Shared}) );
 
	my($shares)=$class->{Shared}->elements(	(	(exists $class->{query_model_statement_ids}) &&
							($#{$class->{query_model_statement_ids}}>=0) ) ? 
								@{$class->{query_model_statement_ids}} : () );

	#forget about being a query model if necessary :)
	delete($class->{query_model_statement_ids})
		if(exists $class->{query_model_statement_ids});

	#break the sharing
        delete($class->{Shared});

        #XXXX it could be really expensive in-memory consumage and CPU time!!!
	for my $ii (0..$#{$shares}) {
		$class->add($shares->[$ii]);
	};
};
                                

# The following two functions come from an algorithm developed by Dirk Willem van Guilk and Nick Hibma called Windex
#
# NOTE: I am aware of that the following should be written in C :)
#
# Simple RLE encoder/decoder
# token byte
#      bit     value   meaning
#      0..4    ...     lenght of run (len)
#      5-6     00      len is between 0 .. 31, no other bytes
#              10      len is continued in next byte, next is LSB (short int)
#              01      len is continued in next 3 bytes (long int)
#                         * first is upper nibble of MSB
#                         * next is lower nibble of MSB
#                         * next+1 is upper nibble of LSB
#                         * next+2 is lower nibble of LSB
#              11      len is continued in next 7 bytes (64 bit int, not implemented yet...)
#      7       set     run of len bytes set to 0
#              unset   No run, next len bytes are to be copied
#                      as-is.
#

# read a string and returns a RLE encoded version of it
sub _encode {
        my ($class,$buff) = @_;
 
	return
		unless(	(defined $buff) &&
			($buff ne '') );
 
        my ($out, $comp, $len, $l);
        $out='';
        $comp=0;
        my $insize=length($buff);
        my $i=0;
        my $j=0;
        for($i=0,$j=0; $i<$insize; ) {
		#found that using regex below is much faster. But if C code the for is probably better...
                if(     (vec($buff,$i,8)==0) &&
                        ($i+1<$insize) &&
                        (0==vec($buff,$i+1,8)) ) {
                        for(    $len=2;
                                        ($len+$i<$insize) &&
                                        (0==vec($buff,$i+$len,8)) &&
                                        ($len < 536870912); #up to 32*256*256*256
                                $len++) {};
                        $comp=1;
                } else {
                        for(    $len=1;
                                        ($len+$i<$insize) &&
                                        (       (vec($buff,$i+$len,8)) ||
                                                (vec($buff,$i+$len-1,8)) ) &&
                                        ($len < 536870912);
                                $len++) {};
                        $len--
                                if(     ($len+$i<$insize) &&
                                        ($len < 536870912) );
                        $comp=0;
                };
                $l=$j;
                if($len>8191) {
                        vec($out,$l,8) = 64 + (($len>>24) & 31);
                        vec($out,$l+1,8) = ($len>>16) & 0xffff;
                        vec($out,$l+2,8) = ($len>>8) & 0xffff;
                        vec($out,$l+3,8) = $len & 0xffff;
                        $j+=3;
                } elsif($len>31) {
                        vec($out,$l,8) = 32 + (($len>>8) & 31);
                        vec($out,$l+1,8) = $len & 0xff;
                        $j++;
                } else {
                        vec($out,$l,8) = $len & 31;
                };
                $j++;
		if($comp) {
                        vec($out,$l,8) |= 128;
                } else {
                        if($len==1) {
                                vec($out,$j,8) = vec($buff,$i,8);
                        } else {
                                for(my $ii=0;$ii<$len; $ii++) {
                                        vec($out,$j+$ii,8) = vec($buff,$i+$ii,8);
                                };
                        };
                        $j+=$len;
                }; # non-compressed else
                $i+=$len; # hop on for the next ones...
        };
        #return $out up to $j
 
        return $out;
};

# read a RLE encoded string and returns a decompressed version of it
sub _decode {
        my ($class,$buff) = @_;

	return
		unless(	(defined $buff) &&
			($buff ne '') );

        my ($out, $c, $len);
        $out='';
 
        my $insize=length($buff);
        my $i=0;
        my $j=0;
        for($i=0,$j=0; $i<$insize; ) {
                # work out run length
                $c = vec($buff,$i,8);
                last
                        unless($c); #no compress, no length

                if( $c & 64 ) {
                	$len = $c & 63;
			for (1..3) {
                		$len=($len<<8) + vec($buff,++$i,8);
			};
		} else {
                	$len = $c & 31;
                	$len=($len<<8) + vec($buff,++$i,8)
                		if( $c & 32 );
		};

                if($len==0) {
                        warn "RDFStore::Model::_decode: Bug RLE len=0\n";
                        last;
		};
                $i++;
                if($c & 128) {
                        vec($out,$j,8) = (0) x $len;
                } else {
                        for(my $ii=0;$ii<$len; $ii++) {
                                vec($out,$j+$ii,8) = vec($buff,$i+$ii,8);
                        };
                        $i+=$len;
                };
                $j+=$len;
        };
        #return $out up to $j
 
        return $out;
};

sub _getLookupValue {
        my ($class) = shift;

        return
                unless(defined $_[0]);

        return pack("i*",$_[0]);
};

sub _getValueFromLookup {
        my ($class) = shift;

        return
                unless(defined $_[0]);

        return unpack("i*",$_[0]);
};

# return a list of statement IDs for a given criteria. The statement could be *unique*
sub _fetchRDFNode {
        my($class,	$subject_localname,
			$subject_namespace,
			$predicate_localname,
			$predicate_namespace,
			$object_localname,
			$object_namespace,
			$object_literal,
			$object_literal_word) = @_;

	return
		if(	(     (exists $class->{options}->{FreeText}) &&
                              ($class->{options}->{FreeText}==1) ) &&
			(defined $object_literal) &&
			(defined $object_literal_word) );

	$object_literal=$object_literal_word
		if(defined $object_literal_word);

#print STDERR "_fetchRDFNode - ",((caller)[2]),"\n";

        my $Windex='';
	my $bitno=0;
	my $mask='';
	foreach my $idx ( 	$subject_localname, 	#0
				$subject_namespace,	#1
				$predicate_localname,	#2
				$predicate_namespace,	#3
				$object_localname,	#4
				$object_namespace,	#5
				$object_literal ) {	#6
		if(defined $idx) {
			$Windex|=(	(exists $class->{options}->{Compression}) &&
					($class->{options}->{Compression}==1) ) ?
					$class->_decode( $class->{Windex}->{$idx} ) :
					$class->{Windex}->{$idx} #FETCH
				if(exists $class->{Windex}->{$idx}); #EXISTS
			vec($mask,$bitno,1)|=1;

#print STDERR "A- $bitno(".(
#		( $subject 	? $subject->toString 	: '').",".
#		( $predicate 	? $predicate->toString 	: '').",".
#		( $object 	? $object->toString 	: '') ).")--".length($Windex)."-->'",unpack("b*",$Windex),"'-mask='",unpack("b*",$mask),"'(".length($mask).")\n\n";
		};
		$bitno++;
	};

	my $pos=-1;
	my @ids;
	while( ($pos=index($Windex,$mask,$pos)) > -1 ) {
		push @ids,$pos;
#print STDERR "_fetchRDFNode() ",(
#		( $subject      ? $subject->toString    : '').",".
#		( $predicate    ? $predicate->toString  : '').",".
#		( $object       ? $object->toString     : '') )," - found at '$pos'\n";
		$pos++;
	};

        return @ids;
};

sub DESTROY {
        $_[0]->_untie
                if($_[0]->_tied);
};

package RDFStore::Model::Statements;

use vars qw ( $VERSION );
use strict;

$VERSION = '0.1';

BEGIN {
        $Data::MagicTie::Array::perl_version_ok=
		($] ge '5.6.0') ? 1 : 0;
};

sub new {
        return $_[0]->TIEARRAY(@_);
};

sub TIEARRAY {
        my ($pkg,$model,@ids) = @_;

	return
                unless(defined $model);

        return 	bless {
			model => 	$model,
			ids => \@ids,
			remove_holes	=>	0
	},$pkg;
};

sub FETCH {
	my($class,$key) = @_;

	if($#{$class->{ids}}>=0) {
		$key=$class->{ids}->[$key];
		$key*=8;
	} else {
		$key+=$class->{remove_holes};
		$key*=8;

		while(!(exists $class->{model}->{statements}->{
			$class->{model}->_getLookupValue($key)})) {	#EXISTS
			$class->{remove_holes}++;
			$key+=8;
		};
	};

#print STDERR caller,"FETCH($key)\n";

	# here are all the DB operations needed to fetch a statement
	# NOTE: if we return directly properties in a tied hash should be faster....
	#
	# 4+(1|2) EXISTS & FETCH
	my @nodeids;
	for my $ff (0,1,2,3,6,4,5) { #see model add() method
		next
			if(	(($ff==4) || ($ff==5)) &&
				(defined $nodeids[6]) ); #save 2 EXISTS/FETCH :)
			
		if(	($ff==0) || #skip the EXISTS above :)
			(exists $class->{model}->{statements}->{
				$class->{model}->_getLookupValue($key+$ff)}) ) {	#EXISTS
			$nodeids[$ff]= $class->{model}->{statements}->{
					$class->{model}->_getLookupValue($key+$ff)}; #FETCH
			$nodeids[$ff]= $class->{model}->{resources}->{$nodeids[$ff]} #FETCH	
				if(	(	($ff==0) || 
						($ff==2) || 
						($ff==4) ) &&
					(exists $class->{model}->{resources}->{$nodeids[$ff]}) ); #EXISTS
			$nodeids[$ff]= $class->{model}->{namespaces}->{$nodeids[$ff]} #FETCH	
				if(	(	($ff==1) || 
						($ff==3) || 
						($ff==5) ) &&
					(exists $class->{model}->{namespaces}->{$nodeids[$ff]}) ); #EXISTS
			$nodeids[$ff]= $class->{model}->{literals}->{$nodeids[$ff]} #FETCH	
				if(	($ff==6) &&
					(exists $class->{model}->{literals}->{$nodeids[$ff]}) ); #EXISTS
		};
	};

	return
		unless($#nodeids>=2); #minimal statement is (genid1,genid2,"object")

	my $factory=$class->{model}->getNodeFactory;
	my $subject=$factory->createResource(
			$nodeids[1] ? 
				($nodeids[1],$nodeids[0]) : 
				($nodeids[0]) );
	my $predicate=$factory->createResource(
			$nodeids[3] ? 
				($nodeids[3],$nodeids[2]) : 
				($nodeids[2]) );

        my $object;
        if(defined $nodeids[6]) {
        	$object = $factory->createLiteral($nodeids[6]);
        } else {
		$object=$factory->createResource(
				$nodeids[5] ? 
					($nodeids[5],$nodeids[4]) : 
					($nodeids[4]) );
        };

	return $factory->createStatement($subject,$predicate,$object);
};

sub FETCHSIZE {

#print STDERR (caller), "-FETCHSIZE: ",(($#{$_[0]->{ids}}>=0) ? $#{$_[0]->{ids}} : $_[0]->{model}->size-1),"\n";

	return ($#{$_[0]->{ids}}>=0) ? $#{$_[0]->{ids}}+1 : $_[0]->{model}->size;
};

sub STORESIZE {
};

sub STORE {
};

sub DESTROY {
};

1;
};

__END__

=head1 NAME

RDFStore::Model - An implementation of the Model RDF API using tied hashes and implementing free-text search on literals

=head1 SYNOPSIS

	use RDFStore::NodeFactory;
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

	use RDFStore::Model;
	my $model = new RDFStore::Model( Name => 'store', Split => 20, Compression => 1, FreeText => 1 );

	$model->add($statement);
	$model->add($statement1);
	$model->add($statement2);
	my $model1 = $model->duplicate();

	print $model1->getDigest->equals( $model1->getDigest );
	print $model1->getDigest->hashCode;

	my $found = $model->find($statement2->subject,undef,undef);
	my $found1 = $model->find(undef,undef,undef,undef,'Cool'); #free-text search on literals :)

	#get Statements
	foreach ( @{$found->elements} ) {
        	print $_->getLabel(),"\n";
	};

	#or faster
	my $fetch;
	foreach ( @{$found->elements} ) {
		my $fetch=$_;  #avoid too many fetches from RDFStore::Model::Statements
        	print $fetch->getLabel(),"\n";
	};

	#or
	my($statements)=$found1->elements;
	for ( 0..$#{$statements} ) {
                print $statements->[$_]->getLabel(),"\n";
        };

	#get RDFNodes
	foreach ( keys %{$found->elements}) {
        	print $found->elements->{$_}->getLabel(),"\n";
	};

=head1 DESCRIPTION

An RDFStore::Stanford::Model implementation using Data::MagicTie tied arrays and hashes to store triplets. The actual store could be tied either to an in-memory, a local or remote database - see Data::MagicTie(3).

This modules implements a storage and iterator by leveraging on perltie(3) and the Data::MagicTie(3) interface. A compact indexing model is used that allows to make free-text indexing up to literals.

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

=item Compression

Switch on Run Length Encoding (RLE) on the internal index; this option allows to save a lot of space (or memory) if you are going to manage large models. For tiny models is
faster to use I<no> compression.

=item FreeText

Enable free text searching on literals over a model (see B<find>)

=head1 SEE ALSO

Data::MagicTie(3) Digest(3) RDFStore::Stanford::Digest::Digestable(3) RDFStore::Stanford::Digest(3) RDFStore::RDFNode RDFStore::Resource RDFStore::FindIndex(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
