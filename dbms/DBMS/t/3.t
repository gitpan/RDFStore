$|=1;
$N=shift || 1500;
use DBMS;
use Fcntl;
no strict;

$a=tie %aap, 'DBMS','zappazoink',O_CREAT | O_RDWR 
	or die "E= $DBMS::DBMS_ERROR $::DBMS_ERROR $! $@ $?";

foreach $ci (1 .. 100) {

	for $i (1 .. $N) {
		$aap{ $i } = $i;# print "FAIL $::DBMS_ERROR";
		};

	for $i (1 .. $N) {
		($c=$aap{ $i }) == $i || print "\nVal Fault\n";
		print "\nFAIL $::DBMS_ERROR $!\n" unless defined $c;
		};
print".";
	};

untie %aap;
