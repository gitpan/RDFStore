/* $Id: main.c,v 1.2 2001/06/18 15:26:18 reggiori Exp $
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
#include <stdarg.h>
#include <errno.h>
#include <unistd.h>

#include <pwd.h>
#include <syslog.h>
#include <fcntl.h>
#include <time.h>
#include <string.h>
#include <signal.h>

#include <sys/param.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/uio.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <netinet/in.h>
#include <netinet/tcp.h>

#ifdef BSD
#include <db.h>
#else
#include <db_185.h>
#endif

#include "dbms.h"
#include "dbmsd.h"
#include "version.h"

#include "deamon.h"
#include "handler.h"
#include "mymalloc.h"

#define USER		"nobody"
#define PID_FILE	"/var/run/dbms.pid"
#define DUMP_FILE	"/var/tmp/dbms.dump"
#define PORT 		1234
#define DIR_PREFIX	"/pen/dbms"

/* Listen queue, see listen() */
#define	MAX_QUEUE	128

/* If defined, we check for timeouts (in seconds). When left
 * undefined, no time/bookkeeping is done.
 */
/* #define TIMEOUT		250 */

#ifdef TIME_DEBUG
float			total_time;
#endif  
#ifdef FORKING
struct child_rec      * children=NULL;
#endif
struct connection      * client_list=NULL;
fd_set			rset,wset,eset,alleset,allrset,allwset;
int			sockfd,maxfd,mum_pid,mum_fd, mum_pgid;
char		      * my_dir = DIR_PREFIX;
char		      * pid_file = PID_FILE;
int			max_processes=MAX_CHILD;
int			max_dbms=MAX_DBMS_CHILD;
int			max_clients=MAX_CLIENT;
	
#define SERVER_NAME	"DBMS-Dirkx/3.00"

int			debug = 0;
int			verbose = 0;
int			trace_on = 0;

#define barf(x) { log(L_FATAL,x ":%s",strerror(errno)); exit(1); }

char *exp[]={
	"**FATAL", "**ERROR", "Warning", " Inform", "verbose", "  bloat", "  debug"
	};

int lexp[]={
	LOG_ALERT, LOG_ERR, LOG_WARNING, LOG_INFO, 
		LOG_DEBUG,LOG_DEBUG,LOG_DEBUG
	};

void
reply_log(connection * r, int level, char * fmt, ...)
{
	char tmp[ 1024 ];
	va_list	ap;
	pid_t p = getpid();
	DBT v;
		
	if (level<=verbose) {
	 	snprintf(tmp,1024,"%d:%s %s %s",p,
			(!mum_pid) ? "Mum" : "Cld",
			exp[ level - L_FATAL ],
			fmt);

		va_start(ap,fmt);
		vsyslog(lexp[ level - L_FATAL ],tmp,ap);					va_end(ap);
		}

	va_start(ap,fmt);
	vsnprintf(tmp,1024,fmt,ap);
	va_end(ap);

	v.data = tmp;
	v.size = strlen(tmp);
	dispatch(r,TOKEN_ERROR,&v,NULL);
}

void
log(int level, char * fmt, ...)
{
	char tmp[ 1024 ];
	va_list	ap;
	pid_t p = getpid();

	if (level>verbose) 
		return;	

	snprintf(tmp,1024,"%d:%s %s %s",p,
		(!mum_pid) ? "Mum" : "Cld",
		exp[ level - L_FATAL ],
		fmt);

	va_start(ap,fmt);
	vsyslog(lexp[ level - L_FATAL ],tmp,ap);					va_end(ap);
}

void
trace(char * fmt, ...)
{
        char tmp[ 1024 ];
        va_list ap;
	clock_t tt;
	pid_t p = getpid();

	if (!trace_on) return;
	
	time(&tt);

        snprintf(tmp,1024,"%d:%s %20s\t%s\n",
		p,
                (!mum_pid) ? "Mum" : "Cld",
		asctime(gmtime(&tt)),
                fmt
		);

        va_start(ap,fmt);
        vprintf(tmp,ap);
        va_end(ap);
	fflush(stdout);
}    

int check_children=0;

void loglevel( int i) {
	if (i == SIGUSR1 ) verbose++;
	if (i == SIGUSR2 ) {
		verbose=0;
		for(i=0; i < sizeof(cmd_table) / sizeof(struct command_req); i++) 
			cmd_table[i].cnt = 0;
		};

	log(L_ERROR,"Log level changed by signal to %d",debug);
	}

	
