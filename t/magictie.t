# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..24\n";}
END {print "not ok 1\n" unless $loaded;}
use Data::MagicTie;
use BerkeleyDB;
use Fcntl;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Test 2

my $db1 = tie %a,"Data::MagicTie",'test1';
if ($db1)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
    exit;
}

my $db2 = tie @a,"Data::MagicTie",'test2';

if ($db2)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
    exit;
}

my $db3 = tie %b,"Data::MagicTie",'test3',( Q => -1, lr => 12, mode => 22341, style => 'blaaaaa');
if ($db2)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
    exit;
}

my $db4 = tie @b,"Data::MagicTie",'test4',( Q => -1, lr => 12, mode => 22341, style => 'blaaaaa');
if ($db3)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
    exit;
}

#remote should fail unless dbmsd is running on 'localhost'
my $db5;
eval {
	$db5 = tie %c,"Data::MagicTie",'test5',( lr => 1 );
};
if($@) {
    print "not ok 6 $@\n";
    exit;
}

#big one
my $db6 = tie %d,"Data::MagicTie",'test6',( Q => 64, style => 'BerkeleyDB' );
if ($db6)
{
    print "ok 7\n";
}
else
{
    print "not ok 7\n";
    exit;
}

#store - test 8..11
for (1..100) {
	unless($a{"a-".$_}=$_) {
		print "not ok 8\n";
		exit;
	};
	unless($b{"b-".$_}=$_) {
		print "not ok 9\n";
		exit;
	};
	unless($c{"c-".$_}=$_) {
		print "not ok 10\n";
		exit;
	};
	unless($d{"d-".$_}=$_) {
		print "not ok 11\n";
		exit;
	};
};

print "ok 8\n";
print "ok 9\n";
print "ok 10\n";
print "ok 11\n";

#fetch - test 12..14
for (1..100) {
	my $aa;
	unless($aa=$a{"a-".$_}) {
		print "not ok 12\n";
		exit;
	};
	unless($aa=$b{"b-".$_}) {
		print "not ok 13\n";
		exit;
	};
	unless($aa=$c{"c-".$_}) {
		print "not ok 14\n";
		exit;
	};
	unless($aa=$d{"d-".$_}) {
		print "not ok 15\n";
		exit;
	};
};

print "ok 12\n";
print "ok 13\n";
print "ok 14\n";
print "ok 15\n";

#store - test 16..19
for (1..100) {
	unless($a{"a1-".$_}={ $_ => [ 1,2,3,4, {} ] }) {
		print "not ok 16\n";
		exit;
	};
	unless($b{"b1-".$_}={ $_ => [ 1,2,3,4, {} ] }) {
		print "not ok 17\n";
		exit;
	};
	unless($c{"c1-".$_}={ $_ => [ 1,2,3,4, {} ] }) {
		print "not ok 18\n";
		exit;
	};
	unless($d{"d1-".$_}={ $_ => [ 1,2,3,4, {} ] }) {
		print "not ok 19\n";
		exit;
	};
};

print "ok 16\n";
print "ok 17\n";
print "ok 18\n";
print "ok 19\n";

#fetch - test 20..24
for (1..100) {
	my $aa;
	unless($aa=$a{"a1-".$_}) {
		print "not ok 20\n";
		exit;
	};
	unless($aa=$b{"b1-".$_}) {
		print "not ok 21\n";
		exit;
	};
	unless($aa=$c{"c1-".$_}) {
		print "not ok 22\n";
		exit;
	};
	unless($aa=$d{"d1-".$_}) {
		print "not ok 23\n";
		exit;
	};
};

print "ok 20\n";
print "ok 21\n";
print "ok 22\n";
print "ok 23\n";

#delegation stuff
$db1->set_parent($db3);
$db3->set_parent($db6);

#$val should be '12'
my $val = $a{"d-12"};
if($val eq '12')
{
    print "ok 24\n";
}
else
{
    print "not ok 24\n";
    exit;
}


undef $db1;
untie %a;
undef $db2;
untie @a;
undef $db3;
untie %b;
undef $db4;
untie @b;
undef $db5;
untie %c;
undef $db6;
untie %d;

unlink <test*.db>;
