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

use Carp;
use Data::MagicTie;
use RDFStore;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-input_dir <valid_directoryname>] -storename <IDENTIFIER> -query <querystring> [-compression] [-freetext] [-style <BerkeleyDB|DB_File|DBMS>] [-split <number>] [-dbms_host <hostname>] [-dbms_port <port>]

Query an existing RDFStore database.

-h	Print this message

-storename <IDENTIFIER>
		A label or identifier to identify the RDFStore database

-query <querystring>
		A query string to match against the RDFStore database as following:

		# A && (B || C) or A && B || C
		exp		::= subject [',' predicate ] [',' object ] | ['('] exp [operator exp] [')'] | word
		operator	::= 'AND' | 'OR' | 'NOT'
		subject 	::= URI-reference | vocterm
		predicate 	::= URI-reference | vocterm
		object		::= URI-reference | vocterm | word
		word		::= '"' string '"'
		vocterm 	::= vocprefix '::' vocprop
		vocprefix 	::= 'RDF' | 'RDFS' | 'DC' | 'DAML'
		vocprop 	::= string, interpreted based on 
					the vocabulary/schema
		URI-reference	::= string, interpreted per [URI]
		string		::= (any XML text, with "<", ">", and "&" escaped)

		E.g.
			./rdfquery -query 'http://www.daml.org/2000/10/daml-ont#,, AND ,,RDF::subject'

[-input_dir <valid_directoryname>]
		Input directory of existing DB files. Default is cwd.

[-v]	Be verbose

[-compression]
                Use RLE encoding in the persistent RDFStore model

[-freetext]
                Use free-text searching

[-style <BerkeleyDB|DB_File|DBMS>]
		BerkeleyDB, DB_File or DBMS store. Default is DB_File.

[-split <number>]
		Number of DB files to split around - see Data::MagicTie(3)

[-dbms_host <hostname>]
                Name or IP number of the DBMS host. This option makes sense only using the DBMS style; default is 'localhsot' see man dbmsd(8)
 
[-dbms_port <port>]
                TCP/IP port number of the DBMS host. This option makes sense only using the DBMS style; default is 1234

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my $factory = new RDFStore::NodeFactory();

my ($verbose,$compression,$freetext,$query,$storename,$style,$split,$input_dir,$dbms_host,$dbms_port);
my @query;
while (defined($ARGV[0]) and $ARGV[0] =~ /^[-+]/) {
    my $opt = shift;

    if ($opt eq '-storename') {
        $storename = shift;
	$storename .= '/'
                unless( (not(defined $storename)) ||
                        ($storename eq '') ||
                        ($storename =~ /\s+/) ||
                        ($storename =~ /\/$/) );
    } elsif ($opt eq '-style') {
	$style=shift;
    } elsif ($opt eq '-compression') {
        $compression = 1;
    } elsif ($opt eq '-freetext') {
        $freetext = 1;
    } elsif ($opt eq '-query') {
	$query=shift;
	# substitute using matching strings
	unless($query=~/^(\w+)$/) {
		$query =~ s/("[^"]*")/\$factory-\>createLiteral\($1\)/;
		$query =~ s/((\w+:[\/]{1,3})?\w+[^,\s]+)/\$factory\-\>createResource\(\"$1\"\)/g;
		$query =~ s/(\w+::[^\,\)]+)/\$$1/g;

		$query =~ s#\$\$factory\-\>createResource\(\"factory\-\>createLiteral\(\"([^"]+)\"\)"\)#\$factory\-\>createLiteral\(\"$1\"\)#g;

		my @operators;
		#$query =~ s/(.+)\s+\$factory\-\>createResource\(\"AND\"\)\s+(.+)/\( $1 \)\-\>intersect\( \$model\-\>find\( $2 \) /g;
		$query =~ s/(.+)\s+\$factory\-\>createResource\(\"AND\"\)\s+(.+)/\( $1 \)\-\>find\( $2 /g;
		$query =~ s/(.+)\s+\$factory\-\>createResource\(\"OR\"\)\s+(.+)/\( $1 \)\-\>unite\( \$model\-\>find\( $2 \) /g;
		$query =~ s/(.+)\s+\$factory\-\>createResource\(\"NOT\"\)\s+(.+)/\( $1 \)\-\>subtract\( \$model\-\>find\( $2 \) /g;
	} else {
		$query = 'undef,undef,undef,"'.$1.'"';
	};

	$query = '$model->find'.
			(($query=~/^\(/) ? '' : '(' ).	
				$query.')';
				#(($query=~/\)$/) ? '' : ')' );

	$query =~ s/\,\,/\,undef\,/g;
	$query =~ s/\s\,/ undef\,/g;
	$query =~ s/\,\s\)/\,undef \)/g;
	#$query =~ s/\(\s*\,/\(undef\,/g;
	#$query =~ s/\,\s*\)/\,undef\)/g;
	#$query =~ s/\(\s*\(/\(\$model-\>find\(/g;

print STDERR "QUERY string is = $query\n\n";

    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-split') {
	$opt=shift;
        $split = (int($opt)) ? $opt : 0;
    } elsif ($opt eq '-input_dir') {
	$opt=shift;
	$input_dir = $opt
                if(-e $opt);
        $input_dir .= '/'
                unless( (not(defined $input_dir)) ||
                        ($input_dir eq '') ||
                        ($input_dir =~ /\s+/) ||
                        ($input_dir =~ /\/$/) );
    } elsif ($opt eq '-dbms_host') {
        $dbms_host = shift;
    } elsif ($opt eq '-dbms_port') {
	$opt=shift;
        $dbms_port = (int($opt)) ? $opt : undef;
    } else {
        die "Unknown option: $opt\n$Usage";
    };
};

# we assume that the RDFStore has been generated by MagicTie Style parser
my $model = new RDFStore::SetModel(
					Name => $input_dir.$storename,
					Style   =>      $style,
					Host =>    $dbms_host,
                                        Port =>    $dbms_port,
                                        Split       =>      $split,
					Compression => $compression,
					FreeText => $freetext,
					Mode	=>	'r' ) or
	croak "Oh dear, can not tie my model :( $!";
my $result_model = eval $query;

my $err = $@;
croak $err
	if $err;

my($results) = $result_model->elements;
die "No results\n"
	unless(	(defined $result_model) && 
		($#{$results}>=0) );

for my $ii ( 0..$#{$results} ) {
	my $st = $results->[$ii];
	print $st->toString."\n";
};
