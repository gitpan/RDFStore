/* DBMS Server
 * $Id: handler.c,v 1.2 2001/06/18 15:26:18 reggiori Exp $
 *
 * (c) 1998 Web Weaving Internet Engineering
 *     Dirk-Willem van Gulik / dirkx@webweaving.org
 *
 * based on UKDCils
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

/*#include <sys/syslimits.h>*/
#include <sys/param.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/uio.h>

#include <netinet/in.h>
#include <netinet/tcp.h>
#ifdef BSD
#include <db.h>
#else
#include <db_185.h>
#endif

#include "dbms.h"
#include "dbmsd.h"

#include "deamon.h"
#include "mymalloc.h"
#include "handler.h"
#include "children.h"
#include "pathmake.h"

dbase                 * first_dbp = NULL;

char * iprt( DBT * r ) {
        static char tmp[ 128 ]; int i;
	if (r==NULL)
		return "<null>";
	if (r->data==NULL)
		return "<null ptr>";
	if (r->size < 0 || r->size > 1024*1024)
		return "<weird size>";

        for(i=0;i< ( r->size > 127 ? 127 : r->size);i++) {
		int c= ((char *)(r->data))[i];
		tmp[i] =  ((c<32) || (c>127)) ? '.' : c;
		};

        tmp[i]='\0';
        return tmp;
        }                      

char * eptr( int i ) {
	if (i==0) 
		return "Ok   ";
	else
	if (i==1)
		return "NtFnd";
	else
	if (i==2)
		return "Incmp";
	else
	if (i>2)
		return "+?   ";
	else
		return "Fail ";
	}

#ifdef STATIC_BUFF
static dbase * free_dbase_list = NULL;
#endif
static int dbase_counter = 0;

void
free_dbs(
	dbase * q
	)
{
	if (q->handle) {
	   if ((q->handle->sync)(q->handle,0)) 
		log(L_ERROR,"Sync(%s) returned an error prior to close",
			q->name); 
	   if ((q->handle->close)(q->handle))
		log(L_ERROR,"Sync(%s) returned an error prior to close",
			q->name); 
	}
#ifndef STATIC_BUFF
        if (q->pfile) myfree(q->pfile);
        if (q->name) myfree(q->name);
        myfree(q);
#else
	/* pre-fix into free DBS list */
	q->nxt = free_dbase_list;
	free_dbase_list = q;	
#endif
	dbase_counter --;
        };

void
zap_dbs (
	dbase * r
	)
{
	dbase * * p;
	connection * s;

	/* XXX we do not want this ?! before we 
	 * know it we end up in n**2 land
	 */
        for ( p = &first_dbp; *p && *p != r; )
                p = &((*p)->nxt);

        if ( *p == NULL) {
                log(L_ERROR,"DBase to zap not found");
                return;
                };

	/* should we not first check all the connections
	 * to see if there are (about to) close..
	 */
	for(s=client_list; s;s=s->next) 
		if (s->dbp == r) {
			s->close = 1; MX;
			};
        *p = r->nxt;
        free_dbs(r);
        }


void close_all_dbps() {
	dbase * p;

        for(p=first_dbp; p;) {
                dbase * q;
                q = p; p=p->nxt;
		free_dbs( q ); /* XXXX why am I not just calling ZAP ? */
		};
	first_dbp=NULL;
	}
                                            
/* opening of a local database..
 */
int open_dbp( dbase * p ) {

#if 0
        HASHINFO priv = { 
		16*1024, 	/* bsize; hash bucked size */ 
		8,		/* ffactor, # keys/bucket */
		3000,		/* nelements, guestimate */
		512*1024,	/* cache size */
		NULL,		/* hash function */
		0 		/* use current host order */
		}; 
#endif
        umask(0);

	/* XXX Do note that we _have_ a mode variable. We just ignore it.
	 * except for the create flag.
	 *
 	 * XXX we could also pass a &priv=NULL pointer to let the DB's work this
	 * one out..
	 */
        p->handle = 
		dbopen( p->pfile, O_RDWR | p->mode, 0666, DB_HASH, NULL);

        return (p->handle != NULL) ? 0 : errno;
        }


