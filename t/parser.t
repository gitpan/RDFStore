# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..13\n";}
END {print "not ok 1\n" unless $loaded;}
use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::OpenHealth;
use RDFStore::Parser::Styles::MagicTie;
use RDFStore::NodeFactory;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Test 2


my $parser = new RDFStore::Parser::SiRPAC(ProtocolEncoding => 'ISO-8859-1',NodeFactory => new RDFStore::NodeFactory());
if ($parser)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
    exit;
}

my $parser1 = new RDFStore::Parser::OpenHealth(ProtocolEncoding => 'ISO-8859-1',NodeFactory => new RDFStore::NodeFactory());
if ($parser1)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
    exit;
}

my $parser2 = new RDFStore::Parser::SiRPAC(Style => 'RDFStore::Parser::Styles::MagicTie', NodeFactory => new RDFStore::NodeFactory());
if ($parser2)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
    exit;
}

my $parser3 = new RDFStore::Parser::OpenHealth(Style => 'RDFStore::Parser::Styles::MagicTie',NodeFactory => new RDFStore::NodeFactory());
if ($parser3)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
    exit;
}

my $rdfstring =<<"End_of_RDF;";
<?xml version='1.0' encoding='ISO-8859-1'?>
<!DOCTYPE rdf:RDF [
         <!ENTITY rdf 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
         <!ENTITY a 'http://description.org/schema/'>
]>
<rdf:RDF xmlns:rdf="&rdf;" xmlns:a="&a;">
<rdf:Description rdf:about="http://www.w3.org">
        <a:Date>1998-10-03T02:27</a:Date>
        <a:Publisher>World Wide Web Consortium</a:Publisher>
        <a:Title>W3C Home Page</a:Title>
        <a:memyI xml:space="preserve"> </a:memyI>
        <a:albe rdf:parseType="Literal"><this xmlns:is="http://iscool.org" xmlns="http://anduot.edu" is:me="a test">
Hei!!<me you="US"><you><a><b/></a></you>aaaa</me>

ciao!!!
<test2/>

---lsls;s</this></a:albe>
        <a:ee>EEEEE</a:ee>
        <a:bb rdf:parseType="Literal"><a:raffa>Ella</a:raffa></a:bb>
</rdf:Description>
</rdf:RDF>
End_of_RDF;

my $rdfstrawmanstring =<<"End_of_RDF;";
<?xml version='1.0' encoding='ISO-8859-1'?>
<rdf:RDF xmlns:saxon="http://icl.com/saxon" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:rdfx="http://www.openhealth.org/RDF/extract#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<rdf:Statement>
<rdf:predicate rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#type"/>
<rdf:subject rdf:resource="#/1"/>
<rdf:object rdf:resource="http://testme.org#test"/>
</rdf:Statement>
<rdf:Statement>
<rdf:predicate rdf:resource="http://testme.org#/1[\@my]"/>
<rdf:subject rdf:resource="#/1"/>
<rdf:object>first test is nice!</rdf:object>
</rdf:Statement>
<rdf:Statement>
<rdf:predicate rdf:resource="http://testme.org#this"/>
<rdf:subject rdf:resource="#/1"/>
<rdf:object rdf:resource="#/1/1"/>
</rdf:Statement>
</rdf:RDF>
End_of_RDF;

eval {
    $parser->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; },
                        	Start_XML_Literal  => sub { $_[0]->recognized_string; },
                        	Stop_XML_Literal  => sub { $_[0]->recognized_string; },
                        	Char_Literal  => sub { $_[0]->recognized_string; }
			);
};

if ($@)
{
    print "not ok 6\n";
    exit;
}

print "ok 6\n";

eval {
    $parser->parsestring($rdfstring);
};

if ($@)
{
	print "Parse error:\n$@";
}
else
{
	print "ok 7\n";
}

#strawman
eval {
    $parser1->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; }
			);
};

if ($@)
{
    print "not ok 8\n";
    exit;
}

print "ok 8\n";

eval {
    $parser1->parsestring($rdfstrawmanstring);
};

if ($@)
{
	print "Parse error:\n$@";
}
else
{
	print "ok 9\n";
}

eval {
    $parser2->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; },
                        	Start_XML_Literal  => sub { $_[0]->recognized_string; },
                        	Stop_XML_Literal  => sub { $_[0]->recognized_string; },
                        	Char_Literal  => sub { $_[0]->recognized_string; }
			);
};

if ($@)
{
    print "not ok 10\n";
    exit;
}

print "ok 10\n";

eval {
    $parser2->parsestring($rdfstring);
};

if ($@)
{
	print "Parse error:\n$@";
}
else
{
	print "ok 11\n";
}

eval {
    $parser3->setHandlers(
				Init    => sub { "INIT"; },
                        	Final   => sub { "FINAL"; },
                        	Assert  => sub { "STATEMENT"; }
			);
};

if ($@)
{
    print "not ok 12\n";
    exit;
}

print "ok 12\n";

eval {
    $parser3->parsestring($rdfstrawmanstring);
};

if ($@)
{
	print "Parse error:\n$@";
}
else
{
	print "ok 13\n";
}
