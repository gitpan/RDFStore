use strict ;
 
BEGIN { print "1..87\n"; };
END {print "not ok 1\n" unless $::loaded;};
 
sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}
 
sub docat
{
    my $file = shift;
    local $/ = undef;
    open(CAT,$file) || die "Cannot open $file:$!";
    my $result = <CAT>;
    close(CAT);
    return $result;
};
 
umask(0);
 
use RDFStore;
use File::Path qw(rmtree);
 
$::loaded = 1;
print "ok 1\n";

ok 2, my $factory= new RDFStore::NodeFactory();

#node
ok 3, my $node = new RDFStore::RDFNode();

#literals
ok 4, my $literal = new RDFStore::Literal('test');
ok 5, my $literal1 = new RDFStore::Literal('test1');
ok 6, ($literal->getContent eq 'test');
ok 7, ($literal1->getContent eq 'test1');
ok 8, ($literal->getLabel eq 'test');
ok 9, ($literal1->getLabel eq 'test1');
ok 10, ($literal->getURI eq 'test');
ok 11, ($literal1->getURI eq 'test1');
ok 12, ($literal->toString eq 'test');
ok 13, ($literal1->toString eq 'test1');
ok 14, (int($literal->hashCode));
ok 15, (int($literal1->hashCode));
ok 16, ($literal->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 17, ($literal1->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 18, ($literal->equals($literal1)) ? 0 : 1;
ok 19, my $blob = new RDFStore::Literal({ a => [1,2,3, { 5 => 6} ], b => 'abcdef' });
ok 20, my $blob1 = new RDFStore::Literal({ a => [1,2,3, { 5 => 6} ], b => 'abcdef' });
ok 21, (ref($blob->getContent) =~ /HASH/);
ok 22, (ref($blob1->getContent) =~ /HASH/);
ok 23, ($blob->getLabel eq $blob1->getLabel);
ok 24, ($blob->getURI eq $blob1->getURI);
ok 25, ($blob->toString eq $blob1->toString);
ok 26, (int($blob->hashCode) == int($blob1->hashCode));
ok 27, ($blob->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 28, ($blob1->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 29, ($blob->getDigest->equals($blob1->getDigest));
ok 30, (int($blob->getDigest->hashCode) == int($blob1->getDigest->hashCode));
ok 31, ($blob->getDigest->toString eq $blob1->getDigest->toString);
ok 32, ($blob->equals($blob1)) ? 1 : 0;

ok 33, my $statement = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Creator'),
			$factory->createLiteral('Ora Lassila') );
ok 34, my $subject = $statement->subject;
ok 35, ($subject->getLabel eq 'http://www.w3.org/Home/Lassila');
ok 36, ($subject->getURI eq 'http://www.w3.org/Home/Lassila');
ok 37, ($subject->toString eq 'http://www.w3.org/Home/Lassila');
ok 38, (int($subject->hashCode));
ok 39, ($subject->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 40, ($subject->getNamespace eq 'http://www.w3.org/Home/');
ok 41, ($subject->getLocalName eq 'Lassila');
ok 42, my $predicate = $statement->predicate;
ok 43, ($predicate->getLabel eq 'http://description.org/schema/Creator');
ok 44, ($predicate->getURI eq 'http://description.org/schema/Creator');
ok 45, ($predicate->toString eq 'http://description.org/schema/Creator');
ok 46, (int($predicate->hashCode));
ok 47, ($predicate->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));
ok 48, ($predicate->getNamespace eq 'http://description.org/schema/');
ok 49, ($predicate->getLocalName eq 'Creator');
ok 50, my $object = $statement->object;
ok 51, ($object->getContent eq 'Ora Lassila');
ok 52, ($object->getLabel eq 'Ora Lassila');
ok 53, ($object->getURI eq 'Ora Lassila');
ok 54, ($object->toString eq 'Ora Lassila');
ok 55, (int($object->hashCode));
ok 56, ($object->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));

ok 57, ($statement->node2string($subject) eq '"http://www.w3.org/Home/Lassila"');
ok 58, ($statement->node2string($predicate) eq '"http://description.org/schema/Creator"');
ok 59, ($statement->node2string($object) eq 'literal("Ora Lassila")');
ok 60, !(defined $statement->getNamespace);
ok 61, ($statement->getLocalName eq 'urn:rdf:SHA-1-ab1050efb0d21e4399cab326544549406798cd78');
ok 62, ($statement->getLabel eq 'urn:rdf:SHA-1-ab1050efb0d21e4399cab326544549406798cd78');
ok 63, ($statement->getURI eq 'urn:rdf:SHA-1-ab1050efb0d21e4399cab326544549406798cd78');
ok 64, (int($statement->hashCode));
ok 65, ($statement->getDigest->isa("RDFStore::Stanford::Digest::Abstract"));

ok 66, my $statement0 = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Author'),
			$factory->createLiteral({ 'Ora' => 'Lissala' })
					);
ok 67, my $statement1 = $factory->createStatement(
			$factory->createResource('http://www.w3.org/Home/Lassila'),
			$factory->createResource('http://description.org/schema/','Author'),
			$factory->createLiteral({ 'Alberto' => 'Reggiori' }) );

ok 68, my $statement2 = $factory->createStatement(
		$factory->createResource('http://www.altavista.com'),
		$factory->createResource('http://pen.jrc.it/schema/1.0/#','author'),
		$factory->createLiteral('me') );

ok 69, my $statement3 = $factory->createStatement(
		$factory->createResource('http://www.google.com'),
		$factory->createResource('http://pen.jrc.it/schema/1.0/#creator'),
		$factory->createLiteral('you') );

ok 70, my $statement4 = $factory->createStatement(
		$factory->createResource('google'),
		$factory->createResource('http://pen.jrc.it/schema/1.0/#creator'),
		$factory->createLiteral('you') );

ok 71, my $statement5 = $factory->createStatement(
		$factory->createUniqueResource(),
		$factory->createOrdinal(1),
		$factory->createLiteral('') );

ok 72, my $model = new RDFStore::Model(Name => 'test', Style => "BerkeleyDB", Split => 3, Sync => 1);
$model->setSourceURI('http://somewhere.org/');
ok 73, ($model->getSourceURI eq 'http://somewhere.org/');
ok 74, ($model->toString eq 'Model[http://somewhere.org/]');
ok 75, ($model->getDigest->isa("RDFStore::Stanford::Digest"));
ok 76, !(defined $model->getNamespace);
ok 77, my $algo=$model->getDigestAlgorithm;
$model->add($statement);
$model->add($statement0);
$model->add($statement1);
$model->add($statement2);
$model->add($statement3);
$model->add($statement4);
$model->add($statement5);
ok 78, !($model->isEmpty);
ok 79, ($model->size == 7);
ok 80, ($model->contains($statement1));
ok 81, ($model->isMutable);

ok 82, my $found = $model->find($statement->subject,undef,$statement->object);
eval {
	my @num = $found->elements;
	die unless($#num==0);
	die unless($num[0]->equals($statement));
};
ok 83, !$@;
eval {
	my $st;
	die unless($st=$found->elements);
};
ok 84, !$@;

ok 85, my $model1 = $model->duplicate();

ok 86, $found = $model1->find($statement->subject,undef,$statement->object);
eval {
	my @num = $found->elements;
	die unless($#num==0);
};
ok 87, !$@;

#ok 88, my $model2 = new RDFStore::Model( Parent => $model );
#ok 89, $found = $model2->find($statement->subject,undef,$statement->object);
#eval {
#	my @num = $found->elements;
#	die unless($#num==0);
#};
#ok 90, !$@;

rmtree('test');
