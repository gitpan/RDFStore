# *
# *	Copyright (c) 2000 Alberto Reggiori / <alberto.reggiori@jrc.it>
# *	ISIS/RIT, Joint Research Center Ispra (I)
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://xml.jrc.it/RDFStore/LICENSE
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
# *

package RDFStore::Model;
{
use Carp;
use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Model;
use RDFStore::Resource;
use RDFStore::Literal;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Stanford::Digest::Util;
use RDFStore::FindIndex;

@RDFStore::Model::ISA = qw( RDFStore::Resource RDFStore::Stanford::Model RDFStore::Stanford::Digest );

sub new {
	my ($pkg,$factory_or_uri,$triples,$findIndex,$shared) = @_;

    	my $self = $pkg->SUPER::new();

    	#whether triples and lookup are shared
    	$self->{shared}=(defined $shared) ? $shared : 0;
    	$self->{uri}=$factory_or_uri
		if(	(defined $factory_or_uri) && (ref($factory_or_uri)) &&
                        (!($factory_or_uri->isa("RDFStore::Stanford::NodeFactory"))) );
    	# first find operation creates lookup table
    	$self->{nodeFactory}=(	(defined $factory_or_uri) && (ref($factory_or_uri)) &&
				($factory_or_uri->isa("RDFStore::Stanford::NodeFactory"))) ? 
				$factory_or_uri : new RDFStore::NodeFactory();

	# creates lookup table
	if( (!(defined $triples)) && (!(defined $findIndex)) ) {
		$self->{triples}={};
		$self->{_findIndex} = new RDFStore::FindIndex();
	} else {
		$self->{triples}=(	(defined $triples) &&
					(ref($triples) =~ /HASH/) ) ?
					$triples :
					{};
		$self->{_findIndex} = ( 	(defined $findIndex) && (ref($findIndex)) &&
						($findIndex->isa("RDFStore::FindIndex")) ) ?
							$findIndex : 
							new RDFStore::FindIndex();
	};

    	bless $self,$pkg;
};

sub getNamespace {
        return undef;
};

sub getLocalName {
        return $_[0]->getURI();
};

sub toString {
        return "Model[" + $_[0]->getSourceURI() + " of size " + $_[0]->size() + "]";
};

# Set a base URI for the message.
# Affects creating of new resources and serialization syntax.
# <code>null</code> is just alright, meaning that
# the serializer will use always rdf:about and never rdf:ID
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
# return  number of triples
sub size {
	# really not efficient :-(
	# we should use BerkeleyDB or DB_File tricks hereish...
	return scalar keys %{$_[0]->{triples}};
};

#watch out in in DBMS(3) implementations!!!!!!!!
sub isEmpty {
	# not efficient also - see size()
	return ($_[0]->size() > 0) ? 0 : 1;
};

sub elements {
	return $_[0]->{triples};
};

# Tests if the model contains the given triple.
# return  true if the triple belongs to the model;
# false otherwise.
# !!!watch out in sub implementations with DBMS(3)!!!!!!!!
sub contains {
	if( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa("RDFStore::Stanford::Statement")) ) {
		#index by label then ;-)
		return (exists $_[0]->{triples}->{$_[1]->hashCode()}) ? 1 : 0;
	} else {
		return (exists $_[0]->{triples}->{$_[1]}) ? 1 : 0;
	};
};

# Model manipulation: add, remove, find
#
# Adds a new triple to the model
sub add {
	croak "Subject or Statement ".$_[1]." is not either instance of RDFStore::Stanford::Statement or RDFStore::Stanford::Resource"
                unless( (defined $_[1]) && (ref($_[1])) && (($_[1]->isa('RDFStore::Stanford::Resource')) || ($_[1]->isa('RDFStore::Stanford::Statement'))) );
	croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[2])) || ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ) );

	$_[0]->makePrivate();

	my $t;
	if( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa("RDFStore::Stanford::Statement")) ) {
		$t = $_[1];
	} elsif( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa("RDFStore::Stanford::Resource")) ) {
		if( (defined $_[3]) && (ref($_[3])) && ($_[3]->isa("RDFStore::Stanford::Resource")) ) {
			$t = $_[0]->{nodeFactory}->createStatement($_[1],$_[2],$_[3]);
		} else { #otherwise create a literal
			$t = $_[0]->{nodeFactory}->createStatement($_[1],$_[2],
						$_[0]->{nodeFactory}->createLiteral($_[3]));
		};
	};

	my $code = $t->hashCode();

	#do not update existing statements
	return
		if( (exists $_[0]->{triples}->{$code}) && (defined $_[0]->{triples}->{$code}) );

	$_[0]->{triples}->{$code} = $t; #STORE

	$_[0]->{_findIndex}->addLookup($t)
		if(defined $_[0]->{_findIndex});

	$_[0]->updateDigest($t);
};

