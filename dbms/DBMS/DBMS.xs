/* $Id: DBMS.xs,v 1.13 1999/01/04 22:31:55 dirkx Exp $
 *
 * Perl 'tie' interface to a socket connection. Possibly to
 * the a server which runs a thin feneer to the Berkely DB.
 *  
 * (c) 1998 Dirk-Willem van Gulik / <Dirk.vanGulik@jrc.it>
 *
 * For the ParlEuNet project (http://pen.jrc.it).
 *
 * TP270 Software Technology and Automation Unit
 * Joint Research Center of the European Commission
 * Ispra VA Italy.
 *  
 * Based on DB_File, which came with perl and UKD which
 * came with CILS.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
  
#include <errno.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <unistd.h>
#include <fcntl.h>
#include <netdb.h>                    
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/time.h>
#include <arpa/inet.h>


/*#define TPS*/

#include <db.h>
#include "../include/dbms.h"

typedef struct dbms {
	char * name;
	char * host;
	unsigned long port;
	int mode;
	int sockfd;
	unsigned long addr;
	} dbms;

typedef dbms * DBMS;

#define MAX_GERROR 256
static char global_error[ MAX_GERROR ];
static const char * last_error_str;

static char * dbms_error[]={
#define 	E_UNDEF		1000
		"Not defined",		
#define		E_NONNUL 	1001 
		"Undefined Error",
#define		E_FULLREAD	1002 
		"Could not receive all bytes from DBMS server",
#define		E_FULLWRITE 	1003
		"Could not send all bytes to DBMS server",
#define		E_CLOSE		1004
		"DBMS server closed the connection",
#define		E_HOSTNAME 	1005
		"Could not find/resolve DBMS servers hostname",
#define		E_VERSION	1006
		"DBMS Version not supported",
#define		E_PROTO		1007
		"DBMS Reply not understood",
#define		E_ERROR		1008
		"DBMS Server side error"
#define		E_NOMEM 	1009
		"Out of memory",
#define		E_RETRY		1010
		"Failed after several retries",
#define		E_NOPE		1011 /* also in Alberto's code !! */
		"No such database",
#define		E_XXX		1012
		"No such database",
#define		E_BUG		1013
		"Conceptual error"
};	

void
set_error( int erx )
{
	/* interact with $! in perl.. */
	SV* sv = perl_get_sv("DBMS_ERROR",TRUE); 
	SV* sv2 = perl_get_sv("!",TRUE); 
	if (erx == E_ERROR) {
		last_error_str = global_error;
		} else
	if ((erx > E_UNDEF) && (erx <= E_BUG)) {
		last_error_str = dbms_error[erx - E_UNDEF];
		}
	else {
		last_error_str = strerror( erx ); /* sys_errlist[erx]; */
		};

	sv_setiv(sv, (IV) erx);
	sv_setpv(sv, last_error_str);
	SvIOK_on(sv);

	sv_setiv(sv2, (IV) erx);
	sv_setpv(sv2, last_error_str);
	SvIOK_on(sv2);
	fprintf(stderr,"DBMSD: ERROR %s\n",last_error_str);
}

#define sure(x) ( x!=0 ? x : E_NONNUL )

#ifdef TPS
long int ttime=0;
long int ttps=0;
struct timeval tstart,tnow;
#endif

