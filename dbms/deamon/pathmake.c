/* $Id: pathmake.c,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $
 *
 * (c) 1998 Joint Research Center Ispra, Italy
 *     ISIS / STA
 *     Dirk.vanGulik@jrc.it
 *
 * (c) 1995 Web-Weaving m/v Enschede, The Netherlands
 *     dirkx@webweaving.org
 */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

#include <fcntl.h>
#include <time.h>
#include <string.h>
#include <signal.h>

#include <sys/param.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/uio.h>

#include "dbms.h"
#include "deamon.h"
#include "pathmake.h"

/* returns null and/or full path
 * to a hashed directory tree. 
 * the final filename is hashed out
 * within that three. Way to complex
 * by now. Lifted from another project
 * which needed more.
 */
char *
mkpath(char * base, char * infile)
{
	char * file; int i,j;
    	char * slash,* dirname;
	static char tmp[ MAXPATHLEN ];
	char * inpath;
	char tmp2[ MAXPATHLEN ];
#define MAXHASH 2
	static char hash[ MAXHASH+1 ];

	strcpy(inpath=tmp2,infile);

	memset(hash,'_',MAXHASH);
	hash[ MAXHASH ]='\0';

	if (base==NULL)
		base="/";

	if (inpath==NULL || inpath[0] == '\0') {
		log(L_ERROR,"No filename or path for the database specified");
		return NULL;
		};

	/* remove our standard docroot if present
	 * so we can work with something relative.
	 * really a legacy thing from older perl DBMS.pm
	 * versions. Can go now.
	 */
	if (!(strncmp(base,inpath,strlen(base))))
		inpath += strlen(base);

        /* fetch the last leaf name 
	 */
	if((file = strrchr(inpath, '/')) != NULL) {
		*file = '\0';
		file++;
		} 
	else {
		file = inpath;
		inpath = "/";
		};

	if (!strlen(file)) {
		log(L_ERROR,"No filename for the database specified");
		return NULL;
		};
 
	strncpy(hash,file,MIN(strlen(file),MAXHASH));

//	strcat(tmp,base,"/",inpath,"/",hash,"/",file,NULL);
	strcpy(tmp,"/");
	strcat(tmp,base);
	strcat(tmp,"/");
	strcat(tmp,inpath);
	strcat(tmp,"/");
	strcat(tmp,hash);
	strcat(tmp,"/");
	strcat(tmp,file);

// 	sanity for leaf names...
//	actually this is really bad.. 
//
	if ((slash=strrchr(tmp,'.')) !=NULL) {
		if ( (!strcasecmp(slash+1,"db")) ||
		     (!strcasecmp(slash+1,"dbm")) ||
		     (!strcasecmp(slash+1,"gdb"))
		   ) *slash = '\0';
		};

	strcat(tmp,".db");

	for(i=0,j=0; tmp[i]; i++) {
		if (i && tmp[i]=='/' && tmp[i-1] =='/')
			continue;
		if (i != j) tmp[j] = tmp[i];
		j++;
		};
	tmp[j] = '\0';
	

	/* run through the full path name, and verify that
	 * each directory along the path actually exists
	 */
    	slash = tmp;
    	dirname = tmp;

  	while((slash=strchr(slash+1,'/')) != NULL) {
	    	struct stat s;
	    	*slash='\0';
    		*dirname='/';
    		/* check if tmp exists and is a directory (or a link
    		 * to one.. if not, create it, else give an error 
    		 */
    		if (stat(tmp,&s) == 0) {
			/* something exists.. it must be a directory 
			 */
			if ((s.st_mode & S_IFDIR) == 0) {
				log(L_ERROR,"Creation of %s failed; path element not directory",tmp);
				return NULL;
				};
			} 
		else if ( errno == ENOENT ) {
    			if ((mkdir(tmp,(S_IRWXU | S_IRWXG | S_IRWXO))) != 0) {
				log(L_ERROR,"Creation of %s failed; %s",tmp, strerror(errno));
				return NULL;
				};
			} 
   		 else {
			log(L_ERROR,"Path creation to failed at %s:%s",tmp,strerror(errno));
			return NULL;
    			};
   		 dirname=slash;
  		}
    	*dirname='/';

	return tmp;
	};
