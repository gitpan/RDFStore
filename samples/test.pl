#!/usr/local/bin/perl -I ../lib
use RDFStore;
use BerkeleyDB;
use Data::MagicTie;

my $factory= new RDFStore::NodeFactory();
my $statement = $factory->createStatement(
			$factory->createResource($ARGV[0]),
			$factory->createResource($ARGV[1]),
			($#ARGV>2) ? $factory->createLiteral($ARGV[2]) : $factory->createResource($ARGV[2])
					);
my $statement1 = $factory->createStatement($factory->createResource("http://www.altavista.com"),$factory->createResource("http://pen.jrc.it/schema/1.0/#author"),$factory->createLiteral("Alberto Reggiori"));

my $statement2 = $factory->createStatement($factory->createUniqueResource(),$factory->createUniqueResource(),$factory->createLiteral(""));

my $index_db={};
tie %{$index_db},"Data::MagicTie",'index/triples',0,DB_CREATE,0,20,"BerkeleyDB";
my $index=new RDFStore::FindIndex($index_db);
my $model = new RDFStore::Model($factory,undef,$index,undef);

$model->add($statement);
$model->add($statement1);
$model->add($statement2);
my $model1 = $model->duplicate();

#print $model1->getDigest->equals($model1->getDigest),"\n";
#print $model1->getDigest->hashCode,"\n";

my $found = $model->find($statement2->subject,undef,undef);

foreach (keys %{$found->elements}) {
	print $found->elements->{$_}->getLabel(),"\n";
};
