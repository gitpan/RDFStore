
use DBMS;
use Fcntl;

tie %a,DBMS,'biggie',O_CREAT|O_RDWR and print "ok\n" or die "could not connect $!";

%a=();
$last_a=$last='';
while($j<100) {
	print "Cycle\n";
	$j++;
for $k ( 1 .. 60 ) {
	$a=  '.' x ( $k * 1024 );
	$i=$k.$j;

	$a{ $i } = $a
		or die "Storing failed: $!";

	die "Retrieval failed"
		if defined($a{ $last}) && ($a{ $last } ne $last_a) ;

	$last_a = $a;
	$last  = $i;
	sleep(1) if $k % 3 == 0;
	};
	};

%a=();
untie %a;

print "ok\n";