dbase * get_dbp (connection *r, int mode, DBT * v2 ) {
        dbase * p;
	char * pfile;

	/* XXX this should be a HASH ! 
	 */
        for ( p = first_dbp; p; p=p->nxt) 	
		if ( (p->sname == v2->size) &&
                    (bcmp(p->name,v2->data,p->sname)==0) &&
		    (strcmp( r->my_dir, p->my_dir )==0)
                ) return p;

	if (dbase_counter > HARD_MAX_DBASE) {
                log(L_ERROR,"Hard max number of dabases hit. (bug?)");
                return NULL;
                };

#ifdef STATIC_BUFF
	if ((p = free_dbase_list) == NULL)
#endif
        if ((p = mymalloc(sizeof(dbase))) == NULL) {
                log(L_ERROR,"No Memory (for another dbase 1)");
                return NULL;
                };

#ifdef STATIC_BUFF
	free_dbase_list = p->nxt;
#endif
        p->nxt = first_dbp;
        first_dbp = p;
	dbase_counter ++;

#ifndef STATIC_BUFF
	p->name = NULL;
	p->pfile = NULL;
#else
  p->name[0] ='\0';
	p->pfile[0] = '\0';
#endif
	p->num_cls = 0;
	p->close = 0;
	p->mode = mode;
        p->sname = v2->size;
	p->my_dir = r->my_dir;
	p->handle = NULL;

#ifdef FORKING
	p->handled_by = NULL;
#endif

#ifdef STATIC_BUFF
	if ( 1+ v2->size > MAX_STATIC_NAME ) 
#else
   if ((p->name = mymalloc( 1+v2->size ))==NULL) 
#endif
	{
                log(L_ERROR,"No Memory (for another dbase 2)");
		goto clean_and_exit;
                };

        strncpy( p->name, v2->data, v2->size );
	p->name[ v2->size ] = '\0';

	if (!(pfile= mkpath(p->my_dir,p->name)))
		goto clean_and_exit;

#ifdef STATIC_BUFF
	if ( strlen(pfile)+1 > MAX_STATIC_PFILE ) 
#else
   if ((p->pfile = mymalloc(strlen(pfile)+1)) == NULL )
#endif
	{ 
                log(L_ERROR,"No Memory (for another dbase 3)");
		goto clean_and_exit;
                };
	strcpy(p->pfile,pfile);

	/* if you do NOT want it created, it MUST exist, otherwise
	 * we send back an error...
	 */
	if ( (mode & O_CREAT) == 0) {
		struct stat sb;
		int s=stat(p->pfile,&sb);
		log(L_INFORM,"Statting %s -> %d",p->pfile,s);
		if (s==-1) 
			goto clean_and_exit;
		};
		
#ifdef FORKING
	/* if we are the main process, then pass
	 * on the request to a suitable child;
	 * if we are the 'child' then do the
	 * actual work..
	 */
	if (!mum_pid) {
		int mdbs=0,c=0;
		struct child_rec * q, *best;

		/* count # of processes and get the least
		 * loaded one of the lot. Or create a
		 * fresh one. XXXX We could also go for 
		 * a rotational approach, modulo the counter.
		 * that would remove the need to loop, but
		 * spoil the load distribution.
		 */
		if (child_counter < max_processes) {
		  	q=create_new_child();
			/* fork/child or error */
		  	if ((q == NULL) && (errno))
				goto clean_and_exit;
			if (q == NULL)
				return NULL; /* just bail out if we are the child */
		  	best=q;
			}
		else {
			for(c=0,q=children; q; q=q->nxt)
				if ( mdbs == 0 || q->num_dbs < mdbs ) {
					mdbs = q->num_dbs;
					best = q;
					};
			};

		p->handled_by = best;
		p->handled_by->num_dbs ++;
		return p;	
		}; /* if mother */
	/* we are a child... just open normal. 
	 */
#endif
        if (open_dbp( p ) == 0) 
		return p;

	log(L_ERROR,"Open1 %s failed: %s",p->pfile,strerror(errno));

clean_and_exit:
	p->close = 1; MX;

	/* repair... and shuffle... */
        first_dbp = p->nxt;
#ifndef STATIC_BUFF
	if (p->pfile) myfree(p->pfile);
	if (p->name) myfree(p->name);
	if (p) myfree(p);
#else
	p->nxt = free_dbase_list;
	free_dbase_list = p;
#endif
	dbase_counter --;
	return NULL;
        }