int
reconnect(
	dbms * me
)
{
	struct sockaddr_in server;
	int one = 1;
	int csndl, csnd, sndbuf = 16*1024;

	/* we could moan if me->sockfd is still	
	 * set.. or do a silent close, just in
	 * case ?
	 */
	if (me->sockfd>=0) {
		close(me->sockfd);
		shutdown(me->sockfd,2);
		}
	
	if ( (me->sockfd = socket( AF_INET, SOCK_STREAM, 0))<0 ) {
		return sure(errno);
		};

	/* allow for re-use; to avoid that we have to wait for
	 * a fair amounth of time after disasterous crashes,
	 */
        if( (setsockopt(me->sockfd,SOL_SOCKET,SO_REUSEADDR,
		(const char *)&one,sizeof(one))) <0) {
		me->sockfd = -1;
		close(me->sockfd);
		return sure(errno);
		};

	/*	
		****** fixed for FreeBSD 3.x by AR 2000/06/15 *****
*/
        if (getsockopt(me->sockfd, SOL_SOCKET, SO_SNDBUF,
                (void *) &csnd, (void *) &csndl ) < 0) {
		me->sockfd = -1;
		close(me->sockfd);
		return sure(errno);
		};
	assert(csndl == sizeof(csnd));

	/**/

	/* only set when smaller */
	if ((csnd < sndbuf) &&
           (setsockopt(me->sockfd, SOL_SOCKET, SO_SNDBUF,
                (const void *) &sndbuf, sizeof(sndbuf)) < 0)) {
		me->sockfd = -1;
		close(me->sockfd);
		return sure(errno);
		};

	/* disable Nagle, for speed 
	 */
        if( (setsockopt(me->sockfd,IPPROTO_TCP,TCP_NODELAY,
		(const char *)&one,sizeof(one))) <0) {
		me->sockfd = -1;
		close(me->sockfd);
		return sure(errno);
		};

	/* larger buffer; as we know that we can initially
	 * slide open the window bigger.
	 */

        bzero( (char *) &server,sizeof(server) );

        server.sin_family       = AF_INET;
        server.sin_addr.s_addr  = me->addr;
        server.sin_port         = htons(me->port);

        if ((connect( me->sockfd, ( struct sockaddr *) &server, sizeof (server)))<0 ) { 
		me->sockfd = -1;
		return sure(errno);
		};

	return 0;
	}

int
getpack (
	dbms * me,
	unsigned long len,
	DBT * r
	)
{
	unsigned int gotten;
	char * at;

	r->size = 0;
	r->data = NULL;

	if (len == 0) 
		return 0;	

	if (r == NULL) 
		return E_BUG;

	r->size = 0;
       	r->data = (char *)safemalloc(len);

	if (r->data == 0) 
		return E_NOMEM;

	/* should block ? */

	for( at = r->data, gotten=0; gotten < len;) {
       		ssize_t l;
		l = recv(me->sockfd,at,len-gotten,0);
       		if (l < 0) {
			safefree(r->data);
			r->data=NULL;
       			return sure(errno);
			} else
		if (l == 0) {
			safefree(r->data);
			r->data=NULL;
			return E_CLOSE;
			};
		gotten +=l, at +=l;
		};

	r->size = len;
	return 0;
	};

