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

package DAML;
{
use vars qw ( $VERSION $domain $nil $List $maxCardinality $cardinality $onProperty $unionOf $versionInfo $hasClassQ $TransitiveProperty $hasValue $Restriction $item $sameIndividualAs $Nothing $Class $Ontology $Thing $inverseOf $differentIndividualFrom $cardinalityQ $intersectionOf $samePropertyAs $Property $complementOf $isDefinedBy $toClass $sameClassAs $disjointWith $value $oneOf $UnambiguousProperty $UniqueProperty $subPropertyOf $ObjectProperty $minCardinality $hasClass $comment $rest $type $equivalentTo $DatatypeProperty $imports $maxCardinalityQ $Literal $first $disjointUnionOf $subClassOf $seeAlso $Datatype $minCardinalityQ $label $range );
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
$DAML::_Namespace= "http://www.daml.org/2001/03/daml+oil#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($DAML::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
	$DAML::domain = createResource($_[0], "domain");
	#      the empty list; this used to be called Empty.
	$DAML::nil = createResource($_[0], "nil");
	$DAML::List = createResource($_[0], "List");
	#     for onProperty(R, P) and maxCardinality(R, n), read:    i is in class R if and only if there are at most n distinct j with P(i, j).    cf OIL MaxCardinality
	$DAML::maxCardinality = createResource($_[0], "maxCardinality");
	#     for onProperty(R, P) and cardinality(R, n), read:    i is in class R if and only if there are exactly n distinct j with P(i, j).    cf OIL Cardinality
	$DAML::cardinality = createResource($_[0], "cardinality");
	#     for onProperty(R, P), read:    R is a restricted with respect to property P.
	$DAML::onProperty = createResource($_[0], "onProperty");
	#     for unionOf(X, Y) read: X is the union of the classes in the list Y;    i.e. if something is in any of the classes in Y, it's in X, and vice versa.    cf OIL OR
	$DAML::unionOf = createResource($_[0], "unionOf");
	#     generally, a string giving information about this    version; e.g. RCS/CVS keywords
	$DAML::versionInfo = createResource($_[0], "versionInfo");
	#     property for specifying class restriction with cardinalityQ constraints
	$DAML::hasClassQ = createResource($_[0], "hasClassQ");
	#     if P is a TransitiveProperty, then if P(x, y) and P(y, z) then P(x, z).    cf OIL TransitiveProperty.
	$DAML::TransitiveProperty = createResource($_[0], "TransitiveProperty");
	#     for onProperty(R, P) and hasValue(R, V), read:    i is in class R if and only if P(i, V).    cf OIL HasFiller
	$DAML::hasValue = createResource($_[0], "hasValue");
	#     something is in the class R if it satisfies the attached restrictions,     and vice versa.
	$DAML::Restriction = createResource($_[0], "Restriction");
	#     for item(L, I) read: I is an item in L; either first(L, I)    or item(R, I) where rest(L, R).
	$DAML::item = createResource($_[0], "item");
	#     for sameIndividualAs(a, b), read a is the same individual as b.
	$DAML::sameIndividualAs = createResource($_[0], "sameIndividualAs");
	# the class with no things in it.
	$DAML::Nothing = createResource($_[0], "Nothing");
	#     The class of all "object" classes
	$DAML::Class = createResource($_[0], "Class");
	#     An Ontology is a document that describes    a vocabulary of terms for communication between    (human and) automated agents.
	$DAML::Ontology = createResource($_[0], "Ontology");
	#     The most general (object) class in DAML.    This is equal to the union of any class and its complement.
	$DAML::Thing = createResource($_[0], "Thing");
	#     for inverseOf(R, S) read: R is the inverse of S; i.e.    if R(x, y) then S(y, x) and vice versa.    cf OIL inverseRelationOf
	$DAML::inverseOf = createResource($_[0], "inverseOf");
	#     for differentIndividualFrom(a, b), read a is not the same individual as b.
	$DAML::differentIndividualFrom = createResource($_[0], "differentIndividualFrom");
	#     for onProperty(R, P), cardinalityQ(R, n) and hasClassQ(R, X), read:    i is in class R if and only if there are exactly n distinct j with P(i, j)    and type(j, X).    cf OIL Cardinality
	$DAML::cardinalityQ = createResource($_[0], "cardinalityQ");
	#     for intersectionOf(X, Y) read: X is the intersection of the classes in the list Y;    i.e. if something is in all the classes in Y, then it's in X, and vice versa.    cf OIL AND
	$DAML::intersectionOf = createResource($_[0], "intersectionOf");
	#     for samePropertyAs(P, R), read P is an equivalent property to R.
	$DAML::samePropertyAs = createResource($_[0], "samePropertyAs");
	$DAML::Property = createResource($_[0], "Property");
	#     for complementOf(X, Y) read: X is the complement of Y; if something is in Y,    then it's not in X, and vice versa.    cf OIL NOT
	$DAML::complementOf = createResource($_[0], "complementOf");
	$DAML::isDefinedBy = createResource($_[0], "isDefinedBy");
	#     for onProperty(R, P) and toClass(R, X), read:    i is in class R if and only if for all j, P(i, j) implies type(j, X).    cf OIL ValueType
	$DAML::toClass = createResource($_[0], "toClass");
	$DAML::sameClassAs = createResource($_[0], "sameClassAs");
	#     for disjointWith(X, Y) read: X and Y have no members in common.    cf OIL Disjoint
	$DAML::disjointWith = createResource($_[0], "disjointWith");
	$DAML::value = createResource($_[0], "value");
	#      for oneOf(C, L) read everything in C is one of the     things in L;     This lets us define classes by enumerating the members.     cf OIL OneOf
	$DAML::oneOf = createResource($_[0], "oneOf");
	#     if P is an UnambiguousProperty, then if P(x, y) and P(z, y) then x=z.    aka injective. e.g. if firstBorne(m, Susan)    and firstBorne(n, Susan) then m and n are the same.
	$DAML::UnambiguousProperty = createResource($_[0], "UnambiguousProperty");
	#     compare with maxCardinality=1; e.g. integer successor:    if P is a UniqueProperty, then if P(x, y) and P(x, z) then y=z.    cf OIL FunctionalProperty.
	$DAML::UniqueProperty = createResource($_[0], "UniqueProperty");
	$DAML::subPropertyOf = createResource($_[0], "subPropertyOf");
	#     if P is an ObjectProperty, and P(x, y), then y is an object.
	$DAML::ObjectProperty = createResource($_[0], "ObjectProperty");
	#     for onProperty(R, P) and minCardinality(R, n), read:    i is in class R if and only if there are at least n distinct j with P(i, j).    cf OIL MinCardinality
	$DAML::minCardinality = createResource($_[0], "minCardinality");
	#     for onProperty(R, P) and hasClass(R, X), read:    i is in class R if and only if for some j, P(i, j) and type(j, X).    cf OIL HasValue
	$DAML::hasClass = createResource($_[0], "hasClass");
	$DAML::comment = createResource($_[0], "comment");
	$DAML::rest = createResource($_[0], "rest");
	$DAML::type = createResource($_[0], "type");
	$DAML::equivalentTo = createResource($_[0], "equivalentTo");
	#     if P is a DatatypeProperty, and P(x, y), then y is a data value.
	$DAML::DatatypeProperty = createResource($_[0], "DatatypeProperty");
	#     for imports(X, Y) read: X imports Y;    i.e. X asserts the* contents of Y by reference;    i.e. if imports(X, Y) and you believe X and Y says something,    then you should believe it.    Note: "the contents" is, in the general case,    an il-formed definite description. Different    interactions with a resource may expose contents    that vary with time, data format, preferred language,    requestor credentials, etc. So for "the contents",    read "any contents".
	$DAML::imports = createResource($_[0], "imports");
	#     for onProperty(R, P), maxCardinalityQ(R, n) and hasClassQ(R, X), read:    i is in class R if and only if there are at most n distinct j with P(i, j)    and type(j, X).    cf OIL MaxCardinality
	$DAML::maxCardinalityQ = createResource($_[0], "maxCardinalityQ");
	$DAML::Literal = createResource($_[0], "Literal");
	$DAML::first = createResource($_[0], "first");
	#     for disjointUnionOf(X, Y) read: X is the disjoint union of the classes in    the list Y: (a) for any c1 and c2 in Y, disjointWith(c1, c2),    and (b) unionOf(X, Y). i.e. if something is in any of the classes in Y, it's    in X, and vice versa.    cf OIL disjoint-covered
	$DAML::disjointUnionOf = createResource($_[0], "disjointUnionOf");
	$DAML::subClassOf = createResource($_[0], "subClassOf");
	$DAML::seeAlso = createResource($_[0], "seeAlso");
	#     The class of all datatype classes
	$DAML::Datatype = createResource($_[0], "Datatype");
	#     for onProperty(R, P), minCardinalityQ(R, n) and hasClassQ(R, X), read:    i is in class R if and only if there are at least n distinct j with P(i, j)     and type(j, X).    cf OIL MinCardinality
	$DAML::minCardinalityQ = createResource($_[0], "minCardinalityQ");
	$DAML::label = createResource($_[0], "label");
	$DAML::range = createResource($_[0], "range");
};
1;
};
