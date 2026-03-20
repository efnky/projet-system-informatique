%{
#include <stdlib.h>
#include <stdio.h>
#include "y.tab.h"
%}

%option noyywrap

%%

[ \t]+	{};
[0-9]+	{
	  yylval.nb = atoi(yytext);
	  return tNB;
	}
"="	{ return tEGAL; }
"-"	{ return tSOU; }
"+"	{ return tADD; }
"*"	{ return tMUL; }
"/"	{ return tDIV; }
"("	{ return tPO; }
")"	{ return tPF; }
[a-z]	{
	  yylval.var = yytext[0];
	  return tID;
	}
\n	{ return tFL; }
.	{ return tERROR; }


int([ \t]*({letter}({letter}|{digit}|_)*)[ \t]*[,])+[ \t]*({letter}({letter}|{digit}|_)*)       {printf(TOKEN: MULTIPLE_INT\n);}

printf[ \t]*\([ \t]*({letter}|{digit})*[ \t]*\) {
    printf("TOKEN: PRINTF (%s)\n", yytext);
}
printf[ \t]*\(.*\) {
    printf("ERROR: invalid printf usage (%s)\n", yytext);
}

{digit}+[eE][+-]?{digit}+       {printf("TOKEN: EXP = %s\n", yytext);}




{letter}({letter}|{digit}|_)*         { printf("TOKEN: ID = %s\n", yytext); }
{letter}({letter}|{digit}|_)*         { printf("TOKEN: ID = %s\n", yytext); }
