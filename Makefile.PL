# *
# *	Copyright (c) 2000 Alberto Reggiori <areggiori@webweaving.org>
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

# Check for non-standard modules that are used by this library.
$| = 1;
my %missing_modules=();

print "Checking for XML::Parser...........";
eval {
	require XML::Parser;
	require XML::Parser::Expat;
};
if ($@) {
    print " missing - XML::Parser module version 2 or higher is required\n";
    $missing_modules{'XML::Parser'}=1;
} else {
	print qq|ALERT!

You have installed a recent version of the XML::Parser (>2.29) with built in expat XML parser support. If you are going to use RDFStore inside the Apache Web server using mod_perl, bear in mind that there is a symbol conflict between XML::Parser and apache when built with expat. To properly use the RDFStore parsing modules you need to rebuilt apache disabling expat.

|
	if($XML::Parser::VERSION gt '2.29');

	print " ok\n";
}

print "Checking for Digest...........";
eval {
	require Digest;
};
if ($@) {
    print " missing - The Digest module is required\n";
    $missing_modules{'Digest'}=1;
} else {
    print " ok\n";
}

print "Checking for URI...........";
eval {
	require URI;
	#URI->VERSION(1.09);
};
if ($@) {
    print " missing - The URI module is required\n";
    $missing_modules{'URI'}=1;
} else {
    print " ok\n";
}

print "Checking for Storable...........";
eval {
	require Storable;
};
if ($@) {
    print " missing - The Storable module is required to serialise in-memory structures on disk\n";
    $missing_modules{'Storable'}=1;
} else {
    print " ok\n";
}

if(	(exists $missing_modules{'XML::Parser'}) ||
	(exists $missing_modules{'Storable'}) ||
	(exists $missing_modules{'Digest'}) ||
	(exists $missing_modules{'URI'}) ) {
	print "\nSorry, can not build RDFStore :(\nPlease installed the missing modules above and try again.\n\n";
	exit;
};

print "Checking for BerkeleyDB...........";
eval {
	require BerkeleyDB;
};
if ($@) {
    print " optional - It can be fetched at http://search.cpan.org/search?dist=BerkeleyDB. Look at http://www.sleepycat.com/docs/index.html for the installation\n";
    $missing_modules{'BerkeleyDB'}=1;
} else {
    print " ok\n";
}

print "Checking for DB_File...........";
eval {
	require DB_File;
};
if ($@) {
    print " optional\n";
    $missing_modules{'DB_File'}=1;
} else {
    print " ok\n";
};

print "Checking for SDBM_File...........";
eval {
	require SDBM_File;
};
if ($@) {
    print " optional\n";
    $missing_modules{'SDBM_File'}=1;
} else {
    print " ok\n";
};

if(	(exists $missing_modules{'BerkeleyDB'}) &&
	(exists $missing_modules{'DB_File'}) &&
	(exists $missing_modules{'SDBM_File'}) ) {
	print qq|

You do not have local database storage module installed. RDFStore will not able to store any kind of results on the local file system; the in-memory syle will be used instead. If you can get the DBMS module below installed you can leverage on a remote storage.
|;
};

print <<EOT;

In addition, you can install the (optional) DBMS module for TCP/IP remote storage by:

cd dbms;
make;
make install;

NOTE: the dbmsd(8) code uses old Berkeley DB 1.x style interface. If you can not get it compile, do not disperate and try to use perl land BerkleyDB, DB_File or SDBM_File styles instead :-)

EOT

use ExtUtils::MakeMaker;

WriteMakefile(
    	NAME      => 'RDFStore',
    	AUTHOR    => 'Alberto Reggiori <areggiori@webweaving.org>',
    	ABSTRACT  => 'RDF Storage Perl library',
    	VERSION   => '0.2',
    	'clean'     => { FILES => "*.db" }
);
