/* DBMS Server
 * $Id: loop.c,v 1.2 2001/06/18 15:26:18 reggiori Exp $
 *
 * (c) 1998 Joint Research Center Ispra, Italy
 *     ISIS / STA
 *     Dirk.vanGulik@jrc.it
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
#include "handler.h"
#include "mymalloc.h"

/* for debugging..
 */
char * 
show(
	int max,
	fd_set * all, 
	fd_set * show
	)
{	int i;
	static char out[16*1024];
	out[0]='\0'; 
	for(i=0; i<max; i++) if (FD_ISSET(i,all)) {
		char tmp[16];
		if (FD_ISSET(i,show))
			snprintf(tmp,16," %4d",i);
		else
			snprintf(tmp,16,"     ");
		strcat(out,tmp);
		};
	return out;
}

/* sync and flush on DB level, file descriptior level
 * as well as on filesystem/kernel level.
 */
void flush_all( void ) { 
	dbase * p;
	int one = 0;

	for(p=first_dbp; p;p=p->nxt) 
		if (p->handle) {
			(p->handle->sync)(p->handle,0);
			fsync( (p->handle->fd)(p->handle) );
			one++;
		};

	if (one)
		sync();

	log(L_INFORM,"Synced %d databases and the file system",one);
	}

void
select_loop( void )
{
	time_t lsync = time(NULL);
	/* seconds and micro seconds. */
	struct timeval nill={600,0};
	struct timeval *np = &nill;

	if (!mum_pid)
			np = NULL;

	for (;;) {
		int n;
		time_t now = time(NULL);
		struct connection *r, *s;
		dbase * p;
#ifdef FORKING
		child_rec * d;
#endif
		rset=allrset;
		wset=allwset;
		eset=alleset;

		/* mothers do not time out, or if
		 * the last cycle was synced and 
		 * was nothing to do... 
		 */	
		if ((n=select(maxfd+1,&rset,&wset,&eset,np)) < 0) {
			if (errno != EINTR )
				log(L_ERROR,"RWE Select Probem %s",strerror(errno));
			continue;
			};

		/* not done anything for 15 minutes or so.
		 * are there any connections outstanding apart 
		 * from the one to mum ?
		 */
		if ( (n==0) && (mum_pid) && 
			(!(first_dbp && client_list && client_list->next))) {

			// clients but no dbase ?
			assert( ! (client_list) && (client_list->next));

			// a dbase but no clients ?
			assert(! first_dbp);

			log(L_INFORM,"Nothing to do, this child stops..");

			exit(0);
			}

		/* upon request from alberto...  flush
		   every 5 minutes or so.. see if that
		   cures the issue since we moved to raid.
	 	 */
		if ((mum_pid) && (difftime(now,lsync) > 300))  {
			flush_all();
			lsync = now;
			/* next round, we can wait for just about forever */
			// if (n == 0) np = NULL;  XXX not needed
		};
		log(L_DEBUG,"Read  : %s",show(maxfd+1,&allrset,&rset));
		log(L_DEBUG,"Write : %s",show(maxfd+1,&allrset,&wset));
		log(L_DEBUG,"Except: %s",show(maxfd+1,&allrset,&eset));
exit;
		/* Is someone knocking on our front door ? 
		 */
		if ((sockfd>=0) && (FD_ISSET(sockfd,&rset))) {
			struct sockaddr_in client;
		        int len=sizeof(client);
			int fd;

			if (mum_pid) 
				log(L_ERROR,"Should not get such an accept()");
			else 
        		if ((fd = accept(sockfd, 
				    ( struct sockaddr *) &client, &len)) <0) 
                		log(L_ERROR,"Could not accept");
			else {
                		log(L_DEBUG,"Accept(%d)",fd);
				handle_new_connection(fd, C_NEW_CLIENT); 
				};
			};

		/* note that for the pthreads we rely on a mark-and-sweep
		 * style of garbage collect.
		 */
		for ( s=client_list; s != NULL; ) {	
			/* Page early, as the record might get zapped
			 * and taken out of the lists in this loop.
			 */
			r=s; s=r->next;
			assert( r != s );
			if (r->close)
				continue;

			if (FD_ISSET(r->clientfd,&rset)) {
				int trapit=getpid(); // trap forks.
				if (r->tosend != 0) {
					log(L_ERROR,"read request received while working on send");
					zap(r);
					continue;
					} 
				log(L_DEBUG,"read F=%d R%d W%d E%d",
					r->clientfd,
					FD_ISSET(r->clientfd,&rset) ? 1 : 0,
					FD_ISSET(r->clientfd,&wset) ? 1 : 0,
					FD_ISSET(r->clientfd,&eset) ? 1 : 0
					);

				if (r->toget == 0) 
					initial_read(r);
				else 
					continue_read(r);
	
				if (trapit != getpid())
					break;
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				if (r->close) 
					continue;
				};

			if (FD_ISSET(r->clientfd,&wset)) {
				if (r->tosend >= 0 )
					continue_send(r);
				else
					log(L_ERROR,"write select while not expecting to write");
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				if (r->close) 
					continue;
				};

// XXX this eset is a pointless
// excersize, perhaps ??
// only seen on linux-RH5.1
//
			if (FD_ISSET(r->clientfd,&eset)) {
				log(L_ERROR,"Some exception. Unexpected");
				r->close = 1; MX;
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				};
#ifdef TIMEOUT
			if (difftime( r->last, time(NULL) ) > TIMEOUT) {
				inform("Timeout, closed the connection."); 
				r->close =1; MX;
				};
#endif
			}; /* client set loop */

		/* clean up operations... 
		 *    note the order 
		 */
		for ( s=client_list; s != NULL; ) {	
			r=s; s=r->next;
			assert( r != s );
			if ( r->close ) {
				log(L_DEBUG,"General clean %d",r->clientfd);
				zap(r);	
				};
			};

#ifdef FORKING
		for(d=children;d;) {
			child_rec * e = d; d=d->nxt;
			assert( d != e );
			if (e->close)
				zap_child( e );
			};
#endif

		for(p=first_dbp; p;) {
			dbase * q=p; p=p->nxt;
			assert( p != q );
			if (q->close)
				zap_dbs(q);
			};

		}; /* Forever.. */
	} /* of main */
