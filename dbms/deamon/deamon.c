/* DBMS Server
 * $Id: deamon.c,v 1.6 1999/01/04 22:31:56 dirkx Exp $
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

static int going_down = 0;

void 
close_connection ( connection * r ) {
	log(L_VERBOSE,"Closing fd %d",r->clientfd);

        FD_CLR(r->clientfd,&allwset);
        FD_CLR(r->clientfd,&allrset);
        FD_CLR(r->clientfd,&alleset);

	close(r->clientfd);

        /* shutdown(r->clientfd,2); */

        if (r->sendbuff != NULL)
                myfree(r->sendbuff);

        if (r->recbuff != NULL)
                myfree(r->recbuff);

	r->recbuff = r->sendbuff = NULL;

	r->send = r->tosend = 0;
	r->gotten = r->toget = 0;

	r->close = 2;
        return;
        }
                       
void free_connection (connection * r ) {
	log(L_VERBOSE,"Freeing connection fd %d type=%d",r->clientfd,r->type);

	if (r->type == C_MUM) {
		/* connection to the mother lost.. we _must_ exit now.. */
		if (!going_down) 
			log(L_FATAL,"Mamma has died.. suicide time %d",mum_fd);
		cleandown(0);
		} else
	if (r->type == C_CLIENT) {
    		if (r->dbp) {
			/* check if this is the last child using
			 * a certain database, and clean if such is
			 * indeed the case..
			 */
			r->dbp->num_cls --;
			if (r->dbp->num_cls<=0) {
				log(L_INFORM,"Child was the last one to use %s, closing\n", 
					r->dbp->pfile);
				r->dbp->close = 1;
				};
			log(L_DEBUG,"Connection to client closed");
			} 
		else {
			log(L_WARN,"C_Client marked with no database ?");
			}
		} else 
	if (r->type == C_NEW_CLIENT) {
		/* tough.. but that is about it..  or shall we try
		 * to send a message...
		 * 
		 */
		log(L_ERROR,"New child closing.. but then what ?");
		} else 
	if (r->type == C_LEGACY) {
		log(L_DEBUG,"Legacy close");
		} else 
	if (r->type == C_CHILD) {
#ifdef FORKING
		dbase * p=0;
		child_rec * c=NULL;
		/* we lost a connection to a child.. so try to kill 	
		 * it and forget about it...
		 * work out which databases are handled by this child..
		 */
		for(p=first_dbp;p;p=p->nxt)
			if (p->handled_by->r == r) {
				if ((c) && (p->handled_by != c))
					log(L_ERROR,"More than one child pointer ?");
				p->close = 1;
				c = p->handled_by;
				};
		if (c==NULL) {
			log(L_ERROR,"Child died, but no record..");
			} 
		else {
		/* overkill, as we do not even wait for the
		 * child to be clean up after itself.
		 */
		c->close = 1;
		if (kill(c->pid,0) == 0) {
			/* so the child is still alive ? */
			log(L_DEBUG,"Sending kill signal (%d) to %d",
				SIGTERM,c->pid);
			kill(c->pid,SIGTERM);
			};
		};
#else
		log(L_ERROR,"We are non forking, but still see a C_CHILD");
#endif
		} 
	else {
		log(L_ERROR,"Zapping a rather unkown connection type?");
		};

	r->type = C_UNK;
	close_connection(r);
	myfree(r);
	return;
	}

void zap ( connection * r ) {
	connection * * p;
	log(L_VERBOSE,"zapping connection %d T=%d",r->clientfd,r->type);

	for ( p = &client_list ; *p && *p != r; )
		p = &((*p)->next);

	if ( *p == NULL) {
		log(L_ERROR,"Connection to zap not found");
		return;
		};

	*p = r->next;
	free_connection(r);
	}


void cleandown( int signo ) { 
        connection * r;

	if (going_down) 
		log(L_ERROR,"Re-entry of cleandown().");

	going_down = 1;

	shutdown(sockfd,2);
        close(sockfd);

	/* send a kill to my children 
	 */
	if (getpid()==mum_pid)
		kill(SIGTERM,0);

	close_all_dbps();
#ifdef FORKING
	clean_children();
#endif

        for( r=client_list; r;) {
                connection * q;
                q = r; r=r->next;
                close_connection(q);
                };
#ifdef DEBUG_MALLOC
	debug_malloc_dump();
#endif
#ifdef TIME_DEBUG
	fprintf(stderr,"Timedebug: Time waiting=%f, handling=%f network=%f\n",.1,.2,.3);
#endif
	/* and call it a day. 
	 */
	unlink(pid_file);	
	log(L_WARN,"Shutdown completed");
	exit(0);
	}

