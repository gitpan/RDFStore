#!/usr/local/bin/perl
use Digest;

my $d1=new Digest("SHA1");
my $d2=new Digest("SHA1");
$d1->add(shift);
$d2->add(shift);

print $d1->hexdigest,"\n",
	$d2->hexdigest,"\n",
	$d1->hexdigest&$d2->hexdigest,"\n";

print $d1->hexdigest<<0x10,"\n";

