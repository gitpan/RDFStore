#!/usr/local/bin/perl
use DBMS;
use Fcntl;
$|=1;
$X = tie %een, 'DBMS','een' or die;
$Y = tie %twee, 'DBMS','twee',O_RDWR|O_CREAT or die $!;

while(1) {
   for $i ( 1..100) {
	$een{ time } = time;
	$twee{ time } = time;
	};
    sleep(1);
    foreach(keys(%een)) {
	delete($een{ $_ });
	};
    foreach(keys(%twee)) {
	delete($twee{ $_ });
	};
     };

		
	
