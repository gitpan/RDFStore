use strict ;
 
BEGIN { print "1..70\n"; };
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

use Data::MagicTie;
use File::Path qw(rmtree);

$::loaded = 1;
print "ok 1\n";

my %a;
my @a;
my %b;
my @b;
my %c;
my %d;
my @d;
my %e;
my @e;

ok 2, my $db1 = tie %a,"Data::MagicTie";
ok 3, my $db2 = tie @a,"Data::MagicTie";

# check for invalid parameters
ok 4, my $db3 = tie %b,"Data::MagicTie",( Name => 'test3', Split => -1, Mode => 22341, Style => 'blaaaaa');
ok 5, my $db4 = tie @b,"Data::MagicTie",( Split => -1, Mode => 22341, Style => 'blaaaaa');

#big one
ok 6, my $db6 = tie %d,"Data::MagicTie",( Name => 'test4', Split => 7, Style => 'BerkeleyDB' );
ok 7, my $db7 = tie @d,"Data::MagicTie",( Name => 'test5', Split => 7, Style => 'BerkeleyDB' );

ok 8, my $db8 = tie %e,"Data::MagicTie",( Name => 'test6', Style => 'DB_File' );
ok 9, my $db9 = tie @e,"Data::MagicTie",( Name => 'test7', Style => 'DB_File' );

#store
eval {
	for (1..100) {
		die unless $a[$_]=$_;
		die unless $b[$_]=$_;
		die unless $d[$_]=$_;
		die unless $e[$_]=$_;

		die unless $a{"a-".$_}=$_;
		die unless $b{"b-".$_}=$_;
		die unless $d{"d-".$_}=$_;
		die unless $e{"e-".$_}=$_;
	};
};
ok 10, !$@;

#fetch
eval {
	for (1..100) {
		die unless my $aa=$a[$_];
		die unless my $bb=$b[$_];
		die unless my $dd=$d[$_];
		die unless my $ee=$e[$_];

		die unless $aa=$a{"a-".$_};
		die unless $bb=$b{"b-".$_};
		die unless $dd=$d{"d-".$_};
		die unless $ee=$e{"e-".$_};
	};
};
ok 11, !$@;

