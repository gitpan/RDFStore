#!/usr/local/bin/perl
$rcsid='$Id: version.pl,v 1.1 1998/11/12 11:36:45 dirkx Exp $';
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
/*>version.c - $0 generated 
 * $rcsid
 */
#include <sys/types.h>

#if 0
static char rcsid[]="$rcsid";
#endif

static char version[]= "DBMS $1.$2 - $date - $id\@$h "
#ifdef FORKING
	"forking"
#else
	"NON forking"
#endif
	;

int get_version( void ) {
	return $version;
	}
char * get_full( void ) {
	return version;
	}
|;


