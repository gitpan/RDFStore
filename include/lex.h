// lex.h: lexer defines & declarations

#ifndef _LEX_H_
#define _LEX_H_

#include <stdio.h>

#define YY_NO_UNPUT

#ifdef _LEX_C_
   int lineno = 1; // line number count; this will be used for error messages later
#else
   // Import some variables
   extern int lineno;
   extern FILE *yyin;  // the input stream

   int yylex();
   int yyparse();
   void *yy_scan_string(const char *str);
   void yy_switch_to_buffer(void *str);
#endif

#endif
