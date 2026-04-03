%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
%}

%option noyywrap

%%

[0-9A-Z]+ {
    yylval.nb = atoi(yytext);
    return INTEGER;
}
[ \t]+ ;
\n {return NEWLINE;}
.   ;

%%