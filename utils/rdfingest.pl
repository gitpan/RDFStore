#!/usr/local/bin/perl -I ../lib
##############################################################################
# 	Copyright (c) 2000 All rights reserved
# 	Alberto Reggiori / <alberto.reggiori@jrc.it>
# 	ISIS/RIT, Joint Research Center Ispra (I)
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
# 3. All advertising materials mentioning features or use of this
#    software must display the following acknowledgment:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors.
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
# This software consists of work developed by the ISIS/RIT group on behalf
# of the Joint Research Center of the European Commission and was originally
# based on public domain software written at the Stanford University Database
# Group by Sergey Melnik.
# For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
#
##############################################################################

use Carp;
use Fcntl;
use BerkeleyDB;
use RDFStore;
use Data::MagicTie;

my $Usage =<<EOU;
Usage is:
    $0 [-h] -stuff <URL_or_filename> [-output_dir <valid_directoryname>] -storename <IDENTIFIER> [-style <BerkeleyDB|DB_File>] [-split <number>] [-remote] [-dbms_host <hostname>] [-dbms_port <port>] [-serialise] [-v]

Query an existing RDFStore database.

-h	Print this message
-v	Be verbose

-stuff  <URL_or_filename>
                URL or filename. '-' denotes STDIN 

[-output_dir <valid_directoryname>]
		Output directory for DB files generated. Default is cwd.

-storename <IDENTIFIER>
		A label or identifier to identify the RDFStore database

[-style <BerkeleyDB|DB_File>]
		BerkeleyDB or DB_File store. Default is DB_File.

[-split <number>]
		Number of DB files to split around - see Data::MagicTie(3)
[-remote]
		Use a remote DBMS server. Default is local. If remote it reads -dbms_host 
		-dbms_port params
[-dbms_host <hostname>]
		Name or IP number of the DBMS host. Default is 'localhsot' see man dbmsd(8)

[-dbms_port <port>]
		TCP/IP port number of the DBMS host. Default is 1234

[-serialise]
                generate strawman RDF output

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my $factory = new RDFStore::NodeFactory();

my ($verbose,$serialise,$stuff,$storename,$style,$split,$output_dir,$remote,$dbms_host,$dbms_port);
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
	$opt=shift;
        $style = ($opt eq 'BerkeleyDB') ? $opt : undef;
    } elsif ($opt eq '-stuff') {
        $stuff = shift;
    } elsif ($opt eq '-serialise') {
        $serialise = 1;
    } elsif ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
	$verbose=1;
    } elsif ($opt eq '-split') {
	$opt=shift;
        $split = (int($opt)) ? $opt : 0;
    } elsif ($opt eq '-output_dir') {
	$opt=shift;
	$output_dir = $opt
                if(-e $opt);
        $output_dir .= '/'
                unless( (not(defined $output_dir)) ||
                        ($output_dir eq '') ||
                        ($output_dir =~ /\s+/) ||
                        ($output_dir =~ /\/$/) );
    } elsif ($opt eq '-remote') {
        $remote = 1;
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
# that name DBs 'rdf/triples' and 'rdf/index'
my $triples={};
tie %{$triples}, 'Data::MagicTie', $output_dir.$storename.'rdf/triples',(
					style   =>      $style,
					dbms_host =>    $dbms_host,
                                        dbms_port =>    $dbms_port,
                                        Q       =>      $split,
                                        lr      =>      $remote ) or
	croak "Cannot tie input 'triplets' DB $!";

my $triples_index = {};
tie %{$triples_index}, 'Data::MagicTie', $output_dir.$storename.'rdf/index',(
					style   =>      $style,
					dbms_host =>    $dbms_host,
                                        dbms_port =>    $dbms_port,
                                        Q       =>      $split,
                                        lr      =>      $remote ) or
	croak "Cannot tie input 'triples INDEX' DB $!";

my $index = new RDFStore::FindIndex($triples_index);
my $model = new RDFStore::SetModel(undef,$triples,$index,undef);
my $factory = new RDFStore::NodeFactory();

if($stuff eq '-') {
	*STUFF=*STDIN;
} else {
	open(STUFF,$stuff);
};

my $stats=0;
# input must look like (S,P,O) or (S,P,"O")
while(<STUFF>) {
	if(m/\(([^,]*),([^,]+),(.*)\)$/) {
		my $s = trim($1);
		my $p = trim($2);
		my $o = trim($3);
		$s =~ s/^stdin#//g;
		$s = $factory->createResource($s);
		$p = $factory->createResource($p);
		if($o =~ m/\s*"([^"]+)"\s*/) {
			$o = $factory->createLiteral($1);
		} else {
			$o = $factory->createResource($o);
		};
		my $stat = $factory->createStatement($s,$p,$o);
		print STDERR $stat->toString,"\n"
			if($verbose);
		$model->add($stat);
		$stats++;
	};
};
print STDERR "Ingested '$stats' RDF statements in '$output_dir$storename' using '$sytle' style and split factor '$split'\n"
	if($verbose);
unless($stuff eq '-') {
	close(STUFF);
};

if($serialise) {
        print $model->toStrawmanRDF(),"\n";
};

untie %{$triples};
untie %{$triples_index};

sub trim {
	my $t = shift;
	$t =~ s/^\s+//g;
	$t =~ s/\s+$//g;
	return $t;
};