sub updateDigest {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
                unless( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')));

      	return
		unless(defined $_[0]->{digest});

	# see http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31
	#my $digest = $_[1]->getDigest();

      	#RDFStore::Stanford::Digest::Util::xor($_[0]->{digest}->getDigestBytes(),$digest->getDigestBytes());

	delete $_[0]->{digest};
};

sub validLookup {
	return 0;
};

sub makePrivate {
	# if we have a clone, tell clone to detach
	if(	(defined $_[0]->{myClone}) && 
		( (defined $_[0]->{myClone}->{shared}) && ($_[0]->{myClone}->{shared}) ) ) {
		$_[0]->{myClone}->makePrivate();
		$_[0]->{myClone} = undef;
	};
	if( (defined $_[0]->{shared}) && ($_[0]->{shared}) ) {
		# for find() query stuff we can easily assume that everything is done
		# in-memory and then we can use Perl constructs. Otherwise we could somehow
		# pass here an external tied hash for copied data.
		if( (exists $_[0]->{shared_triples}) && (defined $_[0]->{shared_triples}) ) {
			%{$_[0]->{shared_triples}}=%{$_[0]->{triples}}; #copy
			$_[0]->{triples} = $_[0]->{shared_triples};
		} else {
			# in-memory case - it is the most common for find() queries
			my %detached_triples = %{$_[0]->{triples}}; #copy
			$_[0]->{triples} = \%detached_triples;
		};
		if( (exists $_[0]->{shared_findIndex}) && (defined $_[0]->{shared_findIndex}) ) {
			$_[0]->{_findIndex} = $_[0]->{shared_findIndex};
		} else {
			$_[0]->{_findIndex} = new RDFStore::FindIndex();
		};
		$_[0]->{shared}=0;
	};
};

# Removes the triple from the model
sub remove {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
                unless( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')));

	$_[0]->makePrivate();

	delete $_[0]->{triples}->{$_[1]->hashCode()}; #DELETE

	$_[0]->{_findIndex}->removeLookup($_[1])
		if(defined $_[0]->{_findIndex});

	$_[0]->updateDigest($_[1]);
};

sub isMutable {
	return 1;
};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: Model result = m.find( null, RDF.type, new Resource("http://...#MyClass") )
# finds all instances of the class MyClass
sub find {
	croak "Subject ".$_[1]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[1])) || ( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ) );
	croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[2])) || ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ) );
	croak "Object ".$_[3]." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $_[3])) || ( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ) );

	#for shared stuff
	my ($result_triples,$result_findIndex);
	if( (defined $_[4]) && (ref($_[4]) =~ /HASH/) ) {
		$result_triples=$_[4]; #we put the query results in a special HASH :)
	};
	if( (defined $_[5]) && (ref($_[5])) && ($_[5]->isa("RDFStore::FindIndex")) ) {
		$result_findIndex=$_[5];
	};

	# we have the same problem like in Pen - a result set must be a model/collection :-)
	my $res = $_[0]->create(undef,$result_triples,$result_findIndex,undef); #EMPTY MODEL

	# we avoid this due to efficency problems with DBMS(3) remote DBs
	# this is check might be safely skipped anyway
        #return $res
	#	if($_[0]->isEmpty());

	return $_[0]->duplicate($result_triples,$result_findIndex)
		if( (not(defined $_[1])) && (not(defined $_[2])) && (not(defined $_[3])) );

	my $en;
	my $t;
	my $key;
	if(defined $_[0]->{_findIndex}) {
		# when index we have a different result set to look at
		$en = $_[0]->{_findIndex}->multiget($_[1],$_[2],$_[3]);

		# NOTE: the first element of $en is "spurious" id for 'undef,undef,undef' that is
		# already checked at the beginning of this method
		foreach $t (@{$en}) {
			unless( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) ) {
				# it was an indirect index
				$t = $_[0]->{triples}->{ $t }; #FETCH from triples
			};
	
			my $matchStatement=1;
			if(	( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) ) &&
				( ( (defined $_[1]) && (ref($_[1])) && (!($t->subject()->equals($_[1]))) ) ||
				  ( (defined $_[2]) && (ref($_[2])) && (!($t->predicate()->equals($_[2]))) ) ||
				  ( (defined $_[3]) && (ref($_[3])) && (!($t->object()->equals($_[3]))) ) ) ) {
				$matchStatement=0;
			};

                	$res->add($t)
				if( 	( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) ) && ($matchStatement) );
                };
	} else {
		# when here we do not have an index set :(
		$en=$_[0]->{triples};
		while(($key,$t) = each %{$en}) {
			my $matchStatement=1;
			if(	( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) ) &&
				( ( (defined $_[1]) && (!($t->subject()->equals($_[1]))) ) ||
				  ( (defined $_[2]) && (!($t->predicate()->equals($_[2]))) ) ||
				  ( (defined $_[3]) && (!($t->object()->equals($_[3]))) ) ) ) {
				$matchStatement=0;
			};

                	$res->add($t)
				if( 	( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) ) &&
					($matchStatement) );
                };
        };
        return $res;
};

