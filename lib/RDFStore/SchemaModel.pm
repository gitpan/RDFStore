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
# *		- general fixing and improvements
# *			* instances and closure are SetModel
# *     version 0.3
# *		- added getLocalName() and getNamespace() to delegate to instances
# *		- changed checking to RDFStore::Stanford::SetModel type
# *		- modified toString()
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *		- fixed miss-spell in validate()
# *

package RDFStore::SchemaModel;
{
use Carp;
use RDFStore::VirtualModel;
use RDFStore::Resource;
use RDFStore::Literal;
use RDFStore::Statement;
use RDFStore::NodeFactory;
use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Digest::Util;
use RDFStore::FindIndex;

use RDFStore::Vocabulary::RDF;
use RDFStore::Vocabulary::RDFS;

@RDFStore::SchemaModel::ISA = qw( RDFStore::VirtualModel );

# Creates a schema model, closure must contain transitive closures of subClassOf and subPropertyOf
sub new {
	my ($pkg,$factory_or_instances,$instances_or_closure,$closure) = @_;

    	my $self = $pkg->SUPER::new();

	#to emulate typed parameters
	if ( (defined $factory_or_instances) && (ref($factory_or_instances)) && ($factory_or_instances->isa("RDFStore::Stanford::SetModel")) ) {
		$self->{nodeFactory}=new RDFStore::NodeFactory();
		$self->{instances}=$factory_or_instances;
		if((defined $instances_or_closure) && (ref($instances_or_closure)) && ($instances_or_closure->isa("RDFStore::Stanford::SetModel"))) {
			$self->{closure}=$instances_or_closure;
		};
	} elsif(  (defined $factory_or_instances) && (ref($factory_or_instances)) &&
                                ($factory_or_instances->isa("RDFStore::Stanford::NodeFactory"))) {
		$self->{nodeFactory}=$factory_or_instances;
		if ( (defined $instances_or_closure) && (ref($instances_or_closure)) && ($instances_or_closure->isa("RDFStore::Stanford::SetModel")) ) {
			$self->{instances}=$instances_or_closure;
		};
		if((defined $closure) && (ref($closure)) && ($closure->isa("RDFStore::Stanford::SetModel"))) {
			$self->{closure}=$closure;
		};
	} else {
		$self->{nodeFactory}=new RDFStore::NodeFactory();
		if ( (defined $instances_or_closure) && (ref($instances_or_closure)) && ($instances_or_closure->isa("RDFStore::Stanford::SetModel")) ) {
			$self->{instances}=$instances_or_closure;
		};
		if((defined $closure) && (ref($closure)) && ($closure->isa("RDFStore::Stanford::SetModel"))) {
			$self->{closure}=$closure;
		};
	};
    	bless $self,$pkg;
};

sub getNamespace {
        return $_[0]->{instances}->getNamespace();
};

sub getLocalName {
        return $_[0]->{instances}->getLocalName();
};

sub getLabel {
	return $_[0]->{instances}->getLabel();
};

sub getURI {
	return $_[0]->{instances}->getURI();
};

# return model contains the fact basis of this model
sub getGroundModel {
	return $_[0]->{instances};
};

# Set a base URI for the message.
# Affects creating of new resources and serialization syntax.
# <code>null</code> is just alright, meaning that
# the serializer will use always rdf:about and never rdf:ID
sub setSourceURI {
	$_[0]->{instances}->setSourceURI($_[1]);
};

# Returns current base URI setting
sub getSourceURI {
	return $_[0]->{instances}->getSourceURI();
};

# Model access
#
# Number of triples in the model
# return  number of triples
sub size {
	return -1; #unknown
};

#watch out in sub implementations with DBMS(3)!!!!!!!!
sub isEmpty {
	return $_[0]->{instances}->isEmpty();
};

sub elements {
	#something special here...like merge the instances and closure with SetModel?
};

# Tests if the model contains the given triple.
# return  true if the triple belongs to the model;
# false otherwise.
# !!!watch out in sub implementations with DBMS(3)!!!!!!!!
sub contains {
	croak "Statement ".$_[1]." is not an instance of RDFStore::Stanford::Statement"
		unless((defined $_[1]) && (ref($_[1])) && ($_[1]->isa("RDFStore::Stanford::Statement")));

	# FIXME: efficiency?
	return !($_[0]->find(	$_[1]->subject(),
				$_[1]->predicate(),
				$_[1]->object())->isEmpty());
};

# Model manipulation: add, remove, find
#
# Adds a new triple to the model
sub add {
	$_[0]->{instances}->add($_[1]);
};

# Removes the triple from the model
sub remove {
	$_[0]->{instances}->remove($_[1]);
};

sub isMutable {
	$_[0]->{instances}->isMutable();
};

# General method to search for triples.
# null input for any parameter will match anything.
# Example: Model result = m.find( null, RDF.type, new Resource("http://...#MyClass") )
# finds all instances of the class MyClass
# NOTE: AR want DAML here now :-)
sub find {
	croak "Subject ".$_[1]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[1])) || ( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource'))));
	croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[2])) || ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource'))));
	croak "Object ".$_[3]." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $_[3])) || ( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode'))) );

	# only two special cases for now

	#  we need it anyway
	my $res = $_[0]->{instances}->find($_[1],$_[2],$_[3]);

	# asking for instances - to me it looks really like PEN.pm ;-)
	if ((defined $_[3]) && ($RDFStore::Stanford::type->equals($_[2]))) {
		# find instances
		my $subclass = $_[0]->{closure}->find(undef,$RDFS::subClassOf,$_[3]); 

		if(!($subclass->isEmpty())) {
                	# collect subproperties
			my $k;
			my $v;
			while (($k,$v) = each %{$subclass->elements()}) {
          			$res->unite($_[0]->{instances}->find($_[1],$RDFStore::Stanford::type,$v->subject()) );
			};
      		};
	} elsif($RDFS::subClassOf->equals($_[2])) {
		$res = $_[0]->{closure}->find($_[1],$_[2],$_[3]);
	} elsif(defined $_[2]) {
		# Check for subproperties
		my $subprop = $_[0]->{closure}->find(undef, $RDFS::subPropertyOf,$_[2]);
      		if(!($subprop->isEmpty())) {
                	# collect subproperties
			my $k;
			my $v;
			while (($k,$v) = each %{$subprop->elements()}) {
          			$res->unite($_[0]->{instances}->find($_[1],$v->subject(),$_[3]) );
			};
      		};
	};
        return $res;
};

