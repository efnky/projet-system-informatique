%{
#include <stdio.h>
%}

digit   [0-9]
letter  [A-Za-z]

%%
"main"      { printf("MAIN\n"); }
"printf"    { printf("PRINTF\n"); }
"{"         { printf("LBRACE\n"); }
"}"         { printf("RBRACE\n"); }
"("         { printf("LPAREN\n"); }
")"         { printf("RPAREN\n"); }

"const"     { printf("CONST\n"); }
"int"       { printf("INT\n"); }
{digit}+    { printf("INTEGER = %s\n", yytext);}
{letter}({letter}|{digit}|_)*         { printf("ID = %s\n", yytext); }

"+"         { printf("PLUS\n"); }
"-"         { printf("MINUS\n"); }
"*"         { printf("MUL\n"); }
"/"         { printf("DIV\n"); }
"="         { printf("ASSIGN\n"); }

";"         { printf("SEMICOLON\n"); }
","         { printf("COMMA\n"); }

[ \t]+	    {}
\n          { printf("NEWLINE\n"); }

.           { printf("ERROR: unknown symbol '%s'\n", yytext); }
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}
