#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

#include <time.h>

/*#include <sys/syslimits.h>*/
#if !defined(WIN32)
#include <sys/param.h>
#endif
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/uio.h>

#include "rdfstore.h"

int main ( int argc, char * * argv ) {
	FLATDB  * me;
	DBT key, data;
	int kk,vv,err;
	char * kk_buff;
	char * vv_buff;

	memset(&key, 0, sizeof(key));
        memset(&data, 0, sizeof(data));

	kk = 5; /* any bigger make Reconnect DBMS due to too big k/v - why??? */
	vv = 32752; /* any bigger make Reconnect DBMS due to too big k/v - why??? */

	/*err=flat_open(  0, 0, &me, "/tmp/", "/overflow.db", (unsigned int)(32*1024), NULL, 0, NULL,NULL,NULL,NULL );*/
	err=flat_open(  1, 0, &me, "cooltest", "/overflow.db", (unsigned int)(32*1024), "mda12.jrc.it", 2345, NULL,NULL,NULL,NULL );

	if(err!=0) {
		fprintf(stderr,"Cannot connect\n");
		return -1;
		};

	kk_buff = (char *) malloc(sizeof(char)*kk);
	if(kk_buff==NULL) {
		fprintf(stderr,"Cannot allocate key buff\n");
		return -1;
		};

	vv_buff = (char *) malloc(sizeof(char)*vv);
	if(vv_buff==NULL) {
		fprintf(stderr,"Cannot allocate value buff\n");
		return -1;
		};
		

	/* store */
        key.data = kk_buff;
        key.size = sizeof(char)*kk;
        data.data = vv_buff;
        data.size = sizeof(char)*vv;

	err = 0;
	err = flat_store( me, key, data );
        if(     (err!=0) &&
        	(err!=FLAT_STORE_E_KEYEXIST) )
		fprintf(stderr,"Cannot store %s\n",key.data);

	flat_sync ( me );

	free( kk_buff );
	free( vv_buff );

	flat_close( me );

	return 0;
};
