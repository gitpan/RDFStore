#!/usr/local/bin/perl -I ../lib
##############################################################################
# 	Copyright (c) 2000 All rights reserved
#	Alberto Reggiori <areggiori@webweaving.org>
#
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 5. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and
# Dirk-Willem van Gulik and was originally based on public domain software
# written at the Stanford University Database Group by Sergey Melnik.
# For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
#
##############################################################################

# this is the script validates an RDF model against an RDF schemas

use Carp;
use RDFStore;
    
my @schemas = ();

my ($outputDirectory, $packageClass, $namespace, $factoryStr);

if(scalar(@ARGV) == 0) {
	print STDERR "RDFSchemaModel <instance URL> {<schema URL>}+\n";
	exit(1);
};

my $f = new RDFStore::NodeFactory();
my $rawSchema = new RDFStore::SetModel();

#readModelsFromArgList
my $fileNameOrURL = shift @ARGV;
print "READING INSTANCE: ". $fileNameOrURL;

my $p=new RDFStore::Parser::SiRPAC( ErrorContext => 2,
                                Style => 'RDFStore::Parser::Styles::MagicTie',
                                NodeFactory     => $f,
                                Source  => $fileNameOrURL,
                                );
my $m = $p->parsefile($fileNameOrURL);
print " - DONE\n";

# in case there is schema info in the instance, append in to the schema
while (my $arg = shift @ARGV) {
	print "..";
	my $schemaURL = $arg;
	print "READING SCHEMA: ".$schemaURL;
	my $p=new RDFStore::Parser::SiRPAC( ErrorContext => 2,
                                Style => 'RDFStore::Parser::Styles::MagicTie',
                                NodeFactory     => $f,
                                Source  => $schemaURL,
                                );
	my $partialSchema = $p->parsefile($schemaURL);
	$rawSchema->unite($partialSchema);
	print " - DONE\n";
};

my $schema_validator = new RDFStore::SchemaModel();
my $valid = $schema_validator->validateRawSchema($m,$rawSchema);

print "Model is ";
print "NOT "
	if(!(defined $valid));
print "valid\n";