int i_comms (
	dbms * me,
	int token, 
	int * retval,
	DBT * v1, 
	DBT * v2,
	DBT * r1,
	DBT * r2
	)
{
	int err = 0;
	DBT rr1, rr2;
        struct header cmd;
        struct iovec  iov[3];
        struct msghdr msg;                   
	size_t s;

	*retval = -1;

	rr1.data = rr2.data = NULL;

        cmd.token = token | F_CLIENT_SIDE;

        cmd.len1 = htonl( (v1 == NULL) ? 0 : v1->size );
        cmd.len2 = htonl( (v2 == NULL) ? 0 : v2->size );

        iov[0].iov_base=(char *) & cmd;
        iov[0].iov_len=sizeof(cmd);

        iov[1].iov_base= (v1 == NULL) ? NULL : v1->data;
        iov[1].iov_len = (v1 == NULL) ? 0    : v1->size;

        iov[2].iov_base= (v2 == NULL) ? NULL : v2->data;
        iov[2].iov_len = (v2 == NULL) ? 0    : v2->size;

        msg.msg_name = NULL;
        msg.msg_namelen = 0;
        msg.msg_iov = iov;
        msg.msg_iovlen = 3;
        msg.msg_control = NULL;
        msg.msg_controllen = 0;
        msg.msg_flags= 0;
	s = sendmsg(me->sockfd,&msg,0);

	if (s==0) {
		err=E_CLOSE;
		goto retry_com;
		} else
	if (s<0) {
		err=sure(errno);
		goto retry_com;
		} else
	if (s != iov[0].iov_len + iov[1].iov_len + iov[2].iov_len) {
		err=E_FULLWRITE;
		goto exit_com;
		};

        s=recv(me->sockfd,&cmd,sizeof(cmd),0);
	if(s==0) {
		err=E_CLOSE;
		goto retry_com;
		} else
	if (s<0) {
		err=sure(errno);
		goto retry_com;
		} else
        if (s != sizeof(cmd)) {
		err=E_FULLREAD;
		goto exit_com;
                };
	cmd.len1 = ntohl( cmd.len1 );
	cmd.len2 = ntohl( cmd.len2 );

	rr2.data = rr1.data = NULL;
	if ((err = getpack(me, cmd.len1, r1 ? r1 : &rr1 )) != 0) 
		goto retry_com;

	if ((err = getpack(me, cmd.len2, r2 ? r2 : &rr2 )) != 0) 
		goto retry_com;

        if ((cmd.token & MASK_TOKEN) == TOKEN_ERROR) {
		char * d=NULL;
		int l=0;
		if (r1) {
			l=r1->size; d=r1->data;
			} 
		else {
			l=rr1.size; d=rr1.data;
		}
		if ((d) && (l>0) && (l<MAX_GERROR-1)) {
			strncpy(global_error,d,MAX_GERROR);
			global_error[l]='\0';
			} else {
			strncpy(global_error,"DBMS side errror, no cause reported",MAX_GERROR);	
			};
		err = E_ERROR;
		goto exit_com;
		} 
	else
        if (((cmd.token & MASK_TOKEN) != token) ||
	    ((cmd.token | F_SERVER_SIDE) == 0) ) {
		err = E_PROTO;
		goto exit_com;
		};

	if ( (rr1.data != NULL) && (rr1.size) ) {
		safefree(rr1.data);
		rr1.size=0;
		};

	if ( (rr2.data != NULL) && (rr2.size) ) {
		safefree(rr2.data);
		rr1.size=0;
		};

	if ( (cmd.token & MASK_STATUS) == F_FOUND ) {
		*retval = 0;
		} 
	else {
		*retval = 1;
		if (r1 != NULL) {
			if ((r1->size)&&(r1->size))
				safefree(r1->data);
			r1->data = NULL;
			r1->size = 0;
			};
		if (r2 != NULL) {
			if ((r2->size)&&(r2->size))
				safefree(r2->data);
			r2->data = NULL;
			r2->size = 0;
			};
		};

	err=0;
	goto done_com;

retry_com:
exit_com:
	if ((r1 != NULL) && (r1->data != NULL) && (r1->size != 0) ) {
		safefree(r1->data); r1->size = 0;
		};

	if ((r2 != NULL) && (r2->data != NULL) && (r2->size != 0) ) {
		safefree(r2->data); r2->size = 0;
		};

	if ((rr1.data != NULL) && (rr1.size) )  {
		safefree(rr1.data); rr1.size =0;
		};

	if ((rr2.data != NULL) && (rr1.size) )  {
		safefree(rr2.data); rr2.size =0;
		};

done_com:
	
	return err;
	}


int
reselect( dbms * me )
{
	DBT r1,r2,v1;
	int retval;
	u_long buff[2];
	int err = 0;
	u_long proto = DBMS_PROTO;
	u_long mode = me->mode;
	char * name = me->name;

	assert(sizeof(buff) == 8); /* really 4 bytes on the network ? */

	buff[0] = htonl( proto );
	buff[1] = htonl( mode );

	r1.size = sizeof(buff);
	r1.data = &buff;

	r2.size = strlen(name);
	r2.data = name;

	v1.data = NULL; /* set up buffer for return protocol and confirmation */
	v1.size = 0;

	if (err = i_comms( me, TOKEN_INIT, &retval, &r1, &r2, &v1, NULL)) {
		/* keep the exit code 
		 * fprintf(stderr,"Fail2\n");
		 */
		}
	else
	if (retval == 1)  {
		err = E_NOPE;
		}
	else
	if (retval < 0)  {
		err = E_PROTO;
		}
	else 
	if (ntohl( *((u_long *)v1.data)) > DBMS_PROTO ) {
		err = E_VERSION;
		};

	safefree(v1.data);
	return err;
}

