# *
# *     Copyright (c) 2000 Alberto Reggiori / <alberto.reggiori@jrc.it>
# *     ISIS/RIT, Joint Research Center Ispra (I)
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

package DAML;
{
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Stanford::Vocabulary::Generator
#

# Namespace URI of this schema
$_Namespace= "http://www.daml.org/2000/10/daml-ont#";
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
	# compare with maxCardinality=1; e.g. integer successor:  if P is a UniqueProperty, then  if P(x, y) and P(x, z) then y=z.  aka functional. 
	$UniqueProperty = createResource($_[0], "UniqueProperty");
	$Property = createResource($_[0], "Property");
	$Empty = createResource($_[0], "Empty");
	# the class with no things in it.
	$Nothing = createResource($_[0], "Nothing");
	#     for complementOf(X, Y) read: X is the complement of Y; if something is in Y,     then it's not in X, and vice versa. cf OIL NOT
	$complementOf = createResource($_[0], "complementOf");
	$domain = createResource($_[0], "domain");
	# for inverseOf(R, S) read: R is the inverse of S; i.e.      if R(x, y) then S(y, x) and vice versa.
	$inverseOf = createResource($_[0], "inverseOf");
	# The most general class in DAML.
	$Thing = createResource($_[0], "Thing");
	# generally, a string giving information about this  version; e.g. RCS/CVS keywords 
	$versionInfo = createResource($_[0], "versionInfo");
	# for qualifiedBy(C, Q), read: C is qualified by Q; i.e. the  qualification Q applies to C;          if onProperty(Q, P) and hasValue(Q, C2)         then for every i in C, there is some V  so that type(V, C2) and P(i, V). 
	$qualifiedBy = createResource($_[0], "qualifiedBy");
	$Class = createResource($_[0], "Class");
	# if P is an UnambiguousProperty, then  if P(x, y) and P(z, y) then x=z.  aka injective.  e.g. if nameOfMonth(m, "Feb")  and nameOfMonth(n, "Feb") then m and n are the same month. 
	$UnambiguousProperty = createResource($_[0], "UnambiguousProperty");
	$range = createResource($_[0], "range");
	$first = createResource($_[0], "first");
	$List = createResource($_[0], "List");
	#     for disjointUnionOf(X, Y) read: X is the disjoint union of the classes in     the list Y: (a) for any c1 and c2 in Y, disjointWith(c1, c2),     and (b) i.e. if something is in any of the classes in Y, it's     in X, and vice versa.      cf OIL disjoint-covered 
	$disjointUnionOf = createResource($_[0], "disjointUnionOf");
	# for toValue(R, V), read: R is a restriction to V.
	$toValue = createResource($_[0], "toValue");
	$subClassOf = createResource($_[0], "subClassOf");
	$Qualification = createResource($_[0], "Qualification");
	$Restriction = createResource($_[0], "Restriction");
	$Literal = createResource($_[0], "Literal");
	# for restrictedBy(C, R), read: C is restricted by R; i.e. the  restriction R applies to c;          if onProperty(R, P) and toValue(R, V)         then for every i in C, we have P(i, V).          if onProperty(R, P) and toClass(R, C2)         then for every i in C and for all j, if P(i, j) then type(j, C2). 
	$restrictedBy = createResource($_[0], "restrictedBy");
	# for type(L, Disjoint) read: the classes in L are   pairwise disjoint.    i.e. if type(L, Disjoint), and C1 in L and C2 in L, then disjointWith(C1, C2). 
	$Disjoint = createResource($_[0], "Disjoint");
	# for imports(X, Y) read: X imports Y;  i.e. X asserts the* contents of Y by reference;  i.e. if imports(X, Y) and you believe X and Y says something,  then you should believe it.   Note: "the contents" is, in the general case,  an il-formed definite description. Different  interactions with a resource may expose contents  that vary with time, data format, preferred language,  requestor credentials, etc. So for "the contents",  read "any contents". 
	$imports = createResource($_[0], "imports");
	#     for unionOf(X, Y) read: X is the union of the classes in the list Y;     i.e. if something is in any of the classes in Y, it's in X, and vice versa.     cf OIL OR
	$unionOf = createResource($_[0], "unionOf");
	# An Ontology is a document that describes  a vocabulary of terms for communication between  (human and) automated agents. 
	$Ontology = createResource($_[0], "Ontology");
	# for minCardinality(P, N) read: P has minimum cardinality N; i.e.     everything x in the domain of P has at least N things y such that P(x, y). 
	$minCardinality = createResource($_[0], "minCardinality");
	# for onProperty(R, P), read:    R is a restriction/qualification on P.
	$onProperty = createResource($_[0], "onProperty");
	# for oneOf(C, L) read everything in C is one of the      things in L;      This lets us define classes by enumerating the members. 
	$oneOf = createResource($_[0], "oneOf");
	# for item(L, I) read: I is an item in L; either first(L, I)     or item(R, I) where rest(L, R).
	$item = createResource($_[0], "item");
	# for equivalentTo(X, Y), read X is an equivalent term to Y. 
	$equivalentTo = createResource($_[0], "equivalentTo");
	$subPropertyOf = createResource($_[0], "subPropertyOf");
	# for disjointWith(X, Y) read: X and Y have no members  in common. 
	$disjointWith = createResource($_[0], "disjointWith");
	$seeAlso = createResource($_[0], "seeAlso");
	$comment = createResource($_[0], "comment");
	# for maxCardinality(P, N) read: P has maximum cardinality N; i.e.     everything x in the domain of P has at most N things y such that P(x, y). 
	$maxCardinality = createResource($_[0], "maxCardinality");
	# for hasValue(Q, C), read: Q is a hasValue    qualification to C.
	$hasValue = createResource($_[0], "hasValue");
	# for toClass(R, C), read: R is a restriction to C.
	$toClass = createResource($_[0], "toClass");
	$value = createResource($_[0], "value");
	#     for intersectionOf(X, Y) read: X is the intersection of the classes in the list Y;     i.e. if something is in all the classes in Y, then it's in X, and vice versa. cf OIL AND
	$intersectionOf = createResource($_[0], "intersectionOf");
	# default(X, Y) suggests that Y be considered a/the default  value for the X property. This can be considered  documentation (ala label, comment) but we don't specify  any logical impact. 
	$default = createResource($_[0], "default");
	# for cardinality(P, N) read: P has cardinality N; i.e.     everything x in the domain of P has N things y such that P(x, y). 
	$cardinality = createResource($_[0], "cardinality");
	$rest = createResource($_[0], "rest");
	$isDefinedBy = createResource($_[0], "isDefinedBy");
	$type = createResource($_[0], "type");
	$TransitiveProperty = createResource($_[0], "TransitiveProperty");
	$label = createResource($_[0], "label");
};

1;
};
