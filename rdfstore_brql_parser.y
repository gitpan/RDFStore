/*
 * Copyright (c) 2000-2004 All rights reserved,
 *       Alberto Reggiori <areggiori@webweaving.org>,
 *       Dirk-Willem van Gulik <dirkx@webweaving.org>.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * 3. The end-user documentation included with the redistribution, if any, must
 * include the following acknowledgment: "This product includes software
 * developed by Alberto Reggiori <areggiori@webweaving.org> and Dirk-Willem
 * van Gulik <dirkx@webweaving.org>." Alternately, this acknowledgment may
 * appear in the software itself, if and wherever such third-party
 * acknowledgments normally appear.
 * 
 * 4. All advertising materials mentioning features or use of this software must
 * display the following acknowledgement: This product includes software
 * developed by the University of California, Berkeley and its contributors.
 * 
 * 5. Neither the name of the University nor the names of its contributors may
 * be used to endorse or promote products derived from this software without
 * specific prior written permission.
 * 
 * 6. Products derived from this software may not be called "RDFStore" nor may
 * "RDFStore" appear in their names without prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * ====================================================================
 * 
 * This software consists of work developed by Alberto Reggiori and Dirk-Willem
 * van Gulik. The RDF specific part is based based on public domain software
 * written at the Stanford University Database Group by Sergey Melnik. For
 * more information on the RDF API Draft work, please see
 * <http://www-db.stanford.edu/~melnik/rdf/api.html> The DBMS TCP/IP server
 * part is based on software originally written by Dirk-Willem van Gulik for
 * Web Weaving Internet Engineering m/v Enschede, The Netherlands.
 * 
 */

%{

/*

 RDQL parser as specified for Jena2 by Andy Seaborne see the following:

	http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/~checkout~/jena/jena2/doc/RDQL/rdql_grammar.html

	http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/

	http://www.w3.org/2004/07/08-BRQL/

	http://cvs.sourceforge.net/viewcvs.py/jena/BRQL/

*/

#include <string.h>

#include "lex.h"
#include "rdfstore_brql.h"

#define YY_NO_UNPUT
#define YYDEBUG 1
#define YYERROR_VERBOSE 1

void yyerror(char *s);

rdfstore_brql_query query_data;

rdfstore_brql_list * rpn_tail;

/* add the next item to the RPN list */
void add_to_rpn(rdfstore_brql_list * item) {

	if( query_data.constraints == NULL )
        	query_data.constraints = item; 

        if( rpn_tail != NULL )
        	rpn_tail->next = item;
	rpn_tail = item;

#ifdef RDFSTORE_BRQL_PARSER_DEBUG
	printf("rpn => %s\n",item->value.textual.value);
#endif
	};

%}

%union {
	rdfstore_brql_list * list;
}

%token COMMA SELECT SOURCE WHERE USING FOR SUCHTHAT SC_OR SC_AND STR_EQ STR_NE
%token STR_MATCH STR_NMATCH PATTERNLITERAL BIT_OR BIT_XOR BIT_AND EQ NEQ LT GT LE GE LSHIFT RSIGNEDSHIFT RUNSIGNEDSHIFT PLUS MINUS
%token STAR SLASH REM TILDE BANG LPAREN RPAREN VARIABLE URI QNAME IDENTIFIER
%token LITERAL_INT LITERAL_HEX LITERAL_BOOLEAN LITERAL_NULL LITERAL_STRING LITERAL_DOUBLE LITERAL_PATTERN CONSTRAINT NODE
%token EOQ

%%

query		: SELECT variables sources WHERE triple_pattern_list constraints namespaces
		{
			rdfstore_brql_list_free($1.list);
			rdfstore_brql_list_free($4.list);

			query_data.resultvars = $2.list;
			query_data.sources = $3.list;
			query_data.triple_patterns = $5.list; /* list of lists */
		}
		;

variables	: VARIABLE commaopt variables
		{ $$.list = $1.list; $1.list->next = $3.list; }
		| VARIABLE
		| STAR
		;

commaopt	: COMMA
		| /* or nothing */
		;

sources		: SOURCE uri_list
		{ rdfstore_brql_list_free($1.list); $$.list = $2.list; }
		| /* empty */
		{ $$.list = NULL; }
		;

uri_list	: URI commaopt uri_list
		{ $$.list = $1.list; $1.list->next = $3.list; }
		| URI
		;

triple_pattern_list	: triple_pattern commaopt triple_pattern_list
			{ $$.list = rdfstore_brql_list_new_list( $1.list ); $$.list->next = $3.list; }
			| triple_pattern
			{ $$.list = rdfstore_brql_list_new_list( $1.list ); }
			;

