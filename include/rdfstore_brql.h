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
*/

#ifndef _H_RDFSTORE_BRQL
#define _H_RDFSTORE_BRQL

/* for BDB in-memory hash stuff */
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"
#include "rdfstore_flat_store.h"

#include "rdfstore_log.h"

#include "rdfstore.h"

#define RDFSTORE_BRQL_ERROR_STRING_SIZE 2048
#define RDFSTORE_BRQL_FILE_BUF_SIZE 2048

typedef enum {
  RDFSTORE_BRQL_UNKNOWN,
  RDFSTORE_BRQL_IDENTIFIER,
  RDFSTORE_BRQL_URI,
  RDFSTORE_BRQL_QNAME,
  RDFSTORE_BRQL_STRING,
  RDFSTORE_BRQL_PATTERN,
  RDFSTORE_BRQL_SIMPLEOR,
  RDFSTORE_BRQL_BOOLEAN,
  RDFSTORE_BRQL_INTEGER,
  RDFSTORE_BRQL_HEX_INTEGER,
  RDFSTORE_BRQL_FLOATING,
  RDFSTORE_BRQL_NULL,
  RDFSTORE_BRQL_VARIABLE,

  RDFSTORE_BRQL_EXPR_UNKNOWN,
  RDFSTORE_BRQL_EXPR_AND,
  RDFSTORE_BRQL_EXPR_OR,
  RDFSTORE_BRQL_EXPR_BIT_AND,
  RDFSTORE_BRQL_EXPR_BIT_OR,
  RDFSTORE_BRQL_EXPR_BIT_XOR,
  RDFSTORE_BRQL_EXPR_EQ,
  RDFSTORE_BRQL_EXPR_NEQ,
  RDFSTORE_BRQL_EXPR_LT,
  RDFSTORE_BRQL_EXPR_GT,
  RDFSTORE_BRQL_EXPR_LE,
  RDFSTORE_BRQL_EXPR_GE,
  RDFSTORE_BRQL_EXPR_LSHIFT,
  RDFSTORE_BRQL_EXPR_RSIGNEDSHIFT,
  RDFSTORE_BRQL_EXPR_RUNSIGNEDSHIFT,
  RDFSTORE_BRQL_EXPR_PLUS,
  RDFSTORE_BRQL_EXPR_MINUS,
  RDFSTORE_BRQL_EXPR_STAR,
  RDFSTORE_BRQL_EXPR_SLASH,
  RDFSTORE_BRQL_EXPR_REM,
  RDFSTORE_BRQL_EXPR_STR_EQ,
  RDFSTORE_BRQL_EXPR_STR_NEQ,
  RDFSTORE_BRQL_EXPR_STR_MATCH,
  RDFSTORE_BRQL_EXPR_STR_NMATCH,
  RDFSTORE_BRQL_EXPR_TILDE,
  RDFSTORE_BRQL_EXPR_BANG,
  RDFSTORE_BRQL_EXPR_AT,
  RDFSTORE_BRQL_EXPR_DATATYPE,
  RDFSTORE_BRQL_EXPR_LITERAL,

  RDFSTORE_BRQL_RESULT_TYPE,
  RDFSTORE_BRQL_LIST_TYPE,

  RDFSTORE_BRQL_LAST= RDFSTORE_BRQL_LIST_TYPE
} rdfstore_brql_types;

#include "rdfstore_brql_dbc.h"

typedef struct rdfstore_brql_list {
        int type;
	union {
        	struct {
                	unsigned char    * value;  /* simple list of strings */
			int len; /* len in bytes/char */
                	} textual;
        	struct {
                	struct rdfstore_brql_list * value; /* or list of lists */ 
                	} structured;
        	} value;
        struct rdfstore_brql_list * next;
        } rdfstore_brql_list;

typedef struct rdfstore_brql_query {
        struct rdfstore_brql_list * resultvars;
        struct rdfstore_brql_list * sources;
        struct rdfstore_brql_list * triple_patterns;
	FLATDB * prefixes; /* some in-memory hash */
        struct rdfstore_brql_list * constraints;
	struct rdfstore_brql_handle * connection;
	struct rdfstore * store;
	struct rdfstore_brql_results * results;
	int binds_size;
	struct rdfstore_brql_results_column * * binds;
	int binds_sp; /* current bind stack pointer */
	int cache_size;
	struct rdfstore_brql_processing_cache * * cache;
	unsigned int num_rows; /* num of rows (to be dynamically filled up) */
	} rdfstore_brql_query;

rdfstore_brql_list * rdfstore_brql_list_new( int type, unsigned char * value, int len );
rdfstore_brql_list * rdfstore_brql_list_new_list( rdfstore_brql_list * value );
rdfstore_brql_list * rdfstore_brql_list_exists( rdfstore_brql_list * list, int type, char * value );
rdfstore_brql_list * rdfstore_brql_list_iesim( rdfstore_brql_list * list, int i );
int rdfstore_brql_list_size( rdfstore_brql_list * list );
int rdfstore_brql_list_free( rdfstore_brql_list * list );

/* misc functions */
void rdfstore_brql_packInt( uint32_t value, unsigned char * buffer );
void rdfstore_brql_unpackInt( unsigned char * buffer, uint32_t * value );

#endif
