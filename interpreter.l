%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
%}

%option noyywrap

%%

[0-9A-Z]+ {yylval.nb = (int)strtol(yytext, NULL, 16);
                return INTEGER;}
[ \t]+ ;
\n {return NEWLINE;}
.   ;

%%