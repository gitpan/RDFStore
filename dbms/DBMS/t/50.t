print "1..2\n";

use DBMS;
$|=1;
tie %a ,DBMS,'aah' and print "ok\n" or die "could not connect $!";
$a{ key_in_a } = val_in_a;
untie %b;

print "ok\n";