int comms (
	dbms * me,
	int token, 
	int * retval,
	DBT * v1, 
	DBT * v2,
	DBT * r1,
	DBT * r2
	)
{
	int errs = 5;
	int err = 0;
	DBT rr1, rr2;
        struct header cmd;
        struct iovec  iov[3];
        struct msghdr msg;                   
	size_t s;

	struct sigaction act,oact;
#ifdef TPS
	gettimeofday(&tstart,NULL);
#endif
	/* for now, SA_RESTART any interupted function calls
	 */
	act.sa_handler = SIG_IGN;
	sigemptyset(&act.sa_mask);
	act.sa_flags = SA_RESTART;

	sigaction(SIGPIPE,&act,&oact);
	*retval = -1;

	/* now obviously this is wrong; we do _not_ want to continue
	 * during certain errors.. ah well..
	 */
	for(errs=0; errs<10; errs++ ) {
		if ((me->sockfd >= 0) && 
		   ((err=i_comms(me, token, retval, v1, v2, r1, r2)) == 0))
			break;

		/* we could of course exit on certain errors, but
		 * which ? we call recv, et.al.
		 */
		if (err == EAGAIN || err==EINTR)
			continue;

		sleep(errs*2); 
		shutdown(me->sockfd,2);
		close(me->sockfd);

		me->sockfd = -1; /* mark that we have an issue */
		if ( ((err=reconnect(me)) == 0) && 
		     ((err=reselect(me)) == 0) ) {
			if (errs) 
				fprintf(stderr,"DBMS: Reconnected %d\n",errs);
			}
		else
		if (errs) 
			fprintf(stderr,"DBMS: Waiting.. %d\n",errs);
		};

	if (err) 
		set_error(err);
	
#ifdef TPS
	gettimeofday(&tnow,NULL);
	ttps++;
	ttime +=
		( tnow.tv_sec - tstart.tv_sec ) * 1000000 +
		( tnow.tv_usec - tstart.tv_usec ) * 1;
	printf("[%d] ",token);
#endif
	/* restore whatever it was before 
	 */
	sigaction(SIGPIPE,&oact,&act);
	return err;
	}

MODULE = DBMS	PACKAGE = DBMS
	
DBMS
TIEHASH(meself,name,mode=DBMS_MODE,host=DBMS_HOST,port=DBMS_PORT)
	char *		meself
	char *		name
	int		mode
	char *		host
	int		port

	PREINIT:
	dbms * me;
	int i,err=0;

	CODE: 

	me = (dbms *)safemalloc(sizeof(dbms));
	if (me==NULL) {
		set_error(E_NOMEM);
		XSRETURN_UNDEF;
		};
	
	me->addr = INADDR_NONE;
	me->sockfd = -1;
	me->mode = mode;
	me->port = port;
	me->name = name;
	me->host = host;

  	/* quick and dirty hack to check for IP vs FQHN and
	 * fall through when in doublt.
	 */
	for (i=0; me->host[i] != '\0'; i++)
        	if (!isdigit(me->host[i]) && me->host[i] != '.')
            		break;

    	if (me->host[i] == '\0')
		me->addr = inet_addr(host);

	if (me->addr == INADDR_NONE) {
    		struct hostent * hp;
        	if((hp = gethostbyname(me->host))==NULL) {
			set_error(E_HOSTNAME);
			safefree(me);
                	XSRETURN_UNDEF;
                	}; 
		/* copy the address, rather than the pointer
		 * as we need it later. It is an usigned long.
		 */	
		me->addr = *(u_long *) hp->h_addr;
		};

	if (err=reconnect(me)) {
		set_error(err);
		safefree(me);
		XSRETURN_UNDEF;
		};

	if (err=reselect(me)) {
		safefree(me);
		XSRETURN_UNDEF;
		};

	RETVAL=me;