void do_init( connection * r) {
	DBT val;
	u_long proto;
	u_long mode;

	val.data = &proto;
	val.size = sizeof( u_long );

	mode =htonl( ((u_long *)(r->v1.data))[1] );

#ifdef FORKING
	assert(mum_pid==0);
#endif
	if (r->v1.size == 0) {
		reply_log(r,L_ERROR,"No protocol version");
		return;
		};


	proto =((u_long *)(r->v1.data))[0];
	if ( htonl(proto) != DBMS_PROTO ) {
		reply_log(r,L_ERROR,"Protocol not supported");
		return;
		};

	/* work out wether we have this dbase already open, 
	 * and open it if ness. 
	 */
	r->dbp = get_dbp( r, mode, &(r->v2)); /* returns NULL on error or if it is a child */

	if (r->dbp == NULL) {
		if (errno == ENOENT) {
			log(L_DEBUG,"Closing instantly with a not found");
			dispatch(r, TOKEN_INIT | F_NOTFOUND,&val,NULL);
			return;
			};
#ifdef FORKING
		if (!mum_pid)
#endif
			reply_log(r,L_ERROR,"Open2 database '%s' failed: %s",
				iprt(&(r->v2)),strerror(errno));
		return;
		};

	r->dbp->num_cls ++;
#ifdef FORKING
	if (handoff_fd(r->dbp->handled_by, r)) 
		reply_log(r,L_ERROR,"handoff %s : %s",
				r->dbp->name,strerror(errno));
#else
	dispatch(r, TOKEN_INIT | F_FOUND,&val,NULL);
#endif
	return;
	}

#ifdef FORKING
void do_pass( connection * mums_r) {  
	/* this is not really a RQ coming in from a child.. bit instead
 	 * a warning that we are about to pass a file descriptor
	 * in the next message. There is no need to actually confirm
	 * anything if we are successfull, we should just be on the 
	 * standby to get the FD, and treat it as a new connection..
	 *
	 * note that the r->fd is _not_ a client fd, but the one to
	 * our mother.
	 */
	connection * r;
	int newfd;
	u_long proto,mode;
	DBT val;

	assert(mum_pid);

	if ((newfd=takeon_fd(mum_fd))<0) {
		reply_log(mums_r,L_ERROR,"Take on failed: %s",
			strerror(errno));
		/* give up on the connection to mum ?*/
		mums_r->close = 1; MX;
		return;
		};

	/* try to take this FD on board.. and let it do
	 * whatever error moaning itself.
	 */
	proto =((u_long *)(mums_r->v1.data))[0];
	mode = htonl(((u_long *)(mums_r->v1.data))[1]);

	log(L_INFORM,"PASS db='%s' mode %d",iprt(&(mums_r->v2)),mode);

	if ((r = handle_new_connection( newfd, C_CLIENT)) == NULL)
		return;

	/* is this the sort of init data we can handle ? 
	 */
	if ( htonl(proto) != DBMS_PROTO ) {
		reply_log(r,L_ERROR,"Protocol not supported");
		return;
		};

	r->dbp = get_dbp( r, mode, &(mums_r->v2));

	if (r->dbp== NULL) {
		if (errno == ENOENT) {
			dispatch(r, TOKEN_INIT | F_NOTFOUND,&val,NULL);
			r->close = 1; MX;
			return;
			};
		reply_log(r,L_ERROR,"Open database %s failed: %s",
				iprt(&(mums_r->v2)),strerror(errno));
		return;
		};

	r->dbp->num_cls ++;
	r->dbp->handled_by = NULL;

	/* let the _real_ client know all is well. */
	proto=htonl(DBMS_PROTO);
	val.data= &proto;
	val.size = sizeof( u_long );

	dispatch(r, TOKEN_INIT | F_FOUND,&val,NULL);

	log(L_INFORM,"PASS send init repy on %d to client",r->clientfd);
	return;
	};
#endif

void do_fetch( connection * r) {
	DBT key, val;
	int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	key.data = r->v1.data;
	key.size = r->v1.size;


	err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);

	if (err == 0) 
		dispatch(r,TOKEN_FETCH | F_FOUND,&key,&val);
	else 
	if (err == 1)
		dispatch(r,TOKEN_FETCH | F_NOTFOUND,NULL,NULL);
	else
		reply_log(r,L_ERROR,"fetch on %s failed: %s",r->dbp->name,strerror(errno));
	};