# Clone the model
sub duplicate {
	# creates a model that shares ONLY the closure with this model
	return new RDFStore::SchemaModel($_[0]->{nodeFactory},$_[0]->{instances}->duplicate(), $_[0]->{closure});
};

# Creates empty model of the same Class
sub create {
	return new RDFStore::SchemaModel($_[0]->{instances}->create(), $_[0]->{closure});
};

sub getNodeFactory {
	return $_[0]->{nodeFactory};	
};

sub toString {
	return "[RDFSchemaModel ".$_[0]->{instances}->getSourceURI()."]";
};

#new bits...

sub computeRDFSClosure {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::SetModel')) );

	#closure must be SetModel!!!
	my $closure = $_[0]->computeClosure($_[1],$RDFS::subClassOf);
    	$closure->unite($_[0]->computeClosure($_[1],$RDFS::subPropertyOf));
	return $closure;
};

# Computes a transitive closure on a given predicate. If <tt>allowLoops</tt> is set to false,
# an exception is thrown if a loop is encountered
sub computeClosure {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::Model')) );
	croak "Property ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Stanford::Resource')) );

	# disallow loops by default
	$_[3] = 0
		if(!(defined $_[3]));

	my $closure = $_[1]->create();

	# find all roots
	my $all = $_[1]->find(undef, $_[2], undef);

    	# compute closure
	my %processedNodes = ();
	my %stack = ();
	my $k;
	my $s;
	while (($k,$s) = each %{$all->elements}) {
		next unless(ref($s));
      		if(	(!(exists $processedNodes{$s->object()})) &&
			($s->object()->isa("RDFStore::Stanford::Resource")) ) {
			%stack = ();
        		if( 	($_[0]->traverseClosure(	\%processedNodes,
							$s->object(), 
							$_[2], 
							\%stack, $closure, $_[1], 0)) &&
				(!($_[3])) ) {
				croak "[RDFSchemaModel] found invalid loop in transitive closure of ",$_[2]->getLabel," Loop node: ",$s->object()->getLabel;
      			};
    		};
    	};
	return $closure;
};

