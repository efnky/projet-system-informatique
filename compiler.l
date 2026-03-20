%{
#include <stdio.h>
%}

digit   [0-9]
letter  [A-Za-z]

%%
"main"      { return MAIN; }
"printf"    { return PRINTF; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"("         { return LPAREN; }
")"         { return RPAREN; }

"const"     { return CONST; }
"int"       { return INT; }
{digit}+    { return INTEGER;}
{letter}({letter}|{digit}|_)*         {return ID; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }
"="         { return ASSIGN; }

";"         { return SEMICOLON; }
","         { return COMMA; }

[ \t]+	    {}
\n          { return NEWLINE; }

.           { printf("ERROR: unknown symbol '%s'\n", yytext); }
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}