void do_inc ( connection * r) {
	DBT key, val;
	int err;
	unsigned long l;
	char * p;
	char outbuf[256]; /* surely shorter than UMAX_LONG */

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	/* all we get from the client is the key, and
	 * all we return is the (increased) value
	 */
	key.data = r->v1.data;
	key.size = r->v1.size;

	err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);

	if ((err == 1) || (val.size == 0)) {
                dispatch(r,TOKEN_INC | F_NOTFOUND,NULL,NULL);
		return;
		}
	else
	if (err) {
		reply_log(r,L_ERROR,"inc on %s failed: %s",r->dbp->name,
			strerror(errno) );
		return;
		};

	/* XXX bit of a hack; but perl seems to deal with
         *     all storage as ascii strings in some un-
         *     specified locale.
         */
	bzero(outbuf,256);
	strncpy(outbuf,val.data,MIN( val.size, 255 ));
	l=strtoul( outbuf, &p, 10 );

	if (*p || l == ULONG_MAX || errno == ERANGE) {
		reply_log(r,L_ERROR,"inc on %s failed: %s",r->dbp->name,
			"Not the (entire) string is an unsigned integer"
			);
		return;
		};
	/* this is where it all happens... */
	l++;

	bzero(outbuf,256);
	snprintf(outbuf,255,"%lu",l);
	val.data = & outbuf;
	val.size = strlen(outbuf);
	
	/* and put it back.. 
	 *
 	 *  	Put routines return -1 on error (setting errno),  0
         *	on success, and 1 if the R_NOOVERWRITE flag was set
         *    	and the key already exists in the file.
	 */
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);

	/* just send it back as an ascii string
	 */
	if (( err == 0 ) || ( err == 1 ))
                dispatch(r,TOKEN_INC | F_FOUND,NULL,&val);
        else
		reply_log(r,L_ERROR,"inc store on %s failed: %s",
			r->dbp->name,strerror(errno));
	};

void do_exists( connection * r) {
        DBT key, val;
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command EXISTS");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

        err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);

        if ( err == 0 )
		dispatch(r,TOKEN_EXISTS | F_FOUND,NULL,NULL);
	else
	if ( err == 1 )
        	dispatch(r,TOKEN_EXISTS | F_NOTFOUND,NULL,NULL);
	else
		reply_log(r,L_ERROR,"exists on %s failed: %s",r->dbp->name,strerror(errno));
        };
   	
void do_delete( connection * r) {
        DBT key;
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command DELETE");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

        err=(r->dbp->handle->del)( r->dbp->handle, &key,0);

       if ( err == 0 )
                dispatch(r,TOKEN_DELETE | F_FOUND,NULL,NULL);
        else
        if ( err == 1 )
                dispatch(r,TOKEN_DELETE | F_NOTFOUND,NULL,NULL);
        else
		reply_log(r,L_ERROR,"delete on %s failed: %s",r->dbp->name,strerror(errno));
        };        

void do_store( connection * r) {
        DBT key, val;
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command STORE");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

        val.data = r->v2.data;
        val.size = r->v2.size;

        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);

	if ( err == 0 )
                dispatch(r,TOKEN_STORE | F_NOTFOUND,NULL,NULL);
        else
        if ( err == 1 )
                dispatch(r,TOKEN_STORE | F_FOUND,NULL,NULL);
        else
		reply_log(r,L_ERROR,"store on %s failed: %s",r->dbp->name,strerror(errno));

        };
      
void do_sync( connection * r) {
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command SYNC");
		return;
		};

        err=(r->dbp->handle->sync)( r->dbp->handle,0);

        if (err < 0 ) {
		reply_log(r,L_ERROR,"sync on %s failed: %s",r->dbp->name,strerror(errno));
                }
	else {
        	dispatch(r,TOKEN_SYNC,NULL,NULL);
		};
        };

void do_clear( connection * r) {
	int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command CLEAR");
		return;
		};

	/* close the database, remove the file, and repoen... ? */	
	if ( ((err=(r->dbp->handle->close)( r->dbp->handle)) < 0 ) ||
	     ((err=unlink(r->dbp->pfile)) !=0) ||
	     ((err=open_dbp( r->dbp )) != 0) ) 
	{
		reply_log(r,L_ERROR,"clear on %s failed: %s",r->dbp->name,strerror(errno));
                return;
                };

	trace("%6s %12s %s","SYNC",r->dbp->name,eptr(err));
	dispatch(r, TOKEN_CLEAR,NULL, NULL);
	};
                	
void do_list( connection * r) {
#if 0
        DBT key, val;
        int err;

	/* now the issue here is... do we want to do
	 * the entire array; as one HUGE malloc ?
	 */

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command LIST");
		return;
		};

	/* keep track of whom used the cursor last...*/
	r->dbp->lastfd = r->clientfd;

	f = R_FIRST;
        for(;;) {
        	err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val,f);
		if ( err ) last;
		f = F_NEXT;

		};

        if ( err < 0 )
		reply_log(r,L_ERROR,"first on %s failed: %s",
			r->dbp->name,strerror(errno));

	if ( err == 1 )
                dispatch(r,TOKEN_FIRSTKEY | F_NOTFOUND,NULL,NULL);
        else
                dispatch(r,TOKEN_LIST | F_FOUND,&key,&val);