OUTPUT:
	RETVAL

void
DESTROY(me)
	DBMS	me

	PREINIT:
	char * err;
	int retval;

	CODE:

	comms(me, TOKEN_CLOSE, &retval, NULL, NULL, NULL, NULL);   
#ifdef TPS
	if (getenv("GATEWAY_INTERFACE") == NULL)
	   fprintf(stderr,"Performance: %ld # %.2f mSec/trans = %.1f\n",
		ttps, ttime / ttps / 1000.0,
		1000000.0 * ttps / ttime
		);
#endif
	close(me->sockfd);
	safefree(me);

DBT
FETCH(me, key)
	DBMS 		me
	DBT		key

	PREINIT:
	int retval;
	CODE:


	RETVAL.data = NULL; RETVAL.size = 0;

	if(comms(me, TOKEN_FETCH, &retval, &key, NULL,NULL,&RETVAL))
                XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	RETVAL;
OUTPUT:
	RETVAL


DBT
INC(me, key) 
        DBMS           	me
        DBT            	key

        PREINIT:
        int retval;  
        DBT rval;

        CODE:
        if (comms(me, TOKEN_INC, &retval, &key, NULL, NULL, &RETVAL))
                XSRETURN_UNDEF;

	if (retval == 1) 
		XSRETURN_UNDEF;

        RETVAL;
OUTPUT: 
        RETVAL
        
int
STORE(me, key, value)
	DBMS		me	
	DBT		key
	DBT		value

        PREINIT:
	int retval;

        CODE:
	if (comms(me, TOKEN_STORE, &retval, &key, &value, NULL, NULL))
                XSRETURN_UNDEF;

        RETVAL = (retval == 0) ? 1 : 0;
OUTPUT:
        RETVAL

int
DELETE(me, key)
	DBMS	me
	DBT	key
        PREINIT:
	int retval;

        CODE:

        if(comms(me, TOKEN_DELETE, &retval, &key, NULL, NULL, NULL))
                XSRETURN_UNDEF;

        RETVAL = (retval == 0) ? 1 : 0;
OUTPUT:
        RETVAL                               

DBT
FIRSTKEY(me)
	DBMS	me

        PREINIT:
	int retval;

        CODE:
	RETVAL.data = NULL; RETVAL.size = 0;
        if(comms(me, TOKEN_FIRSTKEY, &retval, NULL, NULL, &RETVAL, NULL))
                XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	RETVAL;
OUTPUT:
        RETVAL                               

DBT
NEXTKEY(me, key)
	DBMS	me	
	DBT		key

       	PREINIT:
	int retval;

        CODE:             
	RETVAL.data = NULL; RETVAL.size = 0;

        if (comms(me, TOKEN_NEXTKEY, &retval, &key, NULL, &RETVAL, NULL))
		XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

        RETVAL;
OUTPUT:
        RETVAL
                                           
int
sync(me)
	DBMS	me	

	PREINIT:
	int retval;

	CODE:

        if (comms(me, TOKEN_SYNC, &retval, NULL, NULL, NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;
OUTPUT:
        RETVAL                         

int
EXISTS(me, key)
	DBMS	me
	DBT	key

        PREINIT:
	int retval;

        CODE:

        if (comms(me, TOKEN_EXISTS, &retval, &key, NULL,NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;
OUTPUT:
        RETVAL                         

int
CLEAR(me)
	DBMS	me

        PREINIT:
	int retval;

        CODE:
        if (comms(me, TOKEN_CLEAR, &retval, NULL, NULL, NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;
OUTPUT:
        RETVAL                         

