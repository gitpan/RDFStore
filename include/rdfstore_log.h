/*
##############################################################################
# 	Copyright (c) 2000-2004 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by 
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and 
# Dirk-Willem van Gulik. The RDF specific part is based based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################
#
# $Id: rdfstore_log.h,v 1.5 2004/08/19 18:57:43 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE_LOG
#define _H_RDFSTORE_LOG

#ifndef A
#define log(x)	{ printf x; printf("\n"); }
#define plog(x)	{ printf x; perror("Reason:"); }
#define pdie(x) { printf x; perror(NULL);exit(1); }
#else
#define log(x)	{ }
#define plog(x)	{ }
#define pdie(x) { printf x; perror(NULL);exit(1); }
#endif

#ifdef RDFSTORE_DEBUG_MALLOC
void * rdfstore_log_debug_malloc( size_t len, char * file, int line); 
void rdfstore_log_debug_free( void * addr, char * file, int line );
void rdfstore_log_debug_malloc_dump();

#define RDFSTORE_MALLOC(x) rdfstore_log_debug_malloc(x,__FILE__,__LINE__)
#define RDFSTORE_FREE(x) rdfstore_log_debug_free(x,__FILE__,__LINE__)
#else
#define RDFSTORE_MALLOC(x) malloc(x)
#define RDFSTORE_FREE(x)   free(x)
#endif

#if defined(BSD)
#define _HAS_TIME_T
#define _HAS_SENSIBLE_SPRINTF
#endif

#if defined(RDFSTORE_PLATFORM_SOLARIS) || defined(RDFSTORE_PLATFORM_CYGWIN) /* SOLARIS or Cygwin */
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

#endif
