use strict ;
 
BEGIN { print "1..79\n"; };
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
ok 4, my $db3 = tie %b,"Data::MagicTie",( Name => '____33**', Split => -1, Mode => 22341, Style => 'blaaaaa');
ok 5, my $db4 = tie @b,"Data::MagicTie",( Split => -1, Mode => 22341, Style => 'blaaaaa');

#remote should fail unless dbmsd is running on 'localhost'
ok 6, my $db5 = tie %c,"Data::MagicTie",( Name => 'test3', Style => 'DBMS' );

#big one
ok 7, my $db6 = tie %d,"Data::MagicTie",( Name => 'test4', Split => 7, Style => 'BerkeleyDB' );
ok 8, my $db7 = tie @d,"Data::MagicTie",( Name => 'test5', Split => 7, Style => 'BerkeleyDB' );

ok 9, my $db8 = tie %e,"Data::MagicTie",( Name => 'test6', Style => 'DB_File' );
ok 10, my $db9 = tie @e,"Data::MagicTie",( Name => 'test7', Style => 'DB_File' );

#store
eval {
	for (1..100) {
		die unless $a[$_]=$_;
		die unless $b[$_]=$_;
		die unless $d[$_]=$_;
		die unless $e[$_]=$_;

		die unless $a{"a-".$_}=$_;
		die unless $b{"b-".$_}=$_;
		die unless $c{"c-".$_}=$_;
		die unless $d{"d-".$_}=$_;
		die unless $e{"e-".$_}=$_;
	};
};
ok 11, !$@;

#fetch
eval {
	for (1..100) {
		die unless my $aa=$a[$_];
		die unless my $bb=$b[$_];
		die unless my $dd=$d[$_];
		die unless my $ee=$e[$_];

		die unless $aa=$a{"a-".$_};
		die unless $bb=$b{"b-".$_};
		die unless my $cc=$c{"c-".$_};
		die unless $dd=$d{"d-".$_};
		die unless $ee=$e{"e-".$_};
	};
};
ok 12, !$@;