# Clone the model
sub duplicate {
	#for shared stuff
	if( (defined $_[1]) && (ref($_[1]) =~ /HASH/) ) {
		$_[0]->{shared_triples}=$_[1];
	};
	if( (defined $_[2]) && (ref($_[2])) && ($_[2]->isa("RDFStore::FindIndex")) ) {
		$_[0]->{shared_findIndex} = $_[2];
	};

	if( (!(defined $_[0]->{myClone})) || (!($_[0]->{myClone}->{shared})) ) {
		my $self=ref($_[0]);
		# creates a model that shares triples and lookup with this model
		return $_[0]->{myClone} = $self->new(	$_[0]->{uri},
							(defined $_[0]->{shared_triples}) ?
								$_[0]->{shared_triples} : 
								$_[0]->{triples},
							(defined $_[0]->{shared_findIndex}) ?
								$_[0]->{shared_findIndex} :
								((defined $_[0]->{_findIndex}) ? 
									$_[0]->{_findIndex} : 
									undef), 1 ); #shared
	} else {
		$_[0]->{myClone}->duplicate();
	};
};

sub clone {
	return $_[0]->duplicate(@_);
};

# Creates empty model of the same Class
sub create {
	my $self = ref(shift);
	return $self->new(@_);
};

sub getNodeFactory {
	return $_[0]->{nodeFactory};	
};

sub getDigest {
	# we do NOT carry out the whole model digest here - JAVA uses Digestable inteface :(
	if(not(defined $_[0]->{digest})) {
		my $digest_bytes;
		# this does not work under MagicTie yet :(
		my $key;
		my $t;
		while(($key,$t) = each %{$_[0]->{triples}}) {
      			my $d = $t->getDigest();
      			if(not(defined $digest_bytes)) {
        			$digest_bytes = $d->getDigestBytes();
      			} else {
				RDFStore::Stanford::Digest::Util::xor($digest_bytes,$d->getDigestBytes());
    			};
		};
		$_[0]->{digest} = RDFStore::Stanford::Digest::Util::createFromBytes($_[0]->{algorithm},$digest_bytes);
	};
	return $_[0]->{digest};
};

sub getURI {
	if($_[0]->isEmpty()) {
      		return $_[0]->{nodeFactory}->createUniqueResource()->toString();
    	} else {
		return "uuid:rdf:".
				$_[0]->getDigestAlgorithm ."-".
				RDFStore::Stanford::Digest::Util::toHexString($_[0]->getDigest());
      	};
};

