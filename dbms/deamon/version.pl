#!/usr/bin/perl
$rcsid='$Id: version.pl,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $';
#
$h=`hostname`;
chop $h;
$a=`id -p`;
$id='??';
$id=$1 if $a=~ m/uid\s+(\w+)/;
$id=$1 if $a=~ m/login\s+(\w+)/;

# $a=`pwd`;
# $a =~ m/dbms-(\d+)\.(\d+)/
# 	or die "no version in $a";
# $version =$1 * 100 +$2;

$rcsid =~ m/Id:\s+\S+\s+([\d\.]+)\s+/
	or die "No version in rcs version";

$version = $1;
$date=gmtime(time);

print qq|\
/*>version.c - $0 generated - $version
 * $rcsid
 */
#include <sys/types.h>

#if 0
static char rcsid[]="$rcsid";
#endif

static char version[]= "DBMS/$version - $date - $id\@$h - "
#ifdef FORKING
	"forking"
#else
	"NON forking"
#endif
	;

char * get_full( void ) {
	return version;
	}
|;


