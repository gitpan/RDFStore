# *
# *     Copyright (c) 2000 Alberto Reggiori <areggiori@webweaving.org>
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

package DC;
{
use vars qw ( $VERSION $contributor $description $creator $date $coverage $rights $subject $title $type $source $relation $language $format $identifier $publisher );
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
$DC::_Namespace= "http://dublincore.org/2000/03/13-dces#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($DC::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	# An entity responsible for making contributions to the  content of the resource.
	$DC::contributor = createResource($_[0], "contributor");
	# An account of the content of the resource.
	$DC::description = createResource($_[0], "description");
	# An entity primarily responsible for making the content  of the resource.
	$DC::creator = createResource($_[0], "creator");
	# A date associated with an event in the life cycle of  the resource.
	$DC::date = createResource($_[0], "date");
	#  The extent or scope of the content of the  resource.
	$DC::coverage = createResource($_[0], "coverage");
	#  Information about rights held in and over the  resource.
	$DC::rights = createResource($_[0], "rights");
	# The topic of the content of the resource.
	$DC::subject = createResource($_[0], "subject");
	# A name given to the resource.
	$DC::title = createResource($_[0], "title");
	# The nature or genre of the content of the  resource.
	$DC::type = createResource($_[0], "type");
	# A Reference to a resource from which the present  resource is derived.
	$DC::source = createResource($_[0], "source");
	#  A reference to a related resource.
	$DC::relation = createResource($_[0], "relation");
	#  A language of the intellectual content of the  resource.
	$DC::language = createResource($_[0], "language");
	# The physical or digital manifestation of the  resource.
	$DC::format = createResource($_[0], "format");
	# An unambiguous reference to the resource within a  given context.
	$DC::identifier = createResource($_[0], "identifier");
	# An entity responsible for making the resource  available.
	$DC::publisher = createResource($_[0], "publisher");
};
1;
};
