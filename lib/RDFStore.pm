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
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.31
# *             - added use (include) of all RDFStore modules suite
# *		- updated documentation
# *

package RDFStore;

$VERSION='0.31';

use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::OpenHealth;
use RDFStore::Parser::Styles::MagicTie;
use RDFStore::RDFNode;
use RDFStore::Literal;
use RDFStore::Resource;
use RDFStore::Statement;
use RDFStore::FindIndex;
use RDFStore::Model;
use RDFStore::NodeFactory;
use RDFStore::SchemaModel;
use RDFStore::SetModel;
use RDFStore::VirtualModel;

1;

__END__

=head1 NAME

RDFStore - This is a set of Perl modules that implement an object-oriented API to manipulate RDF models

=head1 SYNOPSIS

	use RDFStore;

=head1 DESCRIPTION

RDFStore is a set of Perl modules to manage Resource Description Framework (RDF) model databases in a easy and straightforward way. It is a pure Perl implementation of the Draft Java API (see http://www-db.stanford.edu/~melnik/rdf/api.html) from the Stanford University DataBase Group by Sergey Melnik. Together with its companions RDFStore::Parser::SiRPAC(3) and Data::MagicTie(3) modules RDFStore suite allow a user to fetch, parse, process, store and query RDF models.

Modules like RDFStore::Stanford::RDFNode, RDFStore::Stanford::Literal, RDFStore::Stanford::Model and so on define a set of "O-O interfaces" to be implemented by concrete counterparts such as RDFStore::RDFNode, RDFStore::Model and others. The modules defined by RDFStore correspond to the Java org.w3c.rdf.model, org.w3c.rdf.util, org.w3c.rdf.implementation.model, org.w3c.tools.crypt, edu.stanford.db.rdf.schema, edu.stanford.db.rdf.vocabulary, org.w3c.rdf.vocabulary.rdf_syntax_19990222, org.w3c.rdf.vocabulary.rdf_schema_19990303, org.w3c.rdf.vocabulary.dublin_core_1999070 packages defined by Sergey Melnik; the Perl code has been structured as follow:


	Perl packages 		   Java classes
--------------------------------------------------------------
RDFStore::Stanford::*				org.w3c.rdf.model
--------------------------------------------------------------
RDFStore::Stanford::Model			org.w3c.rdf.model.Model
RDFStore::Stanford::Literal 			org.w3c.rdf.model.Literal
RDFStore::Stanford::RDFNode 			org.w3c.rdf.model.RDFNode
RDFStore::Stanford::Resource 			org.w3c.rdf.model.Resource
RDFStore::Stanford::Statement 			org.w3c.rdf.model.Statement
RDFStore::Stanford::NodeFactory 		org.w3c.rdf.model.NodeFactory
RDFStore::Stanford::VirtualModel		org.w3c.rdf.model.VirtualModel
RDFStore::Stanford::SetModel 			org.w3c.rdf.model.SetModel


RDFStore::Stanford::Digest::*				org.w3c.rdf.util,org.w3c.tools.crypt
----------------------------------------------------------------------------
RDFStore::Stanford::Digest				org.w3c.rdf.tools.crypt.Digest
RDFStore::Stanford::Digest::Util			org.w3c.rdf.util.DigestUtil
RDFStore::Stanford::Digest::AbstractDigest	org.w3c.rdf.util.DigestUtil
RDFStore::Stanford::Digest::GenericDigest	org.w3c.rdf.util.DigestUtil
RDFStore::Stanford::Digest::MD5			org.w3c.rdf.util.DigestUtil
RDFStore::Stanford::Digest::SHA1			org.w3c.rdf.util.DigestUtil


RDFStore::*				org.w3c.rdf.implementation.model,edu.stanford.db.rdf.schema
---------------------------------------------------------------------------------------------------
RDFStore::Model			org.w3c.rdf.implementation.model.Model
RDFStore::Literal			org.w3c.rdf.implementation.model.Literal
RDFStore::RDFNode			org.w3c.rdf.implementation.model.RDFNode
RDFStore::Resource		org.w3c.rdf.implementation.model.Resource
RDFStore::Statement		org.w3c.rdf.implementation.model.Statement
RDFStore::NodeFactory		org.w3c.rdf.implementation.model.NodeFactory
RDFStore::VirtualModel		org.w3c.rdf.implementation.model.VirtualModel
RDFStore::SetModel		org.w3c.rdf.implementation.model.SetModel
RDFStore::SchemaModel		edu.stanford.db.rdf.schema.RDFSchemaModel

RDFStore::Stanford::Vocabulary::*				edu.stanford.db.rdf.vocabulary
-------------------------------------------------------------------------------------------
RDFStore::Stanford::Vocabulary::Generator		edu.stanford.db.rdf.vocabulary.Generator

RDFStore::Stanford::Vocabulary::RDF			org.w3c.rdf.vocabulary.rdf_syntax_19990222.RDF
RDFStore::Stanford::Vocabulary::RDFS			org.w3c.rdf.vocabulary.rdf_schema_19990303.RDFS
RDFStore::Stanford::Vocabulary::DC				org.w3c.rdf.vocabulary.dublin_core_19990702.DC


The Perl RDF API implementation is almost aligned with the Java one (some feauture were left out because for it difficulty or impossibility in the implementation). E.g. Perl do not have Exceptions as built in construcut, and altough they could be easily implemented with eval() and $@ checking, RDFStore just uses the Carp module to warn, croak or confess on errors. In the RDFStore branch the modules code has been extended and modified to use the Data::MagicTie(3) interface and a different indexing mechanism in RDFStore::FindIndex(3). Similarly the RDFStore::Stanford::Vocabulary::Generator(3) now generates valid Perl5 modules containing constants definitions of input RDF Schema.

For the whole API documentation you can temporarly refer to the JavaDoc version at http://www-db.stanford.edu/~melnik/rdf/api-doc/

In addition I invite you to look at the samples and utils directory coming with the RDFStore distribution for a fruitful set of examples to play with :-)

=head1 BUGS

This module implements most of the classes and packages as its Java counterpart from the Stanford University Database Group by Sergey Melnik (see http://www-db.stanford.edu/~melnik/rdf/api.html), but some feature have been missied on purposed or just forgotten ;-)
This RDFsotre version is up-to-date with the latest changes from current revision: 2000-12-05 of Stanford Java API.

Not supported:

	* NodeFactory::createOrdinal()
	* order/backorder experimental from Sergey Melnik

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3), DBMS(3) and XML::Parser(3) XML::Parser::Expat(3)
RDFStore::Stanford::Model(3) RDFStore::NodeFactory(3)
Summary of Recent Discussions about an Application Programming Interface for RDF - http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/

RDF Model and Syntax Specification - http://www.w3.org/TR/REC-rdf-syntax
RDF Schema Specification 1.0 - http://www.w3.org/TR/2000/CR-rdf-schema-20000327
Statements/Statings - http://ilrt.org/discovery/2000/11/statements/

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

	Sergey Melnik <melnik@db.stanford.edu> is the original author of the Java RDF API - txs Sergey!
