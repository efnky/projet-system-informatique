%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ADD 1
#define MUL 2
#define SOU 3
#define DIV 4
#define COP 5
#define AFC 6
#define JMP 7
#define JMF 8

#define MAX_SYMBOLS 100

typedef struct {
        char name[50];
        int address;
        int isConst;
} Symbol;

Symbol symbol_table[MAX_SYMBOLS];
int symbol_count = 0;
int next_free_address = 0;

FILE *clear;
FILE *coded;

int add_symbol(const char *name, int isConst) {
        // Check if the name of the symbol already exists
        for (int i = 0; i < symbol_count; i++) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        printf("Error: symbol '%s' already declared.\n", name);
                        exit(1);
                }
        }

        // Check if the symbol table is full
        if (symbol_count >= MAX_SYMBOLS) {
                printf("Error: symbol table is full.\n");
                exit(1);
        }

        // Add the symbol into table
        strcpy(symbol_table[symbol_count].name, name);
        symbol_table[symbol_count].address = next_free_address;
        symbol_table[symbol_count].isConst = isConst;

        symbol_count++;
        next_free_address++;

        return next_free_address - 1;
}

int get_address(const char *name) {
        for (int i = 0; i < symbol_count; i++) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].address;
                }
        }
        printf("Error: symbol '%s' not found.\n", name);
        exit(1);
}

int is_constant(const char *name) {
        for (int i = 0; i < symbol_count; i++) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].isConst;
                }
        }
        printf("Error: symbol '%s' not found.\n", name);
        exit(1);
}

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
        {
                printf("declaring an integer.\n");
        }
        | tCONST tINT const_list 
        {
                printf("declaring a constant integer.\n");
        }
        ;

// int x; | int x = 5;
id_list: decl_item
        | id_list tCOMMA decl_item
        ;

decl_item: tID // int x;
        {
                int addr = add_symbol($1,0);
                printf("Variable %s declared at address %d\n", $1, addr);
        }
        | tID tASSIGN expr // int x = 5;
        {
                int addr = add_symbol($1, 0);
                fprintf(clear, "AFC %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", AFC, addr, $3);
                printf("Variable %s declared at address %d with value %d\n", $1, addr, $3);
        }
        ;

// const int x = 5;
const_list: decl_item_const // const int x, y, z = 4;
        | const_list tCOMMA decl_item_const
        ;

decl_item_const: tID tASSIGN expr 
        {       
                int addr = add_symbol($1, 1);
                fprintf(clear, "AFC %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", AFC, addr, $3);
                printf("Constant %s declared at address %d with value %d\n", $1, addr, $3);
        }
        ;

assignment: tID tASSIGN INTEGER 
        { 
                int addr = get_address($1);
                fprintf(clear, "AFC %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", AFC, addr, $3);
                printf("Number %d assignet to %s with the address %d\n", $3, $1, addr);
        }
        | tID tASSIGN tID 
        {
                int addr1 = get_address($1);
                int addr2 = get_address($3);
                fprintf(clear, "COP %d %d\n", addr1, addr2);
                fprintf(coded, "%d %d %d\n", COP, addr1, addr2);
                printf("Variable %s copied to variable %s\n", $3, $1);
        }
        | tID tASSIGN expr 
        ;

expr: expr tPLUS expr   
        { 
                
        }
        | expr tMINUS expr  { $$ = $1 - $3; }
        | expr tMUL expr    { $$ = $1 * $3; }
        | expr tDIV expr    { $$ = $1 / $3; }
        | tLPAREN expr tRPAREN  { $$ = $2; }
        ;

print: tPRINTF tLPAREN tID tRPAREN
        | tPRINTF tLPAREN INTEGER tRPAREN;

%%
void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}

