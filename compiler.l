%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
%}

%option noyywrap

digit   [0-9]
letter  [A-Za-z]

%%
"main"      { return tMAIN; }
"printf"    { return tPRINTF; }
"{"         { return tLBRACE; }
"}"         { return tRBRACE; }
"("         { return tLPAREN; }
")"         { return tRPAREN; }

"const"     { return tCONST; }
"int"       { return tINT; }

"if"        { return tIF; }
"else"      { return tELSE; }
"while"     { return tWHILE; }
"return"    { return tRETURN; }
"void"      { return tVOID; }

{digit}+    { yylval.nb = atoi(yytext); return INTEGER;}
{letter}({letter}|{digit}|_)*   {
    yylval.str = strdup(yytext);
    return tID;
}

"+"         { return tPLUS; }
"-"         { return tMINUS; }
"*"         { return tMUL; }
"/"         { return tDIV; }
"="         { return tASSIGN; }

"<"         { return tLT; }
">"         { return tGT; }
"=="        { return tEQEQ; }
"!="        { return tNEQ; }


"&"         { return tAMPERSAND; }

";"         { return tSEMICOLON; }
","         { return tCOMMA; }

[ \t]+	    {}
\n          {}

.           { return tERROR; }
%%
