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

package DC;
{
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Stanford::Vocabulary::Generator
#

# Namespace URI of this schema

$_Namespace= "http://purl.org/dc/elements/1.1/";
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
	# The language of the intellectual content of the   resource. Where practical, the content of this field should coincide   with RFC 1766 [Tags for the Identification of Languages,   http://ds.internic.net/rfc/rfc1766.txt ]; examples include en, de,   es, fi, fr, ja, th, and zh.
	$Language = createResource($_[0], "Language");
	# The name given to the resource, usually by the Creator   or Publisher.
	$Title = createResource($_[0], "Title");
	# A rights management statement, an identifier that   links to a rights management statement, or an identifier that links   to a service providing information about rights management for the   resource.
	$Rights = createResource($_[0], "Rights");
	# An identifier of a second resource and its   relationship to the present resource. This element permits links   between related resources and resource descriptions to be   indicated. Examples include an edition of a work (IsVersionOf), a   translation of a work (IsBasedOn), a chapter of a book (IsPartOf),   and a mechanical transformation of a dataset into an image   (IsFormatOf). For the sake of interoperability, relationships should   be selected from an enumerated list that is currently under   development in the workshop series.
	$Relation = createResource($_[0], "Relation");
	#  A textual description of the content of the resource,   including abstracts in the case of document-like objects or content   descriptions in the case of visual resources.
	$Description = createResource($_[0], "Description");
	# A date associated with the creation or availability of   the resource. Such a date is not to be confused with one belonging   in the Coverage element, which would be associated with the resource   only insofar as the intellectual content is somehow about that   date. Recommended best practice is defined in a profile of ISO 8601   [Date and Time Formats (based on ISO8601), W3C Technical Note,   http://www.w3.org/TR/NOTE-datetime] that includes (among others)   dates of the forms YYYY and YYYY-MM-DD. In this scheme, for example,   the date 1994-11-05 corresponds to November 5, 1994.
	$Date = createResource($_[0], "Date");
	# Information about a second resource from which the   present resource is derived. While it is generally recommended that   elements contain information about the present resource only, this   element may contain a date, creator, format, identifier, or other   metadata for the second resource when it is considered important for   discovery of the present resource; recommended best practice is to   use the Relation element instead.  For example, it is possible to   use a Source date of 1603 in a description of a 1996 film adaptation   of a Shakespearean play, but it is preferred instead to use Relation   "IsBasedOn" with a reference to a separate resource whose   description contains a Date of 1603. Source is not applicable if the   present resource is in its original form.
	$Source = createResource($_[0], "Source");
	# A string or number used to uniquely identify the   resource. Examples for networked resources include URLs and URNs   (when implemented). Other globally-unique identifiers, such as   International Standard Book Numbers (ISBN) or other formal names are   also candidates for this element.
	$Identifier = createResource($_[0], "Identifier");
	# The person or organization primarily responsible for   creating the intellectual content of the resource. For example,   authors in the case of written documents, artists, photographers, or   illustrators in the case of visual resources.
	$Creator = createResource($_[0], "Creator");
	# The topic of the resource. Typically, subject will be   expressed as keywords or phrases that describe the subject or   content of the resource. The use of controlled vocabularies and   formal classification schemes is encouraged.
	$Subject = createResource($_[0], "Subject");
	# The category of the resource, such as home page,   novel, poem, working paper, technical report, essay, dictionary. For   the sake of interoperability, Type should be selected from an   enumerated list that is currently under development in the workshop   series.
	$Type = createResource($_[0], "Type");
	# The entity responsible for making the resource   available in its present form, such as a publishing house, a   university department, or a corporate entity.
	$Publisher = createResource($_[0], "Publisher");
	# The spatial or temporal characteristics of the   intellectual content of the resource. Spatial coverage refers to a   physical region (e.g., celestial sector); use coordinates (e.g.,   longitude and latitude) or place names that are from a controlled   list or are fully spelled out. Temporal coverage refers to what the   resource is about rather than when it was created or made available   (the latter belonging in the Date element); use the same date/time   format (often a range) [Date and Time Formats (based on ISO8601),   W3C Technical Note, http://www.w3.org/TR/NOTE-datetime] as   recommended for the Date element or time periods that are from a   controlled list or are fully spelled out.
	$Coverage = createResource($_[0], "Coverage");
	# The data format of the resource, used to identify the   software and possibly hardware that might be needed to display or   operate the resource. For the sake of interoperability, Format   should be selected from an enumerated list that is currently under   development in the workshop series.
	$Format = createResource($_[0], "Format");
	# A person or organization not specified in a Creator   element who has made significant intellectual contributions to the   resource but whose contribution is secondary to any person or   organization specified in a Creator element (for example, editor,   transcriber, and illustrator).
	$Contributor = createResource($_[0], "Contributor");
};
1;
};

__END__

=head1 NAME 
	RDFStore::Vocabulary::DC

=head1 SYNOPSIS

	use RDFStore::Vocabulary::DC;
	print $DC::Title->toString;

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>
