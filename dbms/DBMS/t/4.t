$|=1;
$N=shift || 500;
use DBMS;
use Fcntl;
no strict;

foreach $db (1 .. 5) {
$a=tie %aap, 'DBMS','zappazoink'.$db,O_CREAT | O_RDWR 
	or die "E= $DBMS::DBMS_ERROR $::DBMS_ERROR $! $@ $?";

for $i (1..$N) {
	$aap{ $i } = $i;# print "FAIL $::DBMS_ERROR";
	};

for $i (1..$N) {
	($c=$aap{ $i }) == $i || print "\nVal Fault\n";
	print "\nFAIL $::DBMS_ERROR $!\n" unless defined $c;
	};

untie %aap;
}
