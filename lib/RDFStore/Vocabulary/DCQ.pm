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

package DCQ;
{
use vars qw ( $VERSION $isVersionOf $created $W3CDTF $tableOfContents $SpatialScheme $available $isFormatOf $modified $DDC $DD $isReferencedBy $IdentifierScheme $IMT $TGN $UDC $LCSH $SubjectScheme $FormatScheme $isRequiredBy $URI $Period $classification $DMS $hasFormat $temporal $issued $Box $release $MESH $note $spatial $DateScheme $requires $extent $ISO639_2 $valid $isPartOf $ISO3166 $hasVersion $abstract $Point $replaces $LanguageScheme $RFC1766 $references $alternative $LCC $hasPart $medium $isReplacedBy );
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
$DCQ::_Namespace= "http://dublincore.org/2000/03/13-dcq#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($DCQ::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	# The described resource is a version, edition, or  adaptation of the referenced resource. Changes in version imply  substantive changes in content rather than differences in  format. 
	$DCQ::isVersionOf = createResource($_[0], "isVersionOf");
	# Date of creation of the resource.
	$DCQ::created = createResource($_[0], "created");
	# W3C Encoding rules for dates and times - a profile  based on ISO8601 
	$DCQ::W3CDTF = createResource($_[0], "W3CDTF");
	# A list of subunits of the content of the  resource.
	$DCQ::tableOfContents = createResource($_[0], "tableOfContents");
	# A set of geographic place encoding schemes and/or  formats
	$DCQ::SpatialScheme = createResource($_[0], "SpatialScheme");
	# Date (often a range) that the resource will become or  did become available.
	$DCQ::available = createResource($_[0], "available");
	# The described resource is the same intellectual  content of the referenced resource, but presented in another  format. 
	$DCQ::isFormatOf = createResource($_[0], "isFormatOf");
	# Date on which the resource was changed.
	$DCQ::modified = createResource($_[0], "modified");
	# Dewey Decimal Classification
	$DCQ::DDC = createResource($_[0], "DDC");
	# A latitude and longitude expressed in decimal  degrees
	$DCQ::DD = createResource($_[0], "DD");
	# The described resource is referenced, cited, or  otherwise pointed to by the referenced resource. 
	$DCQ::isReferencedBy = createResource($_[0], "isReferencedBy");
	# A set of Identified encoding schemes and/or  formats.
	$DCQ::IdentifierScheme = createResource($_[0], "IdentifierScheme");
	# The Internet media type of the resource.
	$DCQ::IMT = createResource($_[0], "IMT");
	# The Getty Thesaurus of Geographic Names
	$DCQ::TGN = createResource($_[0], "TGN");
	# Universal Decimal Classification
	$DCQ::UDC = createResource($_[0], "UDC");
	# Library of Congress Subject Headings
	$DCQ::LCSH = createResource($_[0], "LCSH");
	# A set of subject encoding schemes and/or formats
	$DCQ::SubjectScheme = createResource($_[0], "SubjectScheme");
	# A set of format encoding schemes.
	$DCQ::FormatScheme = createResource($_[0], "FormatScheme");
	# The described resource is required by the referenced  resource, either physically or logically.  
	$DCQ::isRequiredBy = createResource($_[0], "isRequiredBy");
	# A URI Uniform Resource Identifier
	$DCQ::URI = createResource($_[0], "URI");
	# A specification of the limits of a time  interval.
	$DCQ::Period = createResource($_[0], "Period");
	# Subject identified by notation (code) taken from a  controlled classification scheme.
	$DCQ::classification = createResource($_[0], "classification");
	# A latitude and longitude expressed in degrees,  minutes, seconds.
	$DCQ::DMS = createResource($_[0], "DMS");
	# The described resource pre-existed the referenced  resource, which is essentially the same intellectual content  presented in another format. 
	$DCQ::hasFormat = createResource($_[0], "hasFormat");
	# Temporal characteristics of the intellectual content  of the resource.
	$DCQ::temporal = createResource($_[0], "temporal");
	# Date of formal issuance (e.g., publication) of the  resource.
	$DCQ::issued = createResource($_[0], "issued");
	# The DCMI Box identifies a region of space using its  geographic limits.
	$DCQ::Box = createResource($_[0], "Box");
	# An identification of the edition, release or version  of the resource.
	$DCQ::release = createResource($_[0], "release");
	# Medical Subject Headings
	$DCQ::MESH = createResource($_[0], "MESH");
	# Any additional information about the content of the  resource.
	$DCQ::note = createResource($_[0], "note");
	# Spatial characteristics of the intellectual content of  the resoure.
	$DCQ::spatial = createResource($_[0], "spatial");
	# A set of date encoding schemes and/or formats
	$DCQ::DateScheme = createResource($_[0], "DateScheme");
	# The described resource requires the referenced  resource to support its function, delivery, or coherence of  content. 
	$DCQ::requires = createResource($_[0], "requires");
	# The size or duration of the resource.
	$DCQ::extent = createResource($_[0], "extent");
	# ISO 639-2: Codes for the representation of names of languages.
	$DCQ::ISO639_2 = createResource($_[0], "ISO639_2");
	# Date (often a range) of validity of a resource.
	$DCQ::valid = createResource($_[0], "valid");
	# The described resource is a physical or logical part of the referenced resource.
	$DCQ::isPartOf = createResource($_[0], "isPartOf");
	# ISO3166 Codes for the representation of names of  countries
	$DCQ::ISO3166 = createResource($_[0], "ISO3166");
	# The described resource has a version, edition, or  adaptation, namely, the referenced resource. 
	$DCQ::hasVersion = createResource($_[0], "hasVersion");
	# A summary of the content of the resource.
	$DCQ::abstract = createResource($_[0], "abstract");
	# The DCMI Point identifies a point in space using its  geographic coordinates.
	$DCQ::Point = createResource($_[0], "Point");
	# The described resource supplants, displaces, or  supersedes the referenced resource.  
	$DCQ::replaces = createResource($_[0], "replaces");
	# A set of language encoding schemes and/or  formats.
	$DCQ::LanguageScheme = createResource($_[0], "LanguageScheme");
	# Internet RFC 1766 'Tags for the identification of  Language' specifies a two letter code taken from ISO 639, followed  optionally by a two letter country code taken from ISO  3166.
	$DCQ::RFC1766 = createResource($_[0], "RFC1766");
	# The described resource references, cites, or otherwise  points to the referenced resource.  
	$DCQ::references = createResource($_[0], "references");
	# Any form of the title used as a substitute or  alternative to the formal title of the resource.
	$DCQ::alternative = createResource($_[0], "alternative");
	# Library of Congress Classification
	$DCQ::LCC = createResource($_[0], "LCC");
	# The described resource includes the referenced  resource either physically or logically. 
	$DCQ::hasPart = createResource($_[0], "hasPart");
	# The material or physical carrier of the  resource.
	$DCQ::medium = createResource($_[0], "medium");
	# The described resource is supplanted, displaced, or  superceded by the referenced resource.
	$DCQ::isReplacedBy = createResource($_[0], "isReplacedBy");
};
1;
};
