use strict ;
 
BEGIN { print "1..16\n"; };
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

ok 2, my $db5 = tie %c,"Data::MagicTie",( Name => 'test3', Style => 'DBMS' );

#store
eval {
	for (1..100) {
		die unless $c{"c-".$_}=$_;
	};
};
ok 3, !$@;

#fetch
eval {
	for (1..100) {
		die unless my $cc=$c{"c-".$_};
	};
};
ok 4, !$@;

#store again
eval {
	for (1..100) {
		die unless $c{"c1-".$_}={ $_ => [ 1,2,3,4, {} ] };
	};
};
ok 5, !$@;

#fetch again
eval {
	for (1..100) {
		die unless my $cc=$c{"c1-".$_};
	};
};
ok 6, !$@;

# does not work properly yet :(
#inc() method
#eval {
#	$c{count}=0; # does not work :(
#	for(1..100) { 
#		die if $db5->inc('count'); 
#	};
#};
#ok 7, !$@;

#ok 7, ($c{count}==100);

# clear
# NOTE: the one on the DBMS server side can not obviously removed
eval {
	%c=()
		if defined $db5 and tied(%c);
};
ok 7, !$@;

eval {
	undef $db5;
	die unless untie %c;
};
ok 8, !$@;

# Duplicates
ok 9, $db5 = tie %c,"Data::MagicTie",( Name => 'test8', Style => 'DBMS', Duplicates => 1 );
%c=()
	if defined $db5 and tied(%c);

#store
eval {
	for (1..100) {
		die unless $c{"c-".$_}=$_;
		die unless $c{"c-".$_}='DUP'.$_;
		die unless $c{"c-".$_}='DUP1'.$_;
	};
};
ok 10, !$@;

ok 11, (scalar(keys %c)==300);

#find_dup
ok 12, (defined $db5 and tied(%c)) ? ($db5->find_dup("c-22",22)==0) : undef ;

#get_dup
ok 13, (defined $db5 and tied(%c)) ? ($db5->get_dup("c-22")==3) : undef;

eval {
	my @v;
	@v = $db5->get_dup("c-10")
		if(defined $db5 and tied(%c));
	die unless(	($#v==2)	&&
			($v[0] eq '10')	&&
			($v[1] eq 'DUP10')	&&
			($v[2] eq 'DUP110')	);
};
ok 14, !$@;

#zap/delete
$db5->del_dup('c-100','DUP1100')
	if(defined $db5 and tied(%c));

eval {
	foreach(keys %c) {
		delete $c{$_};
		die if(exists $c{$_});
	};
};
ok 15, !$@;

eval {
	# NOTE: the one on the DBMS server side can not obviously removed
	%c=()
		if defined $db5 and tied(%c);
	undef $db5;
	untie %c;
};
ok 16, !$@;