void continue_send( connection * r ) {
	int s;
	log(L_VERBOSE,"Continued send");

	if ((r->tosend==0) || ( r->send >= r->tosend)) {
		log(L_ERROR,"How did we get here ?");
		r->close=1;
		return;
		};

	s = write(r->clientfd,r->sendbuff+r->send,r->tosend - r->send);

	if ((s<0) && (errno == EINTR))  {
		log(L_INFORM,"Continued send interrupted. Retry.");
		return;
		} 
	else
	if ((s<0) && (errno == EAGAIN))  {
		log(L_WARN,"Continued send would still block");
		return;
		} 
	else
	if (s<0) {
		log(L_ERROR,"Failed to continue write %s",strerror(errno));
		r->close=1;
		return;
		}
	else
	if (s==0) {
		log(L_ERROR,"Client closed the connection on us");
		r->close=1;
		return;
		}	

	r->send += s;
	if ( r->send < r->tosend ) 
		return;

	r->send = r->tosend = 0;
	myfree( r->sendbuff );
	r->sendbuff = NULL;

	FD_CLR(r->clientfd,&allwset);
	log(L_DEBUG,"Done(cont) %d\n",time(NULL));
	return;
	}
	
void dispatch( connection * r, int token, DBT * v1, DBT * v2) {
	int s;

	log(L_DEBUG,"Dispatching reply on fd=%d at %d",r->clientfd,time);
	if ((r->tosend != 0) && (r->send !=0)) {
		log(L_WARN,"dispatch, but still older data left to send");
		goto fail_dispatch;
		};

	r->iov[0].iov_base = (void *) &(r->cmd); 
	r->iov[0].iov_len = sizeof(r->cmd);

	r->iov[1].iov_base = r->v1.data = 
		(v1 == NULL) ? NULL : v1->data;
	r->iov[1].iov_len = r->v1.size = r->cmd.len1 = 
		( v1 == NULL ) ? 0 : v1->size;	

	r->iov[2].iov_base = r->v2.data = 
		(v2 == NULL) ? NULL : v2->data;
	r->iov[2].iov_len = r->v2.size = r->cmd.len2 = 
		( v2 == NULL ) ? 0 : v2->size;	

	r->tosend = sizeof(r->cmd) + r->cmd.len1 + r->cmd.len2;
	r->send =0;

	r->cmd.token = token;
	r->cmd.len1 = htonl( r->cmd.len1 );
	r->cmd.len2 = htonl( r->cmd.len2 );

#ifdef TIME_DEBUG
	gettimeofday(&(r->cmd.stamp),NULL);
#endif
	/* BUG: we also use this with certain errors, in an attempt to
	 *      inform the other side of the error. So it might well be
	 * 	that we block here... one day...
	 */
	s=writev(r->clientfd,r->iov,3);

	if (s<0) {
		if (errno == EINTR) {
			log(L_INFORM,"Initial write interrupted. Ignored");
			s=0;	
			}
		else
		if (errno == EAGAIN) {
			log(L_INFORM,"Initial write would block");
			s = 0;
			}
		else {
			log(L_ERROR,"Initial write error:",strerror(errno));
			goto fail_dispatch;
			};
		}
	else
	if (s==0) {
		log(L_ERROR,"Intial write; client closed connection");
		goto fail_dispatch;
		};

	r->send += s;
	if (r->send == r->tosend) {
		r->send = 0;
		r->tosend =0;
		r->sendbuff = NULL;
		log(L_DEBUG,"Done at %d\n",time(NULL));
		}
	else {
		int at,i; void * p;
		/* create a buffer for the remaining data 
		 */
	
		r->sendbuff = mymalloc( r->tosend - r->send );
		if (r->sendbuff == NULL) {
			log(L_ERROR,	
				"Out of memory whilst creating a secondary write buffer of %d bytes",
				r->tosend - r->send
				);
			goto fail_dispatch;
			};
		for(p=r->sendbuff,i=0,at=0; i < 3; i++) {
			if ( at > r->send ) {
				memcpy(p, r->iov[i].iov_base,r->iov[i].iov_len);
				p+=r->iov[i].iov_len;
				} else
			if ( at + r->iov[i].iov_len > r->send ) {
				int offset = r->send - at;
				int len=r->iov[i].iov_len - offset; 
				memcpy(p, r->iov[i].iov_base + offset, len);
				p+=len;
				} 
			else {
				/* skip, done */
				}
			at += r->iov[i].iov_len;
			};
	
		/* redo our bookkeeping, as we have moved it all in
		 * just one contineous buffer. We had to copy, as the
		 * v1 and v2's propably just contained pointers to either
		 * a static error string or a memmap file form the DB inter
		 * face; neither which are going to live long.
		 */
		r->tosend -= s;
		r->send = 0;

		FD_SET(r->clientfd,&allwset);
		log(L_VERBOSE,"Secondary send");		
		};

	return;

fail_dispatch:
	log(L_WARN,"dispatch failed");
	r->close=1;
	return;
	}

