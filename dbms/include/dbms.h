/* $Id: dbms.h,v 1.3 1999/01/04 19:59:10 dirkx Exp $ $Tag$
 */
#ifndef _H_DBMS
#define _H_DBMS

#ifdef TIME_DEBUG
#define		DBMS_PROTO	110
#else
#define		DBMS_PROTO	111
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

struct header {
	unsigned char	token;
	unsigned long	len1;
	unsigned long	len2;
#ifdef TIME_DEBUG
	struct timeval  stamp;
#endif
	};	

#endif
