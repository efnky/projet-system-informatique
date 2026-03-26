%{
#include <stdio.h>
#include <stdlib.h>
int yylex(void);
void yyerror(const char *s);
%}

%union { int nb; char *str; }
%token tMAIN tPRINTF tLBRACE tRBRACE tLPAREN tRPAREN 
%token tCONST tINT 
%token tPLUS tMINUS tMUL tDIV tASSIGN 
%token tSEMICOLON tCOMMA tNEWLINE tERROR
%token <nb> INTEGER
%token <str> tID

%left tPLUS tMINUS
%left tMUL tDIV

%type <nb> expr

%%
program: tMAIN tLPAREN tRPAREN tLBRACE instructions tRBRACE tNEWLINE;

instructions: instruction 
        | instructions instruction
        ;

instruction: declaration tSEMICOLON
        | assignment tSEMICOLON
        | print tSEMICOLON
        ;

declaration: tINT id_list
        | tCONST tINT const_list
        ;

id_list: tID    // int x
        | tID tASSIGN expr  // int x = expr
        | id_list tCOMMA tID    // int x,y
        | id_list tCOMMA tID tASSIGN expr  // int x,y,z=expr
        ;

const_list: tID tASSIGN expr
        | const_list tCOMMA tID tASSIGN expr
        ;

assignment: tID tASSIGN expr;

print: tPRINTF tLPAREN tID tRPAREN
        | tPRINTF tLPAREN INTEGER tRPAREN;


expr: INTEGER   { $$ = $1; }
        | expr tPLUS expr   { $$ = $1 + $3; }
        | expr tMINUS expr  { $$ = $1 - $3; }
        | expr tMUL expr    { $$ = $1 * $3; }
        | expr tDIV expr    { $$ = $1 / $3; }
        | tLPAREN expr tRPAREN  { $$ = $2; }
        ;

%%
void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}

