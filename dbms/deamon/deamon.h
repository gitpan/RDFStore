/* $Id: deamon.h,v 1.2 2001/06/18 15:26:18 reggiori Exp $
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
#include <sys/time.h>
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

#ifndef _H_DEAMON
#define _H_DEAMON

#if defined(BSD)
#define _HAS_TIME_T
#define _HAS_SENSIBLE_SPRINTF
#endif

#if defined(_HAS_TIMESPEC)
#define TIMESPEC struct timespec
#endif

#if defined(_HAS_TIMESTRUC_T)
#define TIMESPEC timestruc_t
#endif

#if defined(_HAS_TIME_T)
#define TIMESPEC time_t
#endif

#if defined(_HAS_SENSIBLE_SPRINTF)
#define STRLEN(x) (x)
#endif

#if defined(_HAS_SILLY_SPRINTF)
#define STRLEN(x) strlen(x)
#endif
            
#ifdef DEBUG
#ifdef TIME_DEBUG
extern float total_time;

#define MDEBUG( x ) {  \
        struct timeval t;  \
        struct timezone tz; \
        gettimeofday(&t,&tz); \
        fprintf(stderr,"MDEBUG[%5d]: %f: ",getpid(),total_time);\
        fprintf x ; \
	fflush(stderr);\
        }
#else 
#define MDEBUG( x ) {  fprintf(stderr,"MDEBUG[%5d %s]: ",getpid(),getpid()==mum_pid ? "mum" : "cld"); fprintf x ; fflush(stderr); }
#endif

#else
#define MDEBUG( x ) { ; }
#endif


#ifdef FORKING	
typedef struct child_rec {
	int			close;
	struct child_rec	* nxt;
	struct connection 	* r;
	int			pid;	/* pid of the child (for sig detects) */
	int			num_dbs;	/* Number of DBS-es assigned sofar */
	} child_rec;
#endif

typedef struct dbase {
#ifdef FORKING	
	struct child_rec * handled_by;
#endif
	int	  sname;
	int	  mode;
#ifdef STATIC_BUFF
	char	pfile[ MAX_STATIC_PFILE ];
	char 	name[ MAX_STATIC_NAME ];
#else
	char	* pfile;
	char 	* name;
#endif
	char    * my_dir;
	DB	* handle;
	int	  lastfd; /* last FD from which a cursor was set */
	int	  num_cls; /* Number of Clients served */
	struct dbase   * nxt;
	int	close;
	} dbase;

typedef struct connection {

   int	type; /* one of C_MUM, C_CHILD, ... */

	int      clientfd;
	char	*	my_dir;

	struct sockaddr_in address;

	DBT	v1;
	DBT	v2;

#ifdef STATIC_CS_BUFF
	char	sendbuff[ MAX_CS_PAYLOAD ];
#else
	char	* sendbuff;
#endif

#ifdef STATIC_SC_BUFF
	char	recbuff[ MAX_SC_PAYLOAD ];
#else
	char 	* recbuff;
#endif

	struct dbase	* dbp;

	struct header	cmd;
	struct iovec 	iov[3];
	struct msghdr	 msg;
	
	int	   	send;	/* size of the outgoing block */
	int	   	tosend;	/* bytes send sofar.. */

	int		gotten;
	int		toget;

	int	   	close;	/* Shall I close the connection ? */
#ifdef TIMEOUT
	TIMESPEC   	start,last;
#endif
	struct connection	* next;
	} connection;

typedef struct command_req {
        unsigned char cmd;	
	char * info;
	int cnt;
        void (*handler)(connection * r);
        } command_req;

extern struct command_req cmd_table[ TOKEN_MAX ];

#define	L_FATAL		-2
#define	L_ERROR 	-1
#define	L_WARN   	0
#define	L_INFORM 	1
#define	L_VERBOSE	2	 
#define	L_BLOAT		3
#define	L_DEBUG 	4

void reply_log(connection * r, int level, char *fmt, ...);
void log(int level, char *fmt, ...);
void trace(char *fmt, ...);

extern int debug,verbose,trace_on;

#define do_error(r,m) do_error_i(r,m,__FILE__,__LINE__);
#define do_error2(r,m,e) do_error2_i(r,m,e,__FILE__,__LINE__);
void do_error_i ( connection * r, char * msg, char *file, int line );
void do_error2_i ( connection * r, char * msg, int err, char *file, int line );

void dispatch( connection * r, int token, DBT * v1, DBT * v2);

void clean_children( void );
void cleanmost( void );
void cleandown( int signo );

void zap ( connection * r );
void zap_dbs( dbase * q );
#ifdef FORKING	
void zap_child( child_rec * r);
#endif

void close_connection ( connection * r );
//void free_connection ( connection * r );
void continue_send( connection * r );
void final_read( connection * r) ;
void initial_read( connection * r );
void continue_read( connection * r );

extern int client_counter;

#endif
