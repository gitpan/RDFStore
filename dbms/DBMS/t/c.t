$|=1;
$N=shift || 500;
use DBMS;
use Fcntl;
no strict;

$a=tie %aap, 'DBMS','zappazoink',O_CREAT | O_RDWR , 'server112'
		or die "E= $DBMS::DBMS_ERROR $::DBMS_ERROR $! $@ $?";

%aap=();

$aap{ counter } = 1;

while(1) {
	print $a->INC( 'counter' ) . "\n";
	};

