/* DBMS Server 
 * $Id: dbmsd.h,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $
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
#ifndef _H_DBMSD
#define _H_DBMSD

#include <assert.h>	/* XXX wrong place */

#include "dbms.h"
#include "deamon.h"

#ifdef TIME_DEBUG
extern float		total_time;
#endif    

extern connection	      * client_list;
extern struct child_rec	      * children;
extern fd_set			rset,wset,eset,alleset,allrset,allwset;
extern char		      * default_dir;
extern char		      * dir;
extern int			sockfd,maxfd,mum_pgid,mum_pid,mum_fd,max_dbms,max_processes,max_clients;
extern char		      * my_dir;
extern char		      * pid_file;
extern int			check_children;
extern dbase                 * first_dbp;

void select_loop();

/* Some reasonable limit, to avoid running out of
 * all sorts of resources, such as file descriptors
 * and all that..
 */
#define MAX_CLIENT     		2048

/* An absolute limit, above this limit, connections
 * are no longer accepted, and simply dropped without
 * as much as an error.
 */
#define HARD_MAX_CLIENTS   	MAX_CLIENT+5
#define HARD_MAX_DBASE		256

/* hard number for the total number of DBMS-es we
 * are willing to server (in total)
 */

#define MAX_DBMS_CHILD		256
#define MAX_CHILD		32
#define MAX_DBMS		(MAX_DBMS_CHILD * MAX_CHILD)

    
#define SERVER_NAME	"DBMS-Dirkx/3.00"

#define	SERVER		1
#define CLIENT		0

/* some connection types... */
#define		C_UNK		0
#define		C_MUM		1
#define		C_CLIENT	2
#define		C_NEW_CLIENT	3
#define		C_CHILD		4
#define		C_LEGACY	5

struct child_rec * create_new_child(void);
int handoff_fd( struct child_rec * child, connection * r );
int takeon_fd(int conn_fd);
connection * handle_new_connection( int sockfd , int type);

#define MX log(L_DEBUG,"@@ %s:%d\n",__FILE__,__LINE__);
#endif
