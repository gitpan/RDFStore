$|=1;

use DB_File;
use Fcntl;

tie %a,'DB_File','/tmp/dbms_tiepje_namie.db',O_RDONLY,0666 or die;

while( ($a,$b) = each %a ) {
	print "$a = $b\n";
	};

