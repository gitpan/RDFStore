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
# *

package RDF;
{
use vars qw ( $VERSION $Description $parseType $about $resource $aboutEach $aboutEachPrefix $ID $Statement $Alt $object $subject $value $predicate $Property $Seq $type $Bag );
$VERSION='0.4';
use strict;

use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Stanford::Vocabulary::Generator
#

# Namespace URI of this schema

$RDF::_Namespace= "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($RDF::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	# A triple consisting of a predicate, a subject, and an object
	$RDF::Statement = createResource($_[0], "Statement");
	# A collection of alternatives
	$RDF::Alt = createResource($_[0], "Alt");
	# Identifies the object of a statement when representing the statement in reified form
	$RDF::object = createResource($_[0], "object");
	# Identifies the resource that a statement is describing when representing the statement
	$RDF::subject = createResource($_[0], "subject");
	# Identifies the principal value (usually a string) of a property when the property value is a structured resource
	$RDF::value = createResource($_[0], "value");
	# Identifies the property used in a statement when representing the statement in reified form
	$RDF::predicate = createResource($_[0], "predicate");
	# A name of a property, defining specific meaning for the property
	$RDF::Property = createResource($_[0], "Property");
	# An ordered collection
	$RDF::Seq = createResource($_[0], "Seq");
	# Identifies the Class of a resource
	$RDF::type = createResource($_[0], "type");
	# An unordered collection
	$RDF::Bag = createResource($_[0], "Bag");
};
1;
};
