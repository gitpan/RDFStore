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
# *

package RDF;
{
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Stanford::Vocabulary::Generator
#

# Namespace URI of this schema

$_Namespace= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	$Description = createResource($_[0], "Description");
	$parseType = createResource($_[0], "parseType");
	$about = createResource($_[0], "about");
	$resource = createResource($_[0], "resource");
	$aboutEach = createResource($_[0], "aboutEach");
	$aboutEachPrefix = createResource($_[0], "aboutEachPrefix");
	$ID = createResource($_[0], "ID");
	# A triple consisting of a predicate, a subject, and an object
	$Statement = createResource($_[0], "Statement");
	# A collection of alternatives
	$Alt = createResource($_[0], "Alt");
	# Identifies the object of a statement when representing the statement in reified form
	$object = createResource($_[0], "object");
	# Identifies the resource that a statement is describing when representing the statement
	$subject = createResource($_[0], "subject");
	# Identifies the principal value (usually a string) of a property when the property value is a structured resource
	$value = createResource($_[0], "value");
	# Identifies the property used in a statement when representing the statement in reified form
	$predicate = createResource($_[0], "predicate");
	# A name of a property, defining specific meaning for the property
	$Property = createResource($_[0], "Property");
	# An ordered collection
	$Seq = createResource($_[0], "Seq");
	# Identifies the Class of a resource
	$type = createResource($_[0], "type");
	# An unordered collection
	$Bag = createResource($_[0], "Bag");
};
1;
};

__END__

=head1 NAME
        RDFStore::Vocabulary::RDF

=head1 SYNOPSIS

        use RDFStore::Vocabulary::RDF;
        print $RDF::type->toString;

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>