triple_pattern	: LPAREN node commaopt node commaopt node_or_literal RPAREN
		{ $2.list->next = $4.list; $4.list->next = $6.list; $$.list = $2.list; }
		| LPAREN node commaopt node commaopt node_or_literal commaopt node RPAREN /* context as 4th component */
		{ $2.list->next = $4.list; $4.list->next = $6.list; $6.list->next = $8.list; $$.list = $2.list; }
		;

simple_or_of_nodes	: URI commaopt simple_or_of_nodes
			{ $$.list = $1.list; $1.list->next = $3.list; }
			| QNAME commaopt simple_or_of_nodes
			{ $$.list = $1.list; $1.list->next = $3.list; }
			| URI
			| QNAME
			;

simple_or_of_nodes_or_literals	: URI commaopt simple_or_of_nodes
				{ $$.list = $1.list; $1.list->next = $3.list; }
				| QNAME commaopt simple_or_of_nodes
				{ $$.list = $1.list; $1.list->next = $3.list; }
				| literal commaopt simple_or_of_nodes
				{ $$.list = $1.list; $1.list->next = $3.list; }
				| URI
				| QNAME
				| literal
				;

node		: VARIABLE
		| QNAME
		| URI
		| LPAREN simple_or_of_nodes RPAREN
		{ $$.list = rdfstore_brql_list_new_list( $2.list ); }
		;

node_or_literal	: VARIABLE
		| QNAME
		| URI
		| literal
		| literal_pattern
		| LPAREN simple_or_of_nodes_or_literals RPAREN
		{ $$.list = rdfstore_brql_list_new_list( $2.list ); }
		;

identifier	: IDENTIFIER
		| SELECT
		| SOURCE
		| WHERE
		| SUCHTHAT
		| USING
		| FOR
		| STR_EQ
		{ $1.list->type = IDENTIFIER; /* need to cast to identifier */ ; $$.list = $1.list; }
		| STR_NE
		{ $1.list->type = IDENTIFIER; /* need to cast to identifier */ ; $$.list = $1.list; }
		| STR_MATCH
		{ $1.list->type = IDENTIFIER; /* need to cast to identifier */ ; $$.list = $1.list; }
		;

literal_pattern	: LITERAL_PATTERN
		;

literal	: LITERAL_STRING
	| LITERAL_INT
	| LITERAL_DOUBLE 
	| LITERAL_HEX
	| LITERAL_BOOLEAN
	| LITERAL_NULL
	;

constraints	: SUCHTHAT constraints_expression
		{ rdfstore_brql_list_free($1.list); }
		| /* empty */
		;

constraints_expression	: expression COMMA constraints_expression
			| expression SUCHTHAT constraints_expression
			{ rdfstore_brql_list_free($2.list); }
			| expression
			;

expression	: conditionalorexpression_list
		;

conditionalorexpression_list	: conditionalorexpression_list SC_OR conditionalandexpression_list
				{ add_to_rpn( $2.list ); }
				| conditionalandexpression_list
				;

conditionalandexpression_list	: conditionalandexpression_list SC_AND stringequalityexpression_list
				{ add_to_rpn( $2.list ); }
				| stringequalityexpression_list
				;

stringequalityexpression_list	: stringequalityexpression_list STR_EQ inclusiveorexpression_list
				{ add_to_rpn( $2.list ); }
				| stringequalityexpression_list STR_NE inclusiveorexpression_list
				{ add_to_rpn( $2.list ); }
				| inclusiveorexpression_list STR_MATCH PATTERNLITERAL
				{ add_to_rpn( $3.list ); add_to_rpn( $2.list ); }
				| inclusiveorexpression_list STR_NMATCH PATTERNLITERAL
				{ add_to_rpn( $3.list ); add_to_rpn( $2.list ); }
				| inclusiveorexpression_list
				;

inclusiveorexpression_list	: inclusiveorexpression_list BIT_OR exclusiveorexpression_list
				{ add_to_rpn( $2.list ); }
				| exclusiveorexpression_list
				;

exclusiveorexpression_list	: exclusiveorexpression_list BIT_XOR andexpression_list
				{ add_to_rpn( $2.list ); }
				| andexpression_list
				;

andexpression_list	: andexpression_list BIT_AND equalityexpression_list
			{ add_to_rpn( $2.list ); }
			| equalityexpression_list
			;

equalityexpression_list	: equalityexpression_list EQ relationalexpression_list
			{ add_to_rpn( $2.list ); }
			| equalityexpression_list NEQ relationalexpression_list
			{ add_to_rpn( $2.list ); }
			| relationalexpression_list
			;

relationalexpression_list	: relationalexpression_list LT shiftexpression_list
				{ add_to_rpn( $2.list ); }
				| relationalexpression_list GT shiftexpression_list
				{ add_to_rpn( $2.list ); }
				| relationalexpression_list LE shiftexpression_list
				{ add_to_rpn( $2.list ); }
				| relationalexpression_list GE shiftexpression_list
				{ add_to_rpn( $2.list ); }
				| shiftexpression_list
				;