# traverse down the tree, maintains stack and adds shortcuts to the model.
# Returns true if loop is found
sub traverseClosure {
	croak "Hash ".$_[1]." is not an HASH reference"
                unless( (defined $_[1]) &&
                        (ref($_[1]) =~ /HASH/) );
	croak "Resource ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Stanford::Resource')) );
	croak "Resource ".$_[3]." is not instance of RDFStore::Stanford::Resource"
                unless( (defined $_[3]) && (ref($_[3])) &&
                        ($_[3]->isa('RDFStore::Stanford::Resource')) );
	croak "Hash ".$_[4]." is not an HASH reference"
                unless( (defined $_[4]) &&
                        (ref($_[4]) =~ /HASH/) );
	croak "Model ".$_[5]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[5]) && (ref($_[5])) &&
                        ($_[5]->isa('RDFStore::Stanford::SetModel')) );
	croak "Model ".$_[6]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[6]) && (ref($_[6])) &&
                        ($_[6]->isa('RDFStore::Stanford::SetModel')) );
	croak "Integer ".$_[7]." is not a valid INTEGER "
                unless( ($_[7] == 0) || ( (defined $_[7]) && (int($_[7]))) );

	$_[1]->{$_[2]} = $_[2];
	my $isOnStack = (exists $_[4]->{$_[2]});
	my $isLoop = $isOnStack;
	if(!($isOnStack)) {
		$_[4]->{$_[2]} = $_[2];

		# get all children of this node
		my $children = $_[6]->find(undef, $_[3], undef);
		my $k;
		my $s;
		while ( ($k,$s) = each %{$children->elements}) {
			# uauuu!! recursive here :)
        		$isLoop |= $_[0]->traverseClosure($_[1], $s->subject(), $_[3], $_[4], $_[5], $_[6], ($_[7]+1));
      		};

		delete $_[4]->{$_[2]}
			if(!($isLoop));
	};

	# add everything from stack
    	if(!($isOnStack)) {
		my $k;
		my $parent;
		while ( ($k,$parent) = each %{$_[4]}) {
      			$_[5]->add($_[6]->getNodeFactory()->createStatement($_[2], $_[3], $parent));
		};
    	};
	return $isLoop;
};

# Validates <tt>rawInstances</tt> model agains schema in <tt>rawSchema</tt>
sub validateRawSchema {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::SetModel')) );
	croak "Model ".$_[2]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Stanford::SetModel')) );

	my $closure = $_[0]->computeRDFSClosure($_[2]);
	my $schema = new RDFStore::SchemaModel($_[2], $closure);
	my $instances = new RDFStore::SchemaModel($_[1], $closure);
	$_[0]->validate($instances, $schema);
};