void do_msg ( connection * r, int token, char * msg) {
	DBT rr;

	rr.size = strlen(msg) +1;
	rr.data = msg;

	dispatch(r,token | F_SERVER_SIDE, &rr, NULL);
	return;
	}

connection *
handle_new_connection( 
	int clientfd, int type
	)
{
	connection * new, *r;
	int i,v;

	for( i=0, r=client_list ; r != NULL;  r=r->next) 
		i++;
	
	if (i>HARD_MAX_CLIENTS) {
		log(L_ERROR,"Max number of clients reached (hard max), completely ignoring");
		close(clientfd);
		return NULL;
		};

	if ((new = (connection *) mymalloc(sizeof(connection))) == NULL ) {
		log(L_ERROR,"Could not claim enough memory");
		close(clientfd);
		return NULL;
		};

	bzero(new,sizeof(new));

	if ( (v=fcntl( clientfd, F_GETFL, 0)<0) || (fcntl(clientfd, F_SETFL,v | O_NONBLOCK)<0) ) {
		log(L_ERROR,"Coulg not make socket non blocking: %s",strerror(errno));
		close(clientfd);
		return NULL;	
		};

	FD_SET(clientfd,&allrset);
	FD_SET(clientfd,&alleset);
	if ( clientfd > maxfd ) 
		maxfd=clientfd;

	/* Copy the needed information. */
	new->clientfd = clientfd;
	new->my_dir   = my_dir;
	new->sendbuff = NULL;
	new->recbuff  = NULL;
	new->dbp      = NULL;
	new->type     = type;
#ifdef TIMEOUT
	new->start    = time(NULL);
	new->last     = time(NULL);
#endif
	new->send = new->tosend = new->gotten = new->toget = 0;

        new->next     = client_list;
        client_list   = new;

	if (i >= max_clients) {
		log(L_ERROR,"Too many connections");
		new->close	= 1;
		}
	else {
		new->close      = 0;
		};

	return new;
	}

void final_read( connection * r) {

	r->toget = r->gotten = 0;
	parse_request(r);	

	if (r->recbuff) {
		myfree(r->recbuff);
		r->recbuff = NULL;
		};

	return;
	}