void dumpie ( int i ) {
#ifdef FORKING
	child_rec * c;
#endif
	connection * r;
	dbase * d;
	time_t t=time(NULL);
	FILE * f;
	if ((f=fopen(DUMP_FILE,"w"))==NULL) {
		log(L_ERROR,"Cannot open dbmsd.dump: %s",strerror(errno));
		return;
		};

	fprintf(f,"# Dump DBMS - pid=%d - %s\n",getpid(),ctime(&t));
#ifdef FORKING
	fprintf(f,"# Children\n");
	for( c=children; c; c=c->nxt) {
		fprintf(f," %7p Pid %5d conn=%p fd=%d",
			c,c->pid,c->r,c->r ? c->r->clientfd : -1);
		for( d=first_dbp; d; d=d->nxt ) if (d->handled_by == c)
			fprintf(f,"\t%7p %s\n",d,d->name);
		};
#endif
	fprintf(f,"# Databases\n");
	for( d=first_dbp; d; d=d->nxt ) 
#ifdef FORKING 
		fprintf(f," %7p %s %p\n", d,d->name, d->handled_by);
#else
		fprintf(f," %7p %s\n", d,d->name);
#endif
	
	fprintf(f,"# Clients\n");
	for( r=client_list; r; r=r->next)
		fprintf(f," %7p fd=%d type=%d Dbase %7p %s\n",
			r,r->clientfd,r->type,r->dbp,
			( r->dbp ? r->dbp->name : 0));

	fprintf(f,"# Stats\n");
	for(i=0; i < sizeof(cmd_table) / sizeof(struct command_req); i++) 
		fprintf(f," %8s: %d\n",cmd_table[i].info, cmd_table[i].cnt);

	fclose(f);
	};

void childied( int i ) {
	int oerrno=errno;
	int status;
	int pid;

	/* reap children, and mark them closed.
	 */
	while((pid=waitpid(-1,&status,WNOHANG))>0) {
#ifdef FORKING
		child_rec * c;
		log(L_INFORM,"Skeduled to zap one of my children pid=%d",pid);
		for(c=children;c;c=c->nxt) 
			if (c->pid == pid) 
				c->close = 1; MX;
#endif
		}

	if ((pid == -1) && ( errno=ECHILD)) {
#if 0
		log(L_ERROR,"Gotten CHILD died signal, but no child...");
#endif
		} else
	if (pid == -1) {
		log(L_ERROR,"Failed to get deceased PID: %s",strerror(errno));
		} 

	errno=oerrno;
	return;
}

int
main( int argc, char * argv[]) 
{
 	struct sockaddr_in  	server;
	int 			port;
	int 			dtch=1;
	int			one=1,i;
	struct rlimit 		l;
	int 			needed=0;
	char			* as_user=USER;
	struct sigaction 	act,oact;

	port = PORT;

	for( i=1; i<argc; i++) {
		if ((!strcmp(argv[i],"-p")) && (i+1<argc)) {
			port=atoi(argv[++i]);
			if (port<=1) {
				fprintf(stderr,"Aborted: You really want a port number >1.\n");
				exit(1);
				};
			} else
		if ((!strcmp(argv[i],"-d")) && (i+1<argc)) {
			my_dir = argv[++i];
			} else
		if ((!strcmp(argv[i],"-u")) && (i+1<argc)) {
			as_user= argv[++i];
			} else
		if (!strcmp(argv[i],"-U")) {
			as_user= NULL;
			} else
		if ((!strcmp(argv[i],"-P")) && (i+1<argc)) {
			pid_file= argv[++i];
			} else
		if ((!strcmp(argv[i],"-n")) && (i+1<argc)) { 
			max_processes = atoi( argv[ ++i ] );
			if ((max_processes < 1) || (max_processes > MAX_CHILD)) {
				fprintf(stderr,"Aborted: Max Number of child processes must be between 1 and %d\n",MAX_CHILD);
				exit(1);
				};
			} else
		if ((!strcmp(argv[i],"-m")) && (i+1<argc)) { 
			max_dbms = atoi( argv[ ++i ] );
			if ((max_dbms < 1) || (max_dbms > MAX_DBMS)) {
				fprintf(stderr,"Aborted: Max Number of DB's must be between 1 and %d\n",MAX_DBMS);
				exit(1);
				};
			} else
		if ((!strcmp(argv[i],"-C")) && (i+1<argc)) { 
			max_clients = atoi( argv[ ++i ] );
			if ((max_clients < 1) || (max_clients> MAX_CLIENT)) {
				fprintf(stderr,"Aborted: Max Number of children must be between 1 and %d\n",MAX_CLIENT);
				exit(1);
				};
			} else
		if (!strcmp(argv[i],"-x")) {
			verbose++; debug++; 
			if (debug>2) dtch = 0;
			} else
		if (!strcmp(argv[i],"-c")) {
			dtch = 0;
			} else
		if (!strcmp(argv[i],"-t")) {
			trace_on= 1;
			} else
		if (!strcmp(argv[i],"-v")) {
			printf("%s\n",get_full());
			exit(0);
			} else
		if (!strcmp(argv[i],"-X")) {
			verbose=debug=100; dtch = 0;
			} else
		{ 	
			fprintf(stderr,"Syntax: %s [-P <pid-file>] [-d <directory_prefix>] [-p <port>] [-x] [-n <max children>] [-m <max databases>] [-C <max clients>]\n",argv[0]);
			exit(1);
			};
		};

	if (HARD_MAX_CLIENTS < max_clients +3) {
		fprintf(stderr,"Aborted: Max number of clients larger than compiled hard max(%d)\n",HARD_MAX_CLIENTS);
		exit(1);
		};

	needed=MAX(max_processes, max_clients/max_processes+max_dbms/max_processes) + 5;

	if (FD_SETSIZE < needed ) {
		fprintf(stderr,"Aborted: Number of select()-able file descriptors too low (FD_SETSIZE)\n");
		exit(1);
		};

     	if (getrlimit(RLIMIT_NOFILE,&l)==-1) 
		barf("Could not obtain limit of files open\n");

	if (l.rlim_cur < needed ) {
		fprintf(stderr,"Aborted: Resource limit imposes on number of open files too limiting\n");
		exit(1);
		};

     	if (getrlimit(RLIMIT_NPROC,&l)==-1) 
		barf("Could not obtain limit on children\n");

	if (l.rlim_cur < 2+max_processes) {
		fprintf(stderr,"Aborted: Resource limit imposes on number of children too limiting\n");
		exit(1);
		};
	openlog("dbms",LOG_LOCAL4, LOG_PID | LOG_CONS);

	if ( (sockfd = socket( AF_INET, SOCK_STREAM, 0))<0 ) 
		barf("Cannot open socket");

   	if( (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,(const char *)&one,sizeof(one))) <0)
		barf("Could not set REUSEADDR option");

       	if( (setsockopt(sockfd,IPPROTO_TCP,TCP_NODELAY,(const void *)&one,sizeof(one))) <0) 
      		barf("Could not distable Nagle algoritm");

