/* $Id: mymalloc.h,v 1.3 1998/11/11 14:52:52 dirkx Exp $
 */
char * memdup( void * data, size_t size );

#ifdef DEBUG_MALLOC
void * debug_malloc( size_t len, char * file, int line); 
void debug_free( void * addr, char * file, int line );
void debug_malloc_dump();

#define mymalloc(x) debug_malloc(x,__FILE__,__LINE__)
#define myfree(x) debug_free(x,__FILE__,__LINE__)
#else
#define mymalloc(x) malloc(x)
#define myfree(x) free(x)
#endif