shiftexpression_list	: shiftexpression_list LSHIFT additiveexpression_list
			{ add_to_rpn( $2.list ); }
			| shiftexpression_list RSIGNEDSHIFT additiveexpression_list
			{ add_to_rpn( $2.list ); }
			| shiftexpression_list RUNSIGNEDSHIFT additiveexpression_list
			{ add_to_rpn( $2.list ); }
			| additiveexpression_list
			;

additiveexpression_list	: additiveexpression_list PLUS multiplicativeexpression_list
			{ add_to_rpn( $2.list ); }
			| additiveexpression_list MINUS multiplicativeexpression_list
			{ add_to_rpn( $2.list ); }
			| multiplicativeexpression_list
			;

multiplicativeexpression_list	: multiplicativeexpression_list STAR unaryexpression_list
				{ add_to_rpn( $2.list ); }
				| multiplicativeexpression_list SLASH unaryexpression_list
				{ add_to_rpn( $2.list ); }
				| multiplicativeexpression_list REM unaryexpression_list
				{ add_to_rpn( $2.list ); }
				| unaryexpression_list
				;

unaryexpression_list	: PLUS unaryexpression_list
			{ add_to_rpn( $1.list ); }
			| MINUS unaryexpression_list
			{ add_to_rpn( $1.list ); }
			| unaryexpressionnotplusminus
			;

unaryexpressionnotplusminus	: TILDE unaryexpression_list
				{ add_to_rpn( $1.list ); }
				| BANG unaryexpression_list
				{ add_to_rpn( $1.list ); }
				| primaryexpression
				;

primaryexpression	: VARIABLE
			{ add_to_rpn( $1.list ); }
			| URI
			{ add_to_rpn( $1.list ); }
			| literal
			{ add_to_rpn( $1.list ); }
			| LPAREN expression RPAREN
			| identifier LPAREN arglist RPAREN
			{ add_to_rpn( $1.list ); }
			;

arglist	: node_or_literal COMMA arglist
	| node_or_literal
	{ add_to_rpn( $1.list ); }
	;

namespaces	: USING prefixes_list
		{ rdfstore_brql_list_free($1.list); }
		| /* empty */
		;

prefixes_list	: prefixes_def commaopt prefixes_list
		| prefixes_def
		;

prefixes_def	: identifier FOR URI
		{
		DBT prefix, namespace;

		rdfstore_brql_list_free($2.list);

		/* we keep prefixes and relative namespaces into a hashtable for easy lookup if needed by the application */
		memset(&prefix, 0, sizeof(prefix));
		memset(&namespace, 0, sizeof(namespace));
		
		prefix.data = $1.list->value.textual.value;
		prefix.size = strlen($1.list->value.textual.value) + 1;

		namespace.data = $3.list->value.textual.value;
		namespace.size = strlen($3.list->value.textual.value) + 1;

		if ( query_data.prefixes == NULL )
			rdfstore_flat_store_open( 0, 0, & query_data.prefixes, NULL, NULL, (unsigned int)(32 * 1024), NULL, 0, NULL, NULL, NULL, NULL );			

		rdfstore_flat_store_store(query_data.prefixes, prefix, namespace);

		rdfstore_brql_list_free($1.list);
		rdfstore_brql_list_free($3.list);
		}
		;

%%

#ifdef STANDALONE
#include <stdio.h>
#include <locale.h>

int
main(int argc, char *argv[]) {
	char query_string[RDFSTORE_BRQL_FILE_BUF_SIZE];
	rdfstore_brql_query query; /* static */
	FILE *fh;
	int status;
	unsigned char *filename=NULL;
	char *y_err_str = NULL;
	void *bs;

	if(argc > 1) {
		filename=argv[1];
		fh = fopen(argv[1], "r");
		if(!fh) {
			fprintf(stderr, "%s: Cannot open file %s - %s\n", argv[0], filename, strerror(errno));
			exit(1);
			};
	} else {
		filename="<stdin>";
		fh = stdin;
		};

	memset(query_string, 0, RDFSTORE_BRQL_FILE_BUF_SIZE);
	fread(query_string, RDFSTORE_BRQL_FILE_BUF_SIZE, 1, fh);

	if(argc>1)
		fclose(fh);

	memset(&query, 0, sizeof(rdfstore_brql_query));

	/* pthread_mutex_lock(&yacc_m); */
	/* XXX start of un-threadsafe code */
	y_err_str = NULL;
        bs = yy_scan_string(query_string);
        yy_switch_to_buffer(bs);
        status = yyparse();

	memcpy(&query, &query_data, sizeof(query));
        if (y_err_str) {
                yyerror(y_err_str);
		return -1;
		}
	/* XXX end of un-threadsafe code */
	/* pthread_mutex_unlock(&yacc_m); */

	return status;
	};

#endif
