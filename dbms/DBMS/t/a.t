$|=1;
use DBMS;
use Fcntl;
no strict;

while(1) {
	$a=tie %aap, 'DBMS','zappazoink',O_CREAT | O_RDWR ,'server112'
		or die "E= $DBMS::DBMS_ERROR $::DBMS_ERROR $! $@ $?";

	for $i (0..5000) {
		$aap{ $i } = $i;# print "FAIL $::DBMS_ERROR";
		};
	print "-";
	for $i (0..5000) {
		($c=$aap{ $i }) == $i || print "\nVal Fault\n";
		print "\nFAIL $::DBMS_ERROR $!\n" unless defined $c;
		};
	print "+";
	untie %aap;
	# print "[$$]";
	};