{
	int sendbuf = 32 * 1024;
	int recvbuf = 32 * 1024;

       	if( (setsockopt(sockfd,SOL_SOCKET,SO_SNDBUF,(const void *)&sendbuf,sizeof(sendbuf))) <0) 
      		barf("Could not set sendbuffer size");

       	if( (setsockopt(sockfd,SOL_SOCKET,SO_RCVBUF,(const void *)&recvbuf,sizeof(sendbuf))) <0) 
      		barf("Could not set sendbuffer size");
}
	if ( (i=fcntl(sockfd, F_GETFL, 0)<0) || (fcntl(sockfd, F_SETFL,i | O_NONBLOCK)<0) )
		barf("Could not make socket non blocking");

	bzero( (char *) &server,sizeof(server) );
	server.sin_family	= AF_INET;
	server.sin_addr.s_addr	= htonl( INADDR_ANY );
	server.sin_port		= htons( port );

	if ( (bind( sockfd, ( struct sockaddr *) &server, sizeof (server)))<0 )
		barf("Cannot bind to local machine");

	/* Allow for a que.. */
	if ( listen(sockfd,MAX_QUEUE)<0 ) 
		barf("Could not start to listen to my port");

	/* fork and detach if ness. 
	 */
	if (dtch) {
#ifdef FORKING
		pid_t   pid;
/*
		fclose(stdin); 
		if (!trace_on) fclose(stdout); 
*/
        	if ( (pid = fork()) < 0) {
                	perror("Could not fork");
			exit(1);
			}
        	else if (pid != 0) {
			FILE * fd;
			if (!(fd=fopen(pid_file,"w"))) {
				fprintf(stderr,"Warning: Could not write pid file %s:%s",pid_file,strerror(errno));
				exit(1);
				};
			fprintf(fd,"%d\n", (int)pid);
			fclose(fd);	
                	exit(0);
			};
 
#else
		fprintf(stderr,"No forking compiled in, no detach\n");
#endif

	        /* become session leader 
		 */
       		if ((mum_pgid = setsid())<0)
			barf("Could not become session leader");
		};

	/* XXX security hole.. yes I know... 
	 */
	if (as_user != NULL) {
		struct passwd * p = getpwnam( as_user );
		uid_t uid;

		uid = (p == NULL) ? atoi( as_user ) : p->pw_uid;

		if ( !uid || setuid(uid) ) {
			perror("Cannot setuid");
			exit(0);
			};
	};

#if 0
        chdir(my_dir);          /* change working directory */
//	chroot(my_dir);		/* for sanities sake */
        umask(0);               /* clear our file mode creation mask */
#endif

	mum_pid = 0;

	FD_ZERO(&allrset);
	FD_ZERO(&allwset);
	FD_ZERO(&alleset);

	FD_SET(sockfd,&allrset);
	FD_SET(sockfd,&alleset);

	maxfd=sockfd;
	client_list=NULL;

	log(L_INFORM,"Waiting for connections");

	signal(SIGHUP,dumpie);
	signal(SIGUSR1,loglevel);
	signal(SIGUSR2,loglevel);
	signal(SIGINT,cleandown);
	signal(SIGQUIT,cleandown);
	signal(SIGKILL,cleandown);
	signal(SIGTERM,cleandown);
#ifdef FORKING
	signal(SIGCHLD,childied); 
#endif
	mum_fd = 0;

	trace("Tracing started\n");

	/* for now, SA_RESTART any interupted PIPE calls
	 */
	act.sa_handler = SIG_IGN;
	sigemptyset(&act.sa_mask);
	act.sa_flags = SA_RESTART;
	sigaction(SIGPIPE,&act,&oact);

	init_cmd_table();

	select_loop(); 
		/* get down to handling.. (as the mother) */

	return 0; /* keep the compiler happy.. */
	}
