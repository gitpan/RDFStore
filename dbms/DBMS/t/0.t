print "1..4\n";
use DBMS;
use Fcntl;

tie %a ,DBMS,'aah',O_CREAT|O_RDRW and print "ok\n" or die "could not connect $!";
print (($a{ "key_in_a" } =  "val_in_a") ? "ok\n" : "not ok\n");
print (($a{ "key_in_a" } eq "val_in_a") ? "ok\n" : "not ok\n");
untie %a;
print "ok\n";
