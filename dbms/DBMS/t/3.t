print "1..2\n";

use DBMS;

tie %a,DBMS,'biggie' and print "ok\n" or die "could not connect $!";

%a=();
$last=$last_a='';
for  $i( 1 .. 100 ) {
	$a=  "Hello World part $i" x ( $i * $i );

	$a{ $i } = $a
		or die "errow hile setting: $!";

	die "Nope not the same"
		if defined($a{$last}) && ($a{ $last } ne $last_a) ;

	$last_a = $a;
	$last  = $i;
	}

%a=();
untie %a;

print "ok\n";