#store again
eval {
	for (1..100) {
		die unless $a[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $b[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $d[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $e[$_]={ $_ => [ 1,2,3,4, {} ] };

		die unless $a{"a1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $b{"b1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $d{"d1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $e{"e1-".$_}={ $_ => [ 1,2,3,4, {} ] };
	};
};
ok 12, !$@;

#fetch again
eval {
	for (1..100) {
		die unless my $aa=$a[$_];
		die unless my $bb=$b[$_];
		die unless my $dd=$d[$_];
		die unless my $ee=$e[$_];

		die unless $aa=$a{"a1-".$_};
		die unless $bb=$b{"b1-".$_};
		die unless $dd=$d{"d1-".$_};
		die unless $ee=$e{"e1-".$_};
	};
};
ok 13, !$@;

ok 14, my $ca = scalar(keys %a);
ok 15, my $cb = scalar(keys %b);
ok 16, my $cd = scalar(keys %d);
ok 17, my $ce = scalar(keys %e);

#delegation stuff
ok 18, $db1->set_parent($db3);
ok 19, $db3->set_parent($db6);
ok 20, $db6->set_parent($db8);

#$val should be '12'
my $val = $a{"d-12"};
ok 21, $val eq '12';

my $cdel = scalar(keys %a);
ok 22, ($ca+$cb+$cd+$ce)==$cdel;

ok 23, $db6->reset_parent();
ok 24, $db3->reset_parent();
ok 25, $db1->reset_parent();

#inc() method
eval {
	$a{count}=0;
	$b{count}=0;
	$d{count}=0;
	$e{count}=0;
	for(1..100) { 
		die unless $db1->inc('count'); 
		die unless $db3->inc('count'); 
		die unless $db6->inc('count'); 
		die unless $db8->inc('count'); 
	};
};
ok 26, !$@;

ok 27, ( ($a{count}==100) &&
	 ($d{count}==100) &&
	 ($e{count}==100) );

# clear

eval {
	undef $db1;
	die unless untie %a;
	undef $db2;
	die unless untie @a;
	undef $db3;
	die unless untie %b;
	undef $db4;
	die unless untie @b;
	undef $db6;
	die unless untie %d;
	undef $db7;
	die unless untie @d;
	undef $db8;
	die unless untie %e;
	undef $db9;
	die unless untie @e;
};
ok 28, !$@;

# Duplicates
ok 29, $db1 = tie %a,"Data::MagicTie",( Duplicates => 1 );
ok 30, $db2 = tie @a,"Data::MagicTie",( Duplicates => 1 );
ok 31, $db6 = tie %d,"Data::MagicTie",( Name => 'test9', Split => 7, Style => 'BerkeleyDB', Duplicates => 1 );
ok 32, $db7 = tie @d,"Data::MagicTie",( Name => 'test10', Split => 7, Style => 'BerkeleyDB', Duplicates => 1 );
ok 33, $db8 = tie %e,"Data::MagicTie",( Name => 'test11', Style => 'DB_File', Duplicates => 1 );
ok 34, $db9 = tie @e,"Data::MagicTie",( Name => 'test12', Style => 'DB_File', Duplicates => 1 );
my %f;
ok 35, my $db10 = tie %f,"Data::MagicTie",( Name => 'test13', Style => 'SDBM_File', Duplicates => 1 );

#store
eval {
	for (1..100) {
		die unless $a[$_]=$_;
		die unless $a[$_]='DUP'.$_;
		die unless $a[$_]='DUP1'.$_;
		die unless $d[$_]=$_;
		die unless $d[$_]='DUP'.$_;
		die unless $d[$_]='DUP1'.$_;
		die unless $e[$_]=$_;
		die unless $e[$_]='DUP'.$_;
		die unless $e[$_]='DUP1'.$_;

		die unless $a{"a-".$_}=$_;
		die unless $a{"a-".$_}='DUP'.$_;
		die unless $a{"a-".$_}='DUP1'.$_;
		die unless $d{"d-".$_}=$_;
		die unless $d{"d-".$_}='DUP'.$_;
		die unless $d{"d-".$_}='DUP1'.$_;
		die unless $e{"e-".$_}=$_;
		die unless $e{"e-".$_}='DUP'.$_;
		die unless $e{"e-".$_}='DUP1'.$_;
		die unless $f{"f-".$_}=$_;
		die unless $f{"f-".$_}='DUP'.$_;
		die unless $f{"f-".$_}='DUP1'.$_;
	};
};
ok 36, !$@;

ok 37, (scalar(keys %a)==300);
ok 38, (scalar(keys %d)==300);
ok 39, (scalar(keys %e)==300);
ok 40, (scalar(keys %f)==300);

#find_dup
ok 41, ($db1->find_dup("a-10",10)==0);
ok 42, ($db2->find_dup(13,13)==0);
ok 43, ($db6->find_dup("d-37",37)==0);
ok 44, ($db7->find_dup(77,77)==0);
ok 45, ($db8->find_dup("e-34",'DUP34')==0);
ok 46, ($db9->find_dup(76,'DUP76')==0);
ok 47, ($db10->find_dup("f-73",'DUP73')==0);

#get_dup
ok 48, ($db1->get_dup("a-10")==3);
ok 49, ($db2->get_dup(13)==3);
ok 50, ($db6->get_dup("d-37")==3);
ok 51, ($db7->get_dup(77)==3);
ok 52, ($db8->get_dup("e-34")==3);
ok 53, ($db9->get_dup(76)==3);
ok 54, ($db10->get_dup('f-34')==3);

eval {
	my @v = $db1->get_dup("a-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 55, !$@;

eval {
	my @v = $db2->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 56, !$@;

eval {
	my @v = $db6->get_dup("d-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 57, !$@;

eval {
	my @v = $db7->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 58, !$@;

eval {
	my @v = $db8->get_dup("e-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 59, !$@;

eval {
	my @v = $db9->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 60, !$@;

eval {
	my @v = $db10->get_dup('f-10');
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 61, !$@;

#zap/delete
$db1->del_dup('a-10','10');
ok 62, (scalar(keys %a)==299);
$db6->del_dup('d-100','DUP1100');
ok 63, (scalar(keys %d)==299);
$db8->del_dup('e-100','DUP1100');
ok 64, (scalar(keys %e)==299);
$db10->del_dup('f-100','DUP1100');
ok 65, (scalar(keys %f)==299);

eval {
	foreach(keys %a) {
		delete($a{$_});
		die if exists($a{$_});
	};
};
ok 66, !$@;

eval {
	foreach(keys %d) {
		delete $d{$_};
		die if(exists $d{$_});
	};
};
ok 67, !$@;

eval {
	foreach(keys %e) {
		delete $e{$_};
		die if(exists $e{$_});
	};
};
ok 68, !$@;

eval {
	foreach(keys %f) {
		delete $f{$_};
		die if(exists $f{$_});
	};
};
ok 69, !$@;

eval {
	undef $db1;
	untie %a;
	undef $db2;
	untie @a;
	undef $db6;
	untie %d;
	undef $db7;
	untie @d;
	undef $db8;
	untie %e;
	undef $db9;
	untie @e;
	undef $db10;
	untie %f;
};
ok 70, !$@;

eval {
unlink <test*.db>;
unlink <*.pag>;
unlink <*.dir>;
};
