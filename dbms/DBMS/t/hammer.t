$childs=6;
use Fcntl;
print "1..".(1+$childs*6)."\n";
$M=500;
$dt=time;
$ttt = ($M*4+6+2) * $childs;

use DBMS;
for $cc ( 1..$childs ) {
	if (fork()==0) {
$|=1;
tie %a ,DBMS,'aah'.$cc.$$,O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
for(1 .. $M){
$a{ key_in_a.$_ } = val_in_a.$_;
$b{ key_in_b } = val_in_b;
};
untie %b;
untie %a;

tie %c ,DBMS,'cee',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;

tie %a ,DBMS,'aah',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee'.$cc.$$,O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
for(1..$M){
$a{ key_in_a.$_ } = val_in_a;
$b{ key_in_b } = val_in_b;
};
untie %b;
untie %a;

tie %c ,DBMS,'cee',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;
exit;
};
};

while(1) {
	last if wait == -1;
   print "ok $_ \n";
	};

$dt = time - $dt;
print "N=".$ttt." ".($ttt/$dt)." ok\n";
