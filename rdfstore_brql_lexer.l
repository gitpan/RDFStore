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

/*

 RDQL lexer as specified for Jena2 by Andy Seaborne see the following:

        http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/~checkout~/jena/jena2/src/com/hp/hpl/jena/rdql/parser/rdql.jjt

	http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/

	http://www.w3.org/2004/07/08-BRQL/

	http://cvs.sourceforge.net/viewcvs.py/jena/BRQL/

*/

/* Never interactive */
/*  No isatty() check */
%option never-interactive

/* Batch scanner */
%option batch

/* Never use yyunput */
%option nounput

%x STR_PATT

%{

#include <string.h>

#define _LEX_C_
#include "lex.h"
#include "rdfstore_log.h"
#include "rdfstore_utf8.h"
#include "rdfstore_brql.h"
#include "y.tab.h"

unsigned char * preprocess_string( const unsigned char *literal, int len, int * out_len );
void matchandeat_singlelinecomment();
void matchandeat_blockcomment();
void yyerror(char *s);

char y_err_str[RDFSTORE_BRQL_ERROR_STRING_SIZE];
int c;

%}

LANGUAGETOKEN [A-Za-z][A-Za-z0-9-]*
PREFIX [[:alpha:]][[:alnum:]]*
NAME [[:alpha:]][[:alnum:]_$\.]*
QN [[:alpha:]][[:alnum:]]*:[[:alpha:]][-[:alnum:]_]*
QUOTEDURI \<[A-Za-z][^> ]+\>
LIT1 '([^'\\\n\r]|\\[^\n\r])*'(@{LANGUAGETOKEN})?(^^({QUOTEDURI}|{QN}))?
LIT2 \"([^"\\\n\r]|\\[^\n\r])*\"(@{LANGUAGETOKEN})?(^^({QUOTEDURI}|{QN}))?

%%

[\r\n]+        	{ lineno++; }
[ \t\f\v]+	{} /* skip them */

"//"      	{ matchandeat_singlelinecomment(); }
"\#"      	{ matchandeat_singlelinecomment(); }
"/*"      	{ matchandeat_blockcomment(); }

"select"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return SELECT; }
"from"     	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return SOURCE; }
"source"     	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return SOURCE; }
"where"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return WHERE; }
"using"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return USING; }
"for"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return FOR; }
"and"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return SUCHTHAT; }

","	  	{ return COMMA; }
"("       	{ return LPAREN; }
")"       	{ return RPAREN; }

\?{NAME}	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_VARIABLE, yytext, yyleng ); return VARIABLE; }

"||"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_OR, yytext, yyleng ); return SC_OR; }
"&&"    	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_AND, yytext, yyleng ); return SC_AND; }
"eq"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_STR_EQ, yytext, yyleng ); return STR_EQ; }
"ne"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_STR_NEQ, yytext, yyleng ); return STR_NE; }

("=~"|"~~"|"like")	{ BEGIN(STR_PATT); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_STR_MATCH, yytext, yyleng ); return STR_MATCH; }
"!~"			{ BEGIN(STR_PATT); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_STR_NMATCH, yytext, yyleng ); return STR_NMATCH; }

<STR_PATT>[\r\n]+         { lineno++; }
<STR_PATT>[ \t\f\v]+      {} /* skip them */
<STR_PATT>. { yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_LITERAL, yytext, yyleng ); BEGIN(0); return PATTERNLITERAL; }; /* pattern language is: [m]/pattern/[i][m][s][x] where '/' can be replaced with '!' if necessary */

"|"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_BIT_OR, yytext, yyleng ); return BIT_OR; }
"&"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_BIT_AND, yytext, yyleng ); return BIT_AND; }
"^"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_BIT_XOR, yytext, yyleng ); return BIT_XOR; }
"=="		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_EQ, yytext, yyleng ); return EQ; }
"!="		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_NEQ, yytext, yyleng ); return NEQ; }
"<"/[^<A-Za-z=]	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_LT, yytext, yyleng ); return LT; }
">"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_GT, yytext, yyleng ); return GT; }
"<="		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_LE, yytext, yyleng ); return LE; }
">="		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_GE, yytext, yyleng ); return GE; }
"<<"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_LSHIFT, yytext, yyleng ); return LSHIFT; }
">>"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_RSIGNEDSHIFT, yytext, yyleng ); return RSIGNEDSHIFT; }
">>>"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_RUNSIGNEDSHIFT, yytext, yyleng ); return RUNSIGNEDSHIFT; }

"+"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_PLUS, yytext, yyleng ); return PLUS; }
"-"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_MINUS, yytext, yyleng ); return MINUS; }
"*"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_STAR, yytext, yyleng ); return STAR; }
"/"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_SLASH, yytext, yyleng ); return SLASH; }
"%"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_REM, yytext, yyleng ); return REM; }
"~"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_TILDE, yytext, yyleng ); return TILDE; }
"!"		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_EXPR_BANG, yytext, yyleng ); return BANG; }

