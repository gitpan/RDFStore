print "1..2\n";

use DBMS;

while(1) {
tie %a,DBMS,'biggie' and print "ok\n" or die "could not connect $!";

%a=();
$last_a=$last='';
for $i ( 1 .. 100 ) {
	$a=  '.' x ( $i * 1024 );

	$a{ $i } = $a
		or die "Storing failed: $!";

	die "Retrieval failed"
		if defined($a{ $last}) && ($a{ $last } ne $last_a) ;

	$last_a = $a;
	$last  = $i;
	}
%a=();
untie %a;
print "ok\n";
}