sub getDigestAlgorithm {
	return $_[0]->{algorithm};
};

sub getDigestBytes {
	#do something hereish......	
	if(not(defined $_[0]->{digest})) {
		$_[0]->{digest} = $_[0]->getDigest();
	}; 
	#$_[0]->{digest_bytes} = $_[0]->{digest}->getDigestBytes();
        #return \$_[0]->{digest_bytes};
	return $_[0]->{digest}->getDigestBytes();
};

#serialise model to strawman syntax - see XML::Parser::OpenHealth(3)
sub toStrawmanRDF {
	# here we should use RDFStore::Stanford::Vocabulary::RDF definitions....
	my $rdf= '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE rdf:RDF [ <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#"> ]><rdf:RDF xmlns:rdf="&rdf;">';
	$rdf .= "\n";
	my($k,$t,$en);
	# when here we do not have an index set :(
	while(($k,$t) = each %{ $_[0]->{triples} }) {
		next
			unless( (defined $t) && (ref($t)) && ($t->isa("RDFStore::Stanford::Statement")) );
		$rdf .= '<rdf:Statement ID="'.$t->getURI().'">'."\n";

		$rdf .= "\t".'<rdf:subject rdf:resource="'.$t->subject()->toString.'" />'."\n";
		$rdf .= "\t".'<rdf:predicate rdf:resource="'.$t->predicate()->toString.'" />'."\n";
		my $object = $t->object();
		# binary data is a still a problem. We might use MIME::Base64 or URI::data
		if( (defined $object) && (ref($object)) && ($object->isa("RDFStore::Stanford::Literal")) ) {
			my $s = $t->object()->toString;
			$rdf .= "\t".'<rdf:object'.
					( ($s =~ /[\&\<\>]/) ? ' xml:space="preserve"><![CDATA['.$s.']]>' : '>'.$s ).'</rdf:object>'."\n";
		} else {
			$rdf .= "\t".'<rdf:object rdf:resource="'.$t->object()->toString.'" />'."\n";
		};

		$rdf .= '</rdf:Statement>'."\n";
       	};
	$rdf .= '</rdf:RDF>';

	return $rdf;
};

1;
};

__END__

=head1 NAME

RDFStore::Model - An implementation of the Model RDF API

=head1 SYNOPSIS

	use RDFStore::Model;
	use RDFStore::NodeFactory;
	use RDFStore::FindIndex;
	use Data::MagicTie;

	my $factory= new RDFStore::NodeFactory();
	my $statement = $factory->createStatement(
                        	$factory->createResource('http://perl.org'),
                        	$factory->createResource('http://iscool.org/schema/1.0/#label'),
                        	$factory->createLiteral('Cool Web site')
                                );
	my $statement1 = $factory->createStatement(
				$factory->createResource("http://www.altavista.com"),
				$factory->createResource("http://pen.jrc.it/schema/1.0/#author"),
				$factory->createLiteral("Who? :-)")
				);

	my $statement2 = $factory->createStatement(
				$factory->createUniqueResource(),
				$factory->createUniqueResource(),
				$factory->createLiteral("")
				);

	my $index_db={};
	tie %{$index_db},"Data::MagicTie",'index/triples',(Q => 20);
	my $index=new RDFStore::FindIndex($index_db);
	my $model = new RDFStore::Model($factory,undef,$index,undef);

	$model->add($statement);
	$model->add($statement1);
	$model->add($statement2);
	my $model1 = $model->duplicate();

	print $model1->getDigest->equals( $model1->getDigest );
	print $model1->getDigest->hashCode;

	my $found = $model->find($statement2->subject,undef,undef);
	foreach (keys %{$found->elements}) {
        	print $found->elements->{$_}->getLabel(),"\n";
	};

=head1 DESCRIPTION

An RDFStore::Stanford::Model implementation using Digested URIs and Perl hashes to store triplets. The actual store could be tied to a Data::MagicTie(3) hash/array and the RDFStore::FindIndex(3) module.

=head1 SEE ALSO

Data::MagicTie(3) Digest(3) RDFStore::Stanford::Digest(3) RDFStore::RDFNode RDFStore::Resource RDFStore::FindIndex(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>