# Converts an ordinal property to an integer
sub getOrd {
	croak "Resource ".$_[1]." is not instance of RDFStore::Stanford::Resource"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::Resource')) );

	return -1
		unless(defined $_[1]);

	my $uri = $_[1]->toString();

	#isRDF?
	return -1
		if(!((defined $uri) && ($uri =~ /^$RDFStore::Stanford::_Namespace/)));
                  
	# Position of the namespace end
	my $pos;
	if (	($uri =~ m/#$/g) ||
		($uri =~ m/:$/g) ||
		($uri =~ m/\/$/g) ) {
		$pos=pos($uri);
	} else {
		$pos=length($uri);
	};

	if(($pos > 0) && ($pos + 1 < length($uri))) {
		#parseInt in Perl....
        	my $n = unpack("i*",substring($uri,$pos + 1));
        	return $n
			if($n >= 1);
    	};
	return -1;
};

# Validates the model.  <tt>schema</tt> should be RDFSchemaModel
sub validate {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[1]) && (ref($_[1])) &&
                        ($_[1]->isa('RDFStore::Stanford::SetModel')) );
	croak "Model ".$_[2]." is not instance of RDFStore::Stanford::SetModel"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Stanford::SetModel')) );

	my %containers = (); # triples containing collections and ordinals
	my @errors = ();
	my $k;
	my $t;
	while (($k,$t) = each %{$_[1]->elements}) {
		next unless(ref($t));
		# rdf:type
		if($RDFStore::Stanford::type->equals($t->predicate())) {
			# ensure that the target is of type rdf:Class
			if($t->object()->isa("RDFStore::Stanford::Literal")) {
          			$_[0]->invalid( \@errors, $t, "Literals cannot be used for typing" );
			};
			# cast is skipped in Perl.....
        		my $res = $_[2]->find( $t->object(), $RDFStore::Stanford::type, $RDFS::Class );
			if($res->isEmpty()) {
          			if($_[0]->noSchema(\@errors, $t->object())) {
					break;
				} else {
            				$_[0]->invalid( \@errors, $t, $t->object()->toString() . " must be an instance of ". $RDFS::Class);
        			};
        		};
		} elsif($_[0]->getOrd($t->predicate()) > 0) {
				# save for later
				$containers{$t->subject()}= $t;

		} else {
			# check domain and range
			my @expected = ();

			# find all allowed domains of the Property
			my $domains = $_[2]->find( $t->predicate(), $RDFS::domain, undef );
        		if(!($domains->isEmpty())) {
          			my $domainOK = 0;
				# go through all valid domains and check whether
				# the subject() is an instance of a valid domain Class
				my $k;
				my $domainClass;
				while( ($k,$domainClass) = each %{$domains->elements} ) {
            				push @expected, $domainClass;
            				if(!($_[1]->find($t->subject(),$RDFStore::Stanford::type, $domainClass)->isEmpty())) {
              					$domainOK = 1;
						break;
            				};
          			};
          			if(!($domainOK)) {
            				if($_[0]->noSchema(\@errors, $t->subject())) {
						last;
					} else {
              					$_[0]->invalid( \@errors, $t, "Subject must be instance of ", @expected );
          				};
          			};
        		};
			@expected=();
			# find all allowed domains of the Property
			my $ranges = $_[1]->find( $t->predicate(), $RDFS::range, undef );
        		if($ranges->size() == 1) { # there can be only one range property!!! (See specs)
          			my $rangeOK = 0;
				# go through all valid ranges and check whether
				# the object() is an instance of a valid range Class
				my $k;
				my $rangeClass;
				while ( ($k,$rangeClass)=each %{$ranges->elements}) {
					next unless(ref($rangeClass));
            				push @expect,$rangeClass;
            				# special treatment for Literals
            				if($RDFS::Literal->equals($rangeClass)) {
              					if( $t->object()->isa("RDFStore::Stanford::Literal")) {
							$rangeOK = 1;
                					last;
              					} else {
                					$_[0]->invalid( \@errors, $t, $t->object() ." must be a literal");
						};
					} elsif ( ($t->object()->isa("RDFStore::Stanford::Resource")) && (!($_[1]->instances->find( $t->object(), $RDFStore::Stanford::type, $rangeClass )->isEmpty())) ) {
						$rangeOK = 1;
						last;
					};
				};
				if(!($rangeOK)) {
					if($_[0]->noSchema(\@errors,$t->object())) {
						last;
					} else {
						$_[0]->invalid( \@errors, $t, "Object must be instance of ", @expected);
					};
        			} elsif($ranges->size() > 1) {
          				$_[0]->invalid( \@errors, undef, "Invalid schema. Multiple ranges for ", $t->predicate() );
      				};
      			};
    		};
    	};

	# Don't check containers. I'm not convinced about it.
	if(sclar(@errors)>0) {
		croak "InvalidModel ",@errors;
    	};
};

sub noSchema {
 	return 0;
};

sub invalid {
	croak "Parameter ".$_[1]." is not an ARRAY reference"
                unless( (defined $_[1]) &&
                        (ref($_[1])=~ /ARRAY/) );
	croak "Statement ".$_[2]." is not instance of RDFStore::Stanford::Statement"
                unless( (defined $_[2]) && (ref($_[2])) &&
                        ($_[2]->isa('RDFStore::Stanford::Statement')) );

	if(scalar(@{$_[1]}) > 0) {
		push @{$_[1]},"\n";
    		if(defined $_[2]) {
      			push @{$_[1]},"Invalid statement:\n\t".$t.".\n\t";
    		};
    	};
	push @{$_[1]},$_[3];
};

1;
};

__END__

=head1 NAME

RDFStore::SchemaModel - implementation of the SchemaModel RDF API

=head1 SYNOPSIS

	use RDFStore::SchemaModel;
	my $schema_validator = new RDFStore::SchemaModel();
	my $valid = $schema_validator->validateRawSchema($m,$rawSchema);

=head1 DESCRIPTION

This is an incomplete package and it provides basic RDF Schema support accordingly to the Draft API of Sergey Melnik at http://www-db.stanford.edu/~melnik/rdf/api.html.
Please use it as a prototype and/or just to get the idea. It provide basic 'closure' support and validation of a given RDF instance against an RDF Schema.

=head1 SEE ALSO

RDFStore::Model(3) RDFStore::VirtualModel(3)
RDF Schema Specification 1.0 - http://www.w3.org/TR/2000/CR-rdf-schema-20000327
DARPA Agent Markup Language (DAML) - http://www.daml.org/

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>
