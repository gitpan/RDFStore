#!/usr/local/bin/perl -I ../lib
use RDFStore;
use File::Path qw(rmtree);

unless($#ARGV>=2) {
	print STDERR "\nUsage: <subject> <predicate> (<object> | 'object')\n\n";
	exit;
};

my $factory= new RDFStore::NodeFactory();
my $statement = $factory->createStatement(
			$factory->createResource($ARGV[0]),
			$factory->createResource($ARGV[1]),
			($#ARGV>2) ? $factory->createLiteral($ARGV[2]) : $factory->createResource($ARGV[2])
					);
my $statement0 = $factory->createStatement(
			$factory->createResource($ARGV[0]),
			$factory->createResource($ARGV[0]),
			($#ARGV>2) ? $factory->createLiteral($ARGV[2]) : $factory->createResource($ARGV[2])
					);
my $statement1 = $factory->createStatement($factory->createResource("http://www.altavista.com"),$factory->createResource("http://pen.jrc.it/schema/1.0/#author"),$factory->createLiteral("Alberto Reggiori"));

my $statement2 = $factory->createStatement($factory->createUniqueResource(),$factory->createUniqueResource(),$factory->createLiteral(""));

my $model = new RDFStore::Model(Name => 'test', Style => "BerkeleyDB", Split => 3);

$model->add($statement);
$model->add($statement0);
$model->add($statement1);
$model->add($statement2);

my $found = $model->find($statement->subject,undef,$statement->object);
my($found_elements) = $found->elements;
for my $ii ( 0..$#{$found_elements} ) {
	my $st=$found_elements->[$ii];
	print $st->getLabel(),"\n";
};

my $model1 = $model->duplicate();
#print $model1->getDigest->equals($model1->getDigest),"\n";
#print $model1->getDigest->hashCode,"\n";

print "The following should give the same results due that is a duplicate model :-)\n";

$found = $model1->find($statement->subject,undef,$statement->object);
($found_elements) = $found->elements;
for my $ii ( 0..$#{$found_elements} ) {
	my $st=$found_elements->[$ii];
	print $st->getLabel(),"\n";
};
eval{
rmtree('test');
};
