/* Simple debugging mallic, when/if needed 
 * $Id: mymalloc.c,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $
 */
#include "deamon.h"
#include "mymalloc.h" 	/* to keep us honest */
#include "dbms.h"

char * memdup( void * data, size_t size ) {
        void * out = mymalloc( size );
        if (out == NULL)
                return NULL;
        memcpy(out, data, size );
        return out;
        }  


#ifdef DEBUG_MALLOC
struct mp {
	void * data;
	int line;
	int len;
	char * file;
	TIMESPEC tal;
	struct mp * nxt;
	} mp;

struct mp * mfirst=NULL;
int mpfree=0,mpalloc=0;

void * debug_malloc( size_t len, char * file, int line ) {
	struct mp * p = malloc( sizeof( mp ) );
	if (p==NULL)
		return NULL;
	p->data = malloc( len );
	if (p->data==NULL)
		return NULL;
#ifdef DEBUG
	bzero(p->data,len);
#endif
	p->tal = time(NULL);
	p->file = strdup( file );
	p->line = line;
	p->len = len;
	p->nxt = mfirst;
	mfirst = p;
	mpalloc++;
	return p->data;
	}

void debug_free( void * addr, char * file, int line ) {
        struct mp *q, * * p;

	for( p=&mfirst; *p; p=&((*p)->nxt)) 
		if ((*p)->data == addr) 
			break;

	if (!*p) {
		log(L_ERROR,"Unanticipated Free from %s:%d",file,line);
#ifdef DEBUG
		abort();
#endif
		};
	q = *p; 
	*p=(*p)->nxt;
#ifdef DEBUG
	bzero(q->data,q->len);
#endif
	free(q->data);
	free(q->file);
	free(q);

	mpfree++;
	}

void debug_malloc_dump() {
        struct mp * p; 
	TIMESPEC now=time(NULL);

        log(L_DEBUG,"Memory==malloc %d == %d free",mpalloc,mpfree);
        for( p = mfirst; p; p=p->nxt)
                log(L_DEBUG,"%s %d size %d age %f",
                        p->file,p->line,p->len,
                        difftime(now,p->tal)
                        );
        }

#endif