void initial_read( connection * r ) {
	struct header skip_cmd;
	int n=0;
	/* we peek, untill we have the full command buffer, and
	 * only then do we give it any attention. This safes a
	 * few syscalls.
	 */
	n=recv(r->clientfd,&(r->cmd),sizeof(r->cmd),MSG_PEEK);

	if ((n < 0) && (errno == EAGAIN)) {
		return;
		} 
	else
	if ((n < 0) && (errno == EINTR)) {
		return;
		} 
	else
	if (n<0) {
		if (errno != ECONNRESET)
			log(L_ERROR,"Read error %s",strerror(errno));
		r->close=1;
		return;
		} 
	else 
	if (n==0) {
		log(L_INFORM,"Client side close on read %s",strerror(errno));
		r->close=1;
		return;
		}
	else
	if ( n == sizeof(r->cmd) ) {
#ifdef TIMEE_DEBUG
 		float s,m;
		struct timeval t;
		gettimeofday(&t,NULL);
		s=t.tv_sec - r->cmd.stamp.tv_sec;
		m=t.tv_usec - r->cmd.stamp.tv_usec;
		MDEBUG((stderr,"Time taken %f seconds\n", s + m / 1000000.0 ));
		total_time += s + m / 1000000.0; 
#endif

		/* check if this is ok ?, if not, do not 
		 * touch it with a stick.
		 */
#if 0
		if (( (r->cmd.token) & ~MASK_TOKEN ) != F_CLIENT_SIDE ) {
			reply_log(r,L_ERROR,"Not a client side token..");
			r->close=1;
			return;
			};
#endif
		r->cmd.token &= MASK_TOKEN;

		/* set up a single buffer to get the remainder of this 
		 * message 
		 */
		r->v1.size= r->cmd.len1 = ntohl( r->cmd.len1);
		r->v2.size= r->cmd.len2 = ntohl( r->cmd.len2);

#if 1
		if (r->v1.size > 2*1024*1024) {
			reply_log(r,L_ERROR,"Size one to big");
                        r->close=1;
                        return;
                        };

		if (r->v1.size > 2*1024*1024) {
			reply_log(r,L_ERROR,"Size two to big");
                        r->close=1;
                        return;
                        };
#endif
#if 0
{
		int i;
		for(i=0; i<sizeof(cmd_table) / sizeof(struct command_req); i++) 
                   if ( cmd_table[i].cmd == r->cmd.token ) 
			log(L_DEBUG,"Token %s s=%d,%d",
				cmd_table[i].info,r->cmd.len1,r->cmd.len2);
}
#endif

		r->recbuff = r->v2.data = r->v1.data = NULL;
		r->toget = r->gotten = 0;

		if (r->cmd.len1 + r->cmd.len2 > 0) {
			r->recbuff = mymalloc( r->cmd.len1 + r->cmd.len2 );
			if (r->recbuff == NULL) {
				reply_log(r,L_ERROR,
					"No Memrory for RQ string(s) %d bytes",
					r->cmd.len1 + r->cmd.len2);
				r->close=1;
				return;
				};
			r->v1.data = r->recbuff;
			r->v2.data = r->recbuff + r->cmd.len1;
			r->toget = r->cmd.len1 + r->cmd.len2;
			};


		r->iov[0].iov_base = (void *)&skip_cmd;
		r->iov[0].iov_len = sizeof( r->cmd );

		r->iov[1].iov_base = r->recbuff;
		r->iov[1].iov_len = r->toget;

reread:		n = readv( r->clientfd, r->iov, 2);
		if ((n<0) && (errno == EINTR)) {
			log(L_INFORM,"Interrupted readv. Ignored");
			goto reread;
			} 
		else
		if ((n<0) && (errno == EAGAIN)) {
			log(L_ERROR,"Would block. Even though we should get the cmd string. Retry");
			goto reread;
			} 
		else
		if (n<0) {
			log(L_ERROR,"Error while reading remainder");
			r->close=1;
			return;
			}
		else
		if (n==0) {
			log(L_INFORM,"Read, but client closed");
			r->close=1;
			return;
			}
		else
		if ( n < sizeof( r->cmd )) {
			reply_log(r,L_WARN,"Gotten CMD and they someone stole it");
			r->close=1;
			return;
			};

		/* book keeping... */
		n -= sizeof(r->cmd);
		r->gotten += n;

		if ( r->gotten >= r->toget) {
			final_read(r);
			return;
			};
		}
	else {
		/* lets log this, as we want to get an idea if this actually happens */
		log(L_WARN,"Still waitingn for those 5 bytes, gotten just a few");
		return;
		};
	}

void
continue_read( connection * r ) {
	/* fill up the two buffers.. */
	int s;

	log(L_VERBOSE,"continued read for %d..",r->toget);
	s = read( r->clientfd, r->gotten + r->v1.data, r->toget - r->gotten);

	if ((s<0) && (errno == EINTR)) {
		log(L_INFORM,"Interrupted continued read. Ignored");
		return;
		} 
	else
	if (((s<0) && (errno == EAGAIN)) ) {
		log(L_ERROR,"continued read, but nothing there");
		return;	
		}
	else
	if (s<0) {
		log(L_ERROR,"Error while reading remainder");
		r->close=1;
		return;
		} 
	else
	if (s==0) {
		log(L_ERROR,"continued read, but client closed connection");
		r->close=1;
		return;
		}; 

	r->gotten +=s;
	if (r->gotten >= r->toget) {
		final_read(r);
		return;
		};

	}
