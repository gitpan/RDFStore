/* DBMS Server
 * $Id: loop.c,v 1.5 1998/12/19 19:43:29 dirkx Exp $
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
#include <db.h>

#include "dbms.h"
#include "dbmsd.h"

#include "deamon.h"
#include "handler.h"
#include "mymalloc.h"

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
	int changes;
	time_t lsync = time(NULL);

	for (changes=0 ; ; ) {
		int n;
		time_t now = time(NULL);
		struct connection *r, *s;
		dbase * p;
#ifdef FORKING
		child_rec * d;
#endif

		/* seconds and micro seconds. */
		struct timeval nill={600,0};
		struct timeval *np = &nill;
		rset=allrset;
		wset=allwset;
		eset=alleset;

		/* mothers should wait forever ? */	
		if (mum_pid == getpid())
			np = NULL;

		if ((n=select(maxfd+1,&rset,&wset,&eset,np)) < 0) {
			if (errno != EINTR )
				log(L_ERROR,"RWE Select Probem %s",strerror(errno));
			continue;
			};

		if ((n==0) && (mum_pid != getpid())) {
			/* not done anything for 5 minutes.. 
			 * anything outstanding... 
			 */
			if (first_dbp && client_list && client_list->next)
				goto ccontinue;

			if ((client_list) && (client_list->next)) {
				log(L_ERROR,"Hmm still Clients but no Dbases..?");
				goto ccontinue;
				};

			if (first_dbp) {
				log(L_ERROR,"Hmm still DBS but no clients ?");
				goto ccontinue;
				};

			log(L_INFORM,"Nothing to do, this child stops..");
			/* kind of give up.. bored... 
			 */
			exit(0);
			}
		else {
			changes = 1;
			};

ccontinue:
		/* upon request from alberto...  flush
		   every 5 minutes or so..
	 	 */
		if ( (mum_pid != getpid()) && (difftime(now,lsync) > 300 ) && (changes))  {
			flush_all();
			lsync = now;
			};
/*
		log(L_DEBUG,"Read  : %s",show(maxfd+1,&allrset,&rset));
		log(L_DEBUG,"Write : %s",show(maxfd+1,&allrset,&wset));
		log(L_DEBUG,"Except: %s",show(maxfd+1,&allrset,&eset));
*/
		/* Is someone knocking on our front door ? */
		if ((sockfd>=0) && (FD_ISSET(sockfd,&rset))) {
			struct sockaddr_in client;
		        int len=sizeof(client);
			int fd;
			if (mum_pid != getpid()) 
				log(L_ERROR,"Should not get such an accept()");
			else 
        		if ((fd = accept(sockfd, 
				    ( struct sockaddr *) &client, &len)) <0) 
                		log(L_ERROR,"Could not accept");
			else 
				handle_new_connection(fd, C_NEW_CLIENT); 
			};


		for ( s=client_list; s != NULL; ) {	
			/* Page early, as the record might get zapped
			 * in this loop !
			 */
			r=s; s=r->next;
			if (!(r->close))
			   if (FD_ISSET(r->clientfd,&rset)) {
				int trapit=getpid();
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
				};

			if (!(r->close))
			   if (FD_ISSET(r->clientfd,&wset)) {
				if (r->tosend >= 0 )
					continue_send(r);
				else
					log(L_ERROR,"write select while not expecting to write");
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				};

			if (!(r->close))
			   if (FD_ISSET(r->clientfd,&eset)) {
				log(L_ERROR,"Some exception. Unexpected");
#ifdef TIMEOUT
				r->last=time(NULL);
#endif
				};
#ifdef TIMEOUT
			if (!(r->close))
			   if (difftime( r->last, time(NULL) ) > TIMEOUT) {
				inform("Timeout, closed the connection."); 
				r->close =1;
				};
#endif
			};

		/* clean up operations... 
		 *    note the order 
		 */
		for ( s=client_list; s != NULL; ) {	
			r=s; s=r->next;
			if ( r->close ) {
				log(L_DEBUG,"General clean %d",r->clientfd);
				zap(r);	
				};
			};

#ifdef FORKING
		for(d=children;d;) {
			child_rec * e = d; d=d->nxt;
			if (e->close)
				zap_child( e );
			};
#endif

		for(p=first_dbp; p;) {
			dbase * q=p; p=p->nxt;
			if (q->close)
				zap_dbs(q);
			};

		}; /* Forever.. */
	} /* of main */