#store again
eval {
	for (1..100) {
		die unless $a[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $b[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $d[$_]={ $_ => [ 1,2,3,4, {} ] };
		die unless $e[$_]={ $_ => [ 1,2,3,4, {} ] };

		die unless $a{"a1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $b{"b1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $c{"c1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $d{"d1-".$_}={ $_ => [ 1,2,3,4, {} ] };
		die unless $e{"e1-".$_}={ $_ => [ 1,2,3,4, {} ] };
	};
};
ok 13, !$@;

#fetch again
eval {
	for (1..100) {
		die unless my $aa=$a[$_];
		die unless my $bb=$b[$_];
		die unless my $dd=$d[$_];
		die unless my $ee=$e[$_];

		die unless $aa=$a{"a1-".$_};
		die unless $bb=$b{"b1-".$_};
		die unless my $cc=$c{"c1-".$_};
		die unless $dd=$d{"d1-".$_};
		die unless $ee=$e{"e1-".$_};
	};
};
ok 14, !$@;

ok 15, my $ca = scalar(keys %a);
ok 16, my $cb = scalar(keys %b);
ok 17, my $cd = scalar(keys %d);
ok 18, my $ce = scalar(keys %e);

#delegation stuff
ok 19, $db1->set_parent($db3);
ok 20, $db3->set_parent($db6);
ok 21, $db6->set_parent($db8);

#$val should be '12'
my $val = $a{"d-12"};
ok 22, $val eq '12';

my $cdel = scalar(keys %a);
ok 23, ($ca+$cb+$cd+$ce)==$cdel;

ok 24, $db6->reset_parent();
ok 25, $db3->reset_parent();
ok 26, $db1->reset_parent();

#inc() method
eval {
	$a{count}=0;
	$b{count}=0;
	#$c{count}=0; # does not work :(
	$d{count}=0;
	$e{count}=0;
	for(1..100) { 
		die unless $db1->inc('count'); 
		die unless $db3->inc('count'); 
		#die if $db5->inc('count'); 
		die unless $db6->inc('count'); 
		die unless $db8->inc('count'); 
	};
};
ok 27, !$@;

ok 28, ( ($a{count}==100) &&
	#($c{count}==100) &&
	($d{count}==100) &&
	($e{count}==100) );

# clear
# NOTE: the one on the DBMS server side can not obviously removed
eval {
	%c=()
		if defined $db5 and tied(%c);
};
ok 29, !$@;

eval {
	undef $db1;
	die unless untie %a;
	undef $db2;
	die unless untie @a;
	undef $db3;
	die unless untie %b;
	undef $db4;
	die unless untie @b;
	undef $db5;
	die unless untie %c;
	undef $db6;
	die unless untie %d;
	undef $db7;
	die unless untie @d;
	undef $db8;
	die unless untie %e;
	undef $db9;
	die unless untie @e;
};
ok 30, !$@;

# Duplicates
ok 31, $db1 = tie %a,"Data::MagicTie",( Duplicates => 1 );
ok 32, $db2 = tie @a,"Data::MagicTie",( Duplicates => 1 );
#remote should fail unless dbmsd is running on 'localhost'
ok 33, $db5 = tie %c,"Data::MagicTie",( Name => 'test8', Style => 'DBMS', Duplicates => 1 );
%c=()
	if defined $db5 and tied(%c);
ok 34, $db6 = tie %d,"Data::MagicTie",( Name => 'test9', Split => 7, Style => 'BerkeleyDB', Duplicates => 1 );
ok 35, $db7 = tie @d,"Data::MagicTie",( Name => 'test10', Split => 7, Style => 'BerkeleyDB', Duplicates => 1 );
ok 36, $db8 = tie %e,"Data::MagicTie",( Name => 'test11', Style => 'DB_File', Duplicates => 1 );
ok 37, $db9 = tie @e,"Data::MagicTie",( Name => 'test12', Style => 'DB_File', Duplicates => 1 );
my %f;
ok 38, my $db10 = tie %f,"Data::MagicTie",( Name => 'test13', Style => 'SDBM_File', Duplicates => 1 );

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
		die unless $c{"c-".$_}=$_;
		die unless $c{"c-".$_}='DUP'.$_;
		die unless $c{"c-".$_}='DUP1'.$_;
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
ok 39, !$@;

ok 40, (scalar(keys %a)==300);
ok 41, (scalar(keys %c)==300);
ok 42, (scalar(keys %d)==300);
ok 43, (scalar(keys %e)==300);
ok 44, (scalar(keys %f)==300);

#find_dup
ok 45, ($db1->find_dup("a-10",10)==0);
ok 46, ($db2->find_dup(13,13)==0);
ok 47, (defined $db5 and tied(%c)) ? ($db5->find_dup("c-22",22)==0) : undef ;
ok 48, ($db6->find_dup("d-37",37)==0);
ok 49, ($db7->find_dup(77,77)==0);
ok 50, ($db8->find_dup("e-34",'DUP34')==0);
ok 51, ($db9->find_dup(76,'DUP76')==0);
ok 52, ($db10->find_dup("f-73",'DUP73')==0);

#get_dup
ok 53, ($db1->get_dup("a-10")==3);
ok 54, ($db2->get_dup(13)==3);
ok 55, (defined $db5 and tied(%c)) ? ($db5->get_dup("c-22")==3) : undef;
ok 56, ($db6->get_dup("d-37")==3);
ok 57, ($db7->get_dup(77)==3);
ok 58, ($db8->get_dup("e-34")==3);
ok 59, ($db9->get_dup(76)==3);
ok 60, ($db10->get_dup('f-34')==3);

eval {
	my @v = $db1->get_dup("a-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 61, !$@;

eval {
	my @v = $db2->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 62, !$@;

eval {
	my @v;
	@v = $db5->get_dup("c-10")
		if(defined $db5 and tied(%c));
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 63, !$@;

eval {
	my @v = $db6->get_dup("d-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 64, !$@;

eval {
	my @v = $db7->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 65, !$@;

eval {
	my @v = $db8->get_dup("e-10");
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 66, !$@;

eval {
	my @v = $db9->get_dup(10);
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 67, !$@;

eval {
	my @v = $db10->get_dup('f-10');
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 68, !$@;

#zap/delete
$db1->del_dup('a-10','10');
ok 69, (scalar(keys %a)==299);
$db5->del_dup('c-100','DUP1100')
	if(defined $db5 and tied(%c));
ok 70, (scalar(keys %c)==299);
$db6->del_dup('d-100','DUP1100');
ok 71, (scalar(keys %d)==299);
$db8->del_dup('e-100','DUP1100');
ok 72, (scalar(keys %e)==299);
$db10->del_dup('f-100','DUP1100');
ok 73, (scalar(keys %f)==299);

eval {
	foreach(keys %a) {
		delete($a{$_});
		die if exists($a{$_});
	};
};
ok 74, !$@;

eval {
	foreach(keys %c) {
		delete $c{$_};
		die if(exists $c{$_});
	};
};
ok 75, !$@;

eval {
	foreach(keys %d) {
		delete $d{$_};
		die if(exists $d{$_});
	};
};
ok 76, !$@;

eval {
	foreach(keys %e) {
		delete $e{$_};
		die if(exists $e{$_});
	};
};
ok 77, !$@;

eval {
	foreach(keys %f) {
		delete $f{$_};
		die if(exists $f{$_});
	};
};
ok 78, !$@;

eval {
	undef $db1;
	untie %a;
	undef $db2;
	untie @a;
	# NOTE: the one on the DBMS server side can not obviously removed
	%c=()
		if defined $db5 and tied(%c);
	undef $db5;
	untie %c;
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
ok 79, !$@;

unlink <test*.db>;
unlink <*.pag>;
unlink <*.dir>;