#endif
	reply_log(r,L_ERROR,"Not implemented.. yet");
	}

void do_ping( connection * r) {

        dispatch(r,TOKEN_PING | F_FOUND,NULL,NULL);
	}

void do_close( connection * r) {

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command CLOSE");
		return;
		};

        dispatch(r,TOKEN_CLOSE,NULL,NULL);
	r->close = 1; MX;
	}

void do_first( connection * r) {
        DBT key, val;
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command FIRST");
		return;
		};

	/* keep track of whom used the cursor last...*/
	r->dbp->lastfd = r->clientfd;

        err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val,R_FIRST);

	if ( err == 1 )
                dispatch(r,TOKEN_FIRSTKEY | F_NOTFOUND,NULL,NULL);
        else
        if ( err == 0 )
                dispatch(r,TOKEN_FIRSTKEY | F_FOUND,&key,&val);
        else
		reply_log(r,L_ERROR,"first on %s failed: %s",r->dbp->name,strerror(errno));

        };

void do_next( connection * r) {
        DBT key, val;
        int err;

	if (r->type != C_CLIENT) {
		log(L_ERROR,"Command received from non-client command NEXT");
		return;
		};

	/* We need to set the cursor first, if we where 
	 * not the last using it. 
	 */
	if ( r->dbp->lastfd != r->clientfd ) {
		r->dbp->lastfd = r->clientfd;
        	key.data = r->v1.data;
        	key.size = r->v1.size;
        	err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val,R_CURSOR);

		if (err<0 && errno ==0)
			log(L_WARN,"seq-cursor We have the inpossible err=%d and %d",
				err,errno);

		if ((err != 0) && (err != 1) && (errno != 0) ) {
                	reply_log(r,L_ERROR,"Internal DB Error %s",r->dbp->name);
			return;
			};

		/* BUG: we could detect the fact that the previous key
	 	 *	the callee was aware of, has been zapped. For
	 	 *	now we note that, if the key is not there, we
	 	 *	have received the next greater key. Which we
		 * 	thus return ?! This is an issue.
		 */	
		} 
	else 
		err = 0;

        if (err == 0) 
		err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val,R_NEXT);

	trace("%6s %12s %20s: %s %s","NEXT",
		r->dbp->name, iprt(&key), 
		iprt( err==0 ? &val : NULL ),eptr(err));

        if (( err == 1 ) || (( err <0 ) && (errno == 0)) )
		dispatch(r,TOKEN_NEXTKEY | F_NOTFOUND,NULL,NULL);
	else
	if ( err == 0 )
        	dispatch(r,TOKEN_NEXTKEY | F_FOUND,&key,&val);
        else {
		reply_log(r,L_ERROR,"next on %s failed: %s",r->dbp->name,strerror(errno));
		};
        };

struct command_req cmd_table[ TOKEN_MAX ];
#define IT(i,s,f) { cmd_table[i].cnt = 0; cmd_table[i].cmd = i; cmd_table[i].info = s; cmd_table[i].handler = f; }
void init_cmd_table( void )
{
	int i;
	for(i=0;i<TOKEN_MAX;i++) 
		IT( i, "VOID",NULL );

	IT( TOKEN_INIT,	"INIT",&do_init);
	IT( TOKEN_FETCH,"FTCH",&do_fetch);
	IT( TOKEN_STORE,"STRE",&do_store);
	IT( TOKEN_DELETE,"DELE",&do_delete);
	IT( TOKEN_CLOSE,"CLSE",&do_close);
	IT( TOKEN_NEXTKEY,"NEXT",&do_next);
	IT( TOKEN_FIRSTKEY,"FRST",&do_first);
	IT( TOKEN_EXISTS,"EXST",&do_exists);
	IT( TOKEN_SYNC,	"SYNC",&do_sync);
	IT( TOKEN_CLEAR,"CLRS",&do_clear);
	IT( TOKEN_PING,"CLRS",&do_ping);
	IT( TOKEN_INC,"INCR",&do_inc);
	IT( TOKEN_LIST,"LIST",&do_list);
#ifdef FORKING
	IT( TOKEN_FDPASS,"PASS",&do_pass);
#endif
}

void parse_request( connection * r) {
	register int i = r->cmd.token;

	if ( i>=0 && i<= TOKEN_MAX && cmd_table[i].handler) {
		cmd_table[i].cnt++;
		(cmd_table[i].handler)(r);
		return;
		}

	reply_log(r,L_ERROR,"Unkown command token %d",i);
	r->close = 1; MX;
	return;
	}

