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

package RDFS;
{
use vars qw ( $VERSION $Class $Container $subClassOf $ContainerMembershipProperty $isDefinedBy $seeAlso $comment $Resource $Literal $label $domain $ConstraintResource $range $ConstraintProperty $subPropertyOf );
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

$RDFS::_Namespace= "http://www.w3.org/2000/01/rdf-schema#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($RDFS::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	# The concept of Class
	$RDFS::Class = createResource($_[0], "Class");
	# This represents the set Containers.
	$RDFS::Container = createResource($_[0], "Container");
	# Indicates membership of a class
	$RDFS::subClassOf = createResource($_[0], "subClassOf");
	$RDFS::ContainerMembershipProperty = createResource($_[0], "ContainerMembershipProperty");
	# Indicates a resource containing and defining the subject resource.
	$RDFS::isDefinedBy = createResource($_[0], "isDefinedBy");
	# Indicates a resource that provides information about the subject resource.
	$RDFS::seeAlso = createResource($_[0], "seeAlso");
	# Use this for descriptions
	$RDFS::comment = createResource($_[0], "comment");
	# The most general class
	$RDFS::Resource = createResource($_[0], "Resource");
	# This represents the set of atomic values, eg. textual strings.
	$RDFS::Literal = createResource($_[0], "Literal");
	# Provides a human-readable version of a resource name.
	$RDFS::label = createResource($_[0], "label");
	# This is how we associate a class with     properties that its instances can have
	$RDFS::domain = createResource($_[0], "domain");
	# Resources used to express RDF Schema constraints.
	$RDFS::ConstraintResource = createResource($_[0], "ConstraintResource");
	# Properties that can be used in a     schema to provide constraints
	$RDFS::range = createResource($_[0], "range");
	# Properties used to express RDF Schema constraints.
	$RDFS::ConstraintProperty = createResource($_[0], "ConstraintProperty");
	# Indicates specialization of properties
	$RDFS::subPropertyOf = createResource($_[0], "subPropertyOf");
};
1;
};
