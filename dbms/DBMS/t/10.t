print "1..4\n";

use DBMS;

tie %a ,DBMS,'aah' and print "ok\n" or die $!;
tie %b ,DBMS,'bee' and print "ok\n" or die $!;

$a{ key_in_a } = val_in_a;
$b{ key_in_b } = val_in_b;

untie %b and print "ok\n" or warn $!;
untie %a and print "ok\n" or warn $!;
 
