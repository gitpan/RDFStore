#!/usr/local/bin/perl -I ../lib
##############################################################################
# 	Copyright (c) 2000 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
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

use RDFStore;
use Carp;

my $Usage =<<EOU;
Usage is:
    $0 [-h] -strawman -bagIDs -GenidNumberFile -stuff <URL_or_filename> [-output_dir <valid_directoryname>] [-storename <IDENTIFIER>] [-style <BerkeleyDB|DB_File|DBMS>] [-split <number>] [-dbms_host <hostname>] [-dbms_port <port>] [-serialise]

Parse an input RDF file and optionally store the generated triplets into a Data::MagicTie(3) database using the RDFStore(3) API.

-h	Print this message
-v	Be verbose

-strawman
		RDFStore::Parser::OpenHealth parser, RDFStore::Parser::SiRPAC otherwise.
-bagIDs
		generates Bag instances for each Description block.

-GenidNumberFile
		EXISTING valid filename containing a single integer value to seed the parser "genid" numbers with the given value (I.e. for anonymous resources). Note that an exclusive lock on the file is used to guarantee that the value is consistent across runs (and concurrent processes)

-stuff	<URL_or_filename>
		URL or filename. '-' denotes STDIN

[-output_dir <valid_directoryname>]
		Output directory for DB files generated. Default is cwd.

[-storename <IDENTIFIER>]
		A label or identifier to identify the RDFStore database. By setting this option the parsing results 
		are stored in DB files. Default is to use in-memory datastructures. To use rdfquery.pl later you want 
		to set 1 here :-)
		(see -output_dir also)

[-namespace <URL_or_filename>]
		Specify a string to set a base URI to use for the generation of 
		resource URIs during parsing

[-style <BerkeleyDB|DB_File|DBMS>]
		BerkeleyDB, DB_File or DBMS store. Default is DB_File.

[-split <number>]
		Number of DB files to split around - see Data::MagicTie(3)

[-dbms_host <hostname>]
		Name or IP number of the DBMS host. This option makes sense only using the DBMS style; default is 'localhsot' see man dbmsd(8)

[-dbms_port <port>]
		TCP/IP port number of the DBMS host. This option makes sense only using the DBMS style; default is 1234
[-serialise]
		generate strawman RDF output

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($GenidNumberFile, $verbose,$namespace,$storename,$strawman,$stuff,$style,$split,$output_dir,$dbms_host,$dbms_port,$serialise);
my $bagIDs=0;
while (defined($ARGV[0]) and $ARGV[0] =~ /^[-+]/) {
    my $opt = shift;

    if ($opt eq '-stuff') {
        $stuff = shift;
    } elsif ($opt eq '-namespace') {
        $namespace = shift;
    } elsif ($opt eq '-GenidNumberFile') {
        $GenidNumberFile = shift;
    } elsif ($opt eq '-serialise') {
        $serialise = 1;
    } elsif ($opt eq '-strawman') {
        $strawman = 1;
    } elsif ($opt eq '-storename') {
        $storename = shift;
	$storename .= '/'
		unless(	(not(defined $storename)) || 
			($storename eq '') || 
			($storename =~ /\s+/) || 
			($storename =~ /\/$/) );
    } elsif ($opt eq '-style') {
	$style=shift;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-bagIDs') {
        $bagIDs = 1;
    } elsif ($opt eq '-split') {
	$opt=shift;
        $split = (int($opt)) ? $opt : 0;
    } elsif ($opt eq '-output_dir') {
	$opt=shift;
        $output_dir = $opt
		if(-e $opt);
	$output_dir .= '/'
		unless(	(not(defined $output_dir)) || 
			($output_dir eq '') || 
			($output_dir =~ /\s+/) || 
			($output_dir =~ /\/$/) );
    } elsif ($opt eq '-dbms_host') {
        $dbms_host = shift;
    } elsif ($opt eq '-dbms_port') {
	$opt=shift;
        $dbms_port = (int($opt)) ? $opt : undef;
    } else {
        die "Unknown option: $opt\n$Usage";
    };
};

my $cnt;
if(	(defined $GenidNumberFile) &&
	(-e $GenidNumberFile) ) {
	# lock the genid counter
	open(FH,'+<'.$GenidNumberFile)
        	or die "Failed to get genid counter $!";
	# go non buffered.
	select(FH);
	$|=1;
	select(STDOUT);
	flock FH,2
        	or die "Failed to get exclusive lock $!";
	seek FH,0,0
        	or die "Failed to seek $!";
	while(<FH>) {
        	chomp;
        	$cnt = int $_;
        };
	die "No genid counter"
        	unless defined $cnt;
};

my $pt;
if($strawman) {
	$pt = 'OpenHealth';
} else {
	$pt = 'SiRPAC';
};
$pt = 'RDFStore::Parser::'.$pt;

my $p=new ${pt}(
				ErrorContext => 	3, 
				Style => 		'RDFStore::Parser::Styles::MagicTie',
				NodeFactory => 		new RDFStore::NodeFactory(),
				Source	=> 		(defined $namespace) ?
								$namespace :
								($stuff =~ /^-/) ? undef : $stuff,
				bCreateBags =>		(defined $bagIDs) ? $bagIDs : undef,
				GenidNumber => $cnt,
				store	=>	{
							seevalues => 	$verbose,
							options		=> 	{
										Name	=> 	$output_dir.$storename,
										Style	=>	$style,
										Host =>	$dbms_host,
										Port =>	$dbms_port,
										Split	=>	$split,
										Sync    => 1 }
						}
				);

my $m;
if($stuff =~ /^-/) {
	# for STDIN use no-blocking
	my $nbp = $p->parse_start($namespace);
	while(<STDIN>) {
		$nbp->parse_more($_);
	};
	$m = $nbp->parse_done();
} else {
	$m = $p->parsefile($stuff);
};
if(	(defined $GenidNumberFile) &&
	(-e $GenidNumberFile) ) {
	$cnt = $p->getReificationCounter();
	seek FH,0,0
        	or die "Failed to seek $!";
	print FH $cnt."\n";
 
	select(FH);
	$|=1;
	flock FH,8
        	or die "Failed to unlock genid counter $!";
	close(FH);
	die "Issue with lock file $!"
        	if ($?);
};

if($serialise) {
	print $m->toStrawmanRDF(),"\n";
};
