/* $Id: dbms.h,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $ $Tag$
 */
#ifndef _H_DBMS
#define _H_DBMS

#ifdef TIME_DEBUG
#define		P0		0
#else
#define		P0		1
#endif

#define		DBMS_HOST	"127.0.0.1"
#define		DBMS_PORT	1234
#define		DBMS_MODE	0666

#define		MASK_SOURCE	(128+64)
#define 	F_CLIENT_SIDE	128
#define 	F_SERVER_SIDE	64
#define 	F_INTERNAL	(128+64)

#define		MASK_STATUS	32
#define		F_FOUND		32
#define		F_NOTFOUND	0

#define		MASK_TOKEN	31
#define		TOKEN_ERROR	0
#define		TOKEN_FETCH	1
#define		TOKEN_STORE 	2	
#define		TOKEN_DELETE 	3		
#define		TOKEN_NEXTKEY 	4
#define		TOKEN_FIRSTKEY 	5
#define		TOKEN_EXISTS	6
#define		TOKEN_SYNC	7
#define		TOKEN_INIT	8
#define		TOKEN_CLOSE	9
#define		TOKEN_CLEAR	10
#define		TOKEN_FDPASS	11 /* only used for internal passing server side */
#define		TOKEN_PING	12 /* only used between servers ?? */
#define		TOKEN_INC	13 /* atomic increment */
#define		TOKEN_LIST	14 /* list all keys */

#define		TOKEN_MAX	15 /* last token.. */

struct header {
	unsigned char	token;
	unsigned long	len1;
	unsigned long	len2;
#ifdef TIME_DEBUG
	struct timeval  stamp;
#endif
	};	

#define MAX_STATIC_NAME		256
#define MAX_STATIC_PFILE	MAXPATHLEN

#ifndef MAX_PAYLOAD
#define MAX_PAYLOAD	(32*1024)
#endif

#ifdef STATIC_CS_BUFF
#define MAX_CS_PAYLOAD	MAX_PAYLOAD
#define	P2		1	
#else
#define P2		0
#endif

#ifdef STATIC_SC_BUFF
#define MAX_SC_PAYLOAD	MAX_PAYLOAD
#define	P1		1
#else
#define P1		0
#endif

#define		DBMS_PROTO	(110+P0*1+P1*2+P2*4)

#endif