[0-9]+["lL"]?	{ c=yytext[yyleng-1]; if (c== 'l' || c == 'L') yytext[yyleng-1]='\0'; yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_INTEGER, yytext, yyleng-1 ); return LITERAL_INT; }
0[xX][0-9a-fA-F]+	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_HEX_INTEGER, yytext, yyleng ); return LITERAL_HEX; }
(([0-9]+\.[0-9]*([eE][+-]?[0-9]+)?[fFdD]?)|(\.[0-9]+([eE][+-]?[0-9]+)?[fFdD]?)|([0-9]+[eE][+-]?[0-9]+[fFdD]?)|([0-9]+([eE][+-]?[0-9]+)?[fFdD]))	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_FLOATING, yytext, yyleng ); return LITERAL_DOUBLE; }

("true"|"false")	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_BOOLEAN, yytext, yyleng ); return LITERAL_BOOLEAN; }
"null"	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_NULL, yytext, yyleng ); return LITERAL_NULL; }

{LIT1}	{ int ll=0; unsigned char * pp=preprocess_string( yytext, yyleng, &ll ); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_STRING, pp, ll ); RDFSTORE_FREE(pp); return LITERAL_STRING; }
{LIT2}	{ int ll=0; unsigned char * pp=preprocess_string( yytext, yyleng, &ll ); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_STRING, pp, ll ); RDFSTORE_FREE(pp); return LITERAL_STRING; }

%'([^'\\\n\r]|\\[^\n\r])+'%	{ int ll=0; unsigned char * pp=preprocess_string( yytext+2, yyleng-4, &ll ); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_PATTERN, pp, ll ); RDFSTORE_FREE(pp); return LITERAL_PATTERN; }
%\"([^"\\\n\r]|\\[^\n\r])+\"%	{ int ll=0; unsigned char * pp=preprocess_string( yytext+2, yyleng-4, &ll ); yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_PATTERN, pp, ll ); RDFSTORE_FREE(pp); return LITERAL_PATTERN; }

{NAME}		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_IDENTIFIER, yytext, yyleng ); return IDENTIFIER; }

{QN}		{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_QNAME, yytext, yyleng ); return QNAME; }

\<{QN}\>	{ yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_QNAME, yytext+1, yyleng-2 ); return QNAME; }

{QUOTEDURI}	{ yytext[yyleng-1]='\0'; yylval.list = rdfstore_brql_list_new( RDFSTORE_BRQL_URI, yytext+1, yyleng-2 ); return URI; }

.               { if (*yytext == EOF) {
			return EOQ;
			};
		  yyerror("Bad character");
                }

%%

void yyerror(char *s) {
	sprintf( y_err_str, "Parse error: %s, line %d at %s\n",s, lineno, yytext );
	};

unsigned char * preprocess_string(
	const unsigned char *literal,
	int len,
	int * out_len ) {
	unsigned int i;
	const unsigned char *s;
	unsigned char *d;
	unsigned int ucl=0;
	unsigned char * processed_literal=NULL;

	processed_literal=(unsigned char *)RDFSTORE_MALLOC( (len+1) * sizeof( unsigned char) * RDFSTORE_UTF8_MAXLEN );

	if ( processed_literal == NULL )
		return NULL;

	for(s=literal, d=processed_literal, i=0; i < len ; s++, i++) {
		unsigned char c=*s;

		if( c == '\\' ) {
			s++; i++;
			c=*s;
			if( c == 'n') {
				*d++= '\n';
			} else if( c == 'r') {
				*d++= '\r';
			} else if( c == 't') {
				*d++= '\t';
			} else if( c == '\\' ) {
				*d++=c;
			} else if ( c == 'u' || c == 'U') {
				int ulen = ( c == 'u') ? 4 : 8;
				unsigned long uc = 0;
				s++; i++;
				if( i+ulen > len ) {
					printf("\\%c over end of line", c);
					RDFSTORE_FREE(processed_literal);
					return NULL;
					};

				sscanf((const char*)s, ((ulen == 4) ? "%04lx" : "%08lx"), &uc);
				s+= ulen-1;
				i+= ulen-1;

				if(	( uc < 0 ) ||
					( uc > 0x10ffff ) ) {
					sprintf( y_err_str, "Illegal Unicode character with code point #x%lX.", uc);
					RDFSTORE_FREE(processed_literal);
					return NULL;
					};

				if ( rdfstore_utf8_cp_to_utf8(uc, &ucl, d) ) {
					RDFSTORE_FREE(processed_literal);
					return NULL;
					};
				d+=ucl;
			} else {
				fprintf(stderr, "Unknown string escape \\%c in \"%s\"", c, literal);
				*d++=c;
				};
		} else {
			*d++=c;
			};
		};

	*out_len = (d - processed_literal);

	*d='\0';

	return processed_literal;
	};

void matchandeat_singlelinecomment()  {
	char c;

	while ((c = input()) != '\n' && c != 0);

	lineno++;
	};

void matchandeat_blockcomment()  {
	char c1, c2 = '\0';

	while (	(c1 = input()) &&
		(c1 != EOF) ) {
        	if (c1 == '\n') {
            		lineno++;
        		};
		if (c2 == '*' && c1 == '/')
			break;
		c2 = c1;
		};
	};
