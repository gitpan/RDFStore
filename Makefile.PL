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

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;

print "Checking for XML::Parser...........";
eval {
	require XML::Parser::Expat;
        $VERSION = '0.1';
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
XML::Parser.pm version 2 or higher is needed
EOT
} else {
    print " ok\n";
}

print "Checking for Digest...........";
eval {
	require Digest;
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The Digest module must be installed
EOT
} else {
    print " ok\n";
}

print "Checking for URI...........";
eval {
	require URI;
	#URI->VERSION(1.09);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The URI module must be installed
EOT
} else {
    print " ok\n";
}

print "Checking for Storable...........";
eval {
	require Storable;
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The Storable module must be installed to serialise in-memory structures on disk
EOT
} else {
    print " ok\n";
}

print "Checking for BerkeleyDB...........";
eval {
	require BerkeleyDB;
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The BerkeleyDB module must be installed - You can fetch at http://www.sleepycat.com
EOT
} else {
    print " ok\n";
}

use ExtUtils::MakeMaker;

WriteMakefile(
    	NAME      => 'RDFStore',
    	AUTHOR    => 'Alberto Reggiori <alberto.reggiori@jrc.it>',
    	ABSTRACT  => 'RDF Storage Perl library',
    	VERSION   => '0.2',
    	'clean'     => { FILES => "*.db" }
);
