$childs=5;
use Fcntl;
print "1..".(1+$childs*6)."\n";

use DBMS;
for $cc ( 1..$childs ) {
	if (fork()==0) {
$|=1;
tie %a ,DBMS,'aah'.$cc.$$,O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
untie %b;
untie %a;

tie %c ,DBMS,'cee',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
$c{ key_in_c } = val_in_c;
untie %c;

tie %a ,DBMS,'aah',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
tie %b ,DBMS,'bee'.$cc.$$,O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;
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
	};

print "ok\n";
