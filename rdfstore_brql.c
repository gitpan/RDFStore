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

#include <stdio.h>

#include "rdfstore_log.h"
#include "rdfstore_brql.h"
#include "y.tab.h"

rdfstore_brql_list *
rdfstore_brql_list_new( int type, unsigned char * value, int len ) {
	rdfstore_brql_list *li;

	if(	( type == RDFSTORE_BRQL_LIST_TYPE ) ||
		( value == NULL ) )
		return NULL;

        li = (struct rdfstore_brql_list *)RDFSTORE_MALLOC(sizeof(struct rdfstore_brql_list));

        if( li == NULL )
                return NULL;

        li->next = NULL;
        li->value.structured.value = NULL;
        li->type = type;

        li->value.textual.len = 0;
        li->value.textual.value = NULL;

	if ( len > 0 ) {
        	li->value.textual.len = len;
        	li->value.textual.value = (unsigned char *)RDFSTORE_MALLOC( ( len+1 ) * sizeof(unsigned char) );

		if( li->value.textual.value == NULL ) {
			RDFSTORE_FREE( li );
			return NULL;
			};

		memcpy(li->value.textual.value, value, len);
		memcpy(li->value.textual.value+len, "\0", 1);
		};

        return li;
	};

rdfstore_brql_list *
rdfstore_brql_list_new_list(rdfstore_brql_list * value) {
	rdfstore_brql_list *li;

        li = (struct rdfstore_brql_list *)RDFSTORE_MALLOC(sizeof(struct rdfstore_brql_list));

        if(li==NULL)
                return NULL;

        li->next = NULL;
        li->value.textual.len = 0;
        li->value.textual.value = NULL;
        li->type = RDFSTORE_BRQL_LIST_TYPE;

        li->value.structured.value = ( value != NULL ) ? value : NULL;

	return li;
	};

int rdfstore_brql_list_free(rdfstore_brql_list * list) {

	if ( list == NULL )
		return 0;

	rdfstore_brql_list_free( list->next );

	if( list->type == RDFSTORE_BRQL_LIST_TYPE ) {
		rdfstore_brql_list_free( list->value.structured.value );
	} else {
		if ( list->value.textual.value != NULL )
			RDFSTORE_FREE( list->value.textual.value );
		};
	RDFSTORE_FREE( list );

	return 1;
	};

rdfstore_brql_list * rdfstore_brql_list_exists(
	rdfstore_brql_list * list,
	int type,
	char * value ) {
	rdfstore_brql_list * li=NULL;

	if(	( list == NULL ) ||
		( list->type == RDFSTORE_BRQL_LIST_TYPE ) ||
		( type == RDFSTORE_BRQL_LIST_TYPE ) )
		return NULL;

	li = list;
	do {
		if (	( strcmp(li->value.textual.value, value) == 0 ) &&
			( li->type == type ) )
			return li;
	} while ( ( li = li->next ) != NULL );

	return NULL;
	};

rdfstore_brql_list * rdfstore_brql_list_iesim(
	rdfstore_brql_list * list,
	int i ) {
	rdfstore_brql_list * li=NULL;
	rdfstore_brql_list * iesim=NULL;
	int pos=-1;

	if ( list != NULL ) {
		li = list;
		do {
			pos++;
			if ( pos == i ) {
				iesim = li;
				break;
				};
			} while ( ( li = li->next ) != NULL );
		};

	return iesim;
	};

int rdfstore_brql_list_size(
	rdfstore_brql_list * list ) {
	rdfstore_brql_list * li=NULL;
	int size=0;

	if ( list != NULL ) {
		li = list;
		do {
			size++;
			} while ( ( li = li->next ) != NULL );
		};

	return size;
	};
