$|=1;
print "1..32\n";

use DBMS;
fork(); fork(); fork(); 
fork(); 
# fork(); # 64
# fork();  #128
$|=1;

tie %a ,DBMS,'aah',&DBMS::XSMODE_CREAT and print "ok\n" or print "not ok\n";
print "ok\n";
sleep(1);

untie %a;
