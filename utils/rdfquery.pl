#!/usr/bin/perl
##############################################################################
# 	Copyright (c) 2000-2004 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
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
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
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
# Dirk-Willem van Gulik. The RDF specific part is based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################

use Carp;
use RDFStore::Model;
use RDFStore::NodeFactory;
use DBI;

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-storename <IDENTIFIER>] [-serialize <syntax>] [-query <querystring>] <querystring>

Query an existing RDFStore database.

-h	Print this message

[-query <querystring>] or last argument of command line
		A RDQL query (see http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/ for syntax)

		E.g.

		SELECT
			?title, ?link
		FROM
			<http://xmlhack.com/rss10.php>
		WHERE
			(?item, <rdf:type>, <rss:item>),
			(?item, <rss::title>, ?title),
			(?item, <rss::link>, ?link)
		USING
			rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
			rss for <http://purl.org/rss/1.0/>

[-storename <IDENTIFIER>]
		RDFStore database name IDENTIFIER is like rdfstore://[HOSTNAME[:PORT]]/PATH/DBDIRNAME

                        E.g. URLs
                                        rdfstore://mysite.foo.com:1234/this/is/my/rd/store/database
                                        rdfstore:///root/this/is/my/rd/store/database

[-v]	Be verbose

[-serialize RDF/XML | NTriples | rdfqr-results | rdf-for-xml ]
                generate results as RDF/XML, NTriples, RDF Query and Rules (http://www.w3.org/2003/03/rdfqr-tests/recording-query-results.html) or RDF-for-XML (http://jena.hpl.hp.com/~afs/RDF-XML.html) syntax

Main paramter is the query.

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($verbose,$query,$storename,$input_dir,$dbms_host,$dbms_port,$serialize);
my @query;
while (defined($ARGV[0])) {
    my $opt = shift;

    if ($opt eq '-storename') {
        $storename = shift;
    } elsif ($opt eq '-query') {
	print STDERR "WARNING! -query option is deprecated - input query is defined to be last passed argument now\n";
	$query=shift;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
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
    } elsif ($opt eq '-serialize') {
        $serialize = shift;
	$serialize = 'RDF/XML'
		unless($serialize);
    } else {
	$query=$opt;
    	};
};

my $factory = new RDFStore::NodeFactory();
my $dbh = DBI->connect("DBI:RDFStore:database=$input_dir$storename;host=$dbms_host;port=$dbms_port", "pincopallino", 0, { nodeFactory => $factory, asRDF => { syntax => $serialize } } )
	or die "Oh dear, can not connect to rdfstore: $!";

my $sth;
eval {
        $sth=$dbh->prepare($query);
	$sth->execute();
};
my $err = $@;
croak $err
	if $err;

my $rows=0;
while (my $row = $sth->fetchrow_hashref()) {
	unless($serialize) {
		map {
			print "$_ = ",$row->{$_}->toString,"\n";
		} keys %{$row};
		print "\n";
		$rows++;
        	};
        };

unless($serialize) {
	die "No results\n"
		unless($rows>0);

	print "Matched: ".$rows." rows\n";
	};

$sth->finish();
