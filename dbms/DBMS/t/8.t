use Fcntl;

use DBMS;
fork(); fork(); fork(); 
fork(); fork(); fork();  # 128
$|=1;

tie %a ,DBMS,'aah'.$$,O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";
print "Done\n";
sleep(1);
