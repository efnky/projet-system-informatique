%{
#include <stdio.h>
%}

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
{digit}+    { return tINTEGER;}
{letter}({letter}|{digit}|_)*         {return tID; }

"+"         { return tPLUS; }
"-"         { return tMINUS; }
"*"         { return tMUL; }
"/"         { return tDIV; }
"="         { return tASSIGN; }

";"         { return tSEMICOLON; }
","         { return tCOMMA; }

[ \t]+	    {}
\n          { return tNEWLINE; }

.           { printf("ERROR: unknown symbol '%s'\n", yytext); }
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}
