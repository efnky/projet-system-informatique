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
#define INF 9
#define SUP 0xA
#define EQU 0xB
#define PRI 0xC

#define MAX_SYMBOLS 100
#define TEMP_BASE 101

typedef struct {
        char name[50];
        int address;
        int isConst;
} Symbol;

Symbol symbol_table[MAX_SYMBOLS];

int symbol_count = 0;
int next_free_address = 0;
int temp_next_address = TEMP_BASE;

FILE *clear;
FILE *coded;

int add_symbol(const char *name, int isConst) {
        int addr = next_free_address;
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

        if (next_free_address >= TEMP_BASE) {
                printf("Error: no more space in zone 1 for symbols.\n");
                exit(1);
        }       

        // Add the symbol into table
        strcpy(symbol_table[symbol_count].name, name);
        symbol_table[symbol_count].address = next_free_address;
        symbol_table[symbol_count].isConst = isConst;

        // Change the next available address
        symbol_count++;
        next_free_address++;

        return addr;
}

// Create a new available temporary memory address
int new_temp() {
    int addr = next_temp_address;
    next_temp_address++;
    return addr;
}

// Reset temporary memory when it is done
void reset_temp_zone() {
    temp_next_address = TEMP_BASE;
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
program:
    tMAIN tLPAREN tRPAREN tLBRACE declarations statements tRBRACE
;

declarations:
      /* empty */
    | declarations declaration tSEMICOLON
;

statements:
      /* empty */
    | statements statement
;

statement:
      assignment tSEMICOLON { reset_temp_zone(); }
    | print tSEMICOLON { reset_temp_zone(); }
;

declaration: tINT id_list 
        {
                printf("declaring an integer.\n");
                reset_temp_zone();
        }
        | tCONST tINT const_list 
        {
                printf("declaring a constant integer.\n");
                reset_temp_zone();
        }
        ;

id_list: decl_item
        | id_list tCOMMA decl_item
        ;

decl_item: tID 
        {
                int addr = add_symbol($1,0);
                printf("Variable %s declared at address %d\n", $1, addr);
        }
        | tID tASSIGN expr 
        {
                int addr = add_symbol($1, 0);
                fprintf(clear, "COP %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", COP, addr, $3);
        }
        ;

const_list: decl_item_const 
        | const_list tCOMMA decl_item_const
        ;

decl_item_const: tID tASSIGN expr 
        {       
                int addr = add_symbol($1, 1);
                fprintf(clear, "COP %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", COP, addr, $3);
        }
        ;

assignment: tID tASSIGN expr
        { 
                int addr = get_address($1);

                if (is_constant($1)) {
                printf("Error: cannot assign to constant '%s'\n", $1);
                exit(1);
                }

                fprintf(clear, "COP %d %d\n", addr, $3);
                fprintf(coded, "%d %d %d\n", COP, addr, $3);
                printf("Assigned expression result to %s at address %d\n", $1, addr);
        }
        ;

expr: expr tPLUS expr   
        { 
                int res = new_temp();
                fprintf(clear, "ADD %d %d %d\n", res, $1, $3);
                fprintf(coded, "%d %d %d %d\n", ADD, res, $1, $3);
                $$ = res;
        }
        | expr tMINUS expr  
        { 
                int res = new_temp();
                fprintf(clear, "SOU %d %d %d\n", res, $1, $3);
                fprintf(coded, "%d %d %d %d\n", SOU, res, $1, $3);
                $$ = res;
        }
        | expr tMUL expr    
        { 
                int res = new_temp();
                fprintf(clear, "MUL %d %d %d\n", res, $1, $3);
                fprintf(coded, "%d %d %d %d\n", MUL, res, $1, $3);
                $$ = res;
        }
        | expr tDIV expr    
        { 
                int res = new_temp();
                fprintf(clear, "DIV %d %d %d\n", res, $1, $3);
                fprintf(coded, "%d %d %d %d\n", DIV, res, $1, $3);
                $$ = res;
        }
        | tLPAREN expr tRPAREN  
        { 
                $$ = $2;
        }
        | INTEGER
        {
                int temp = new_temp();
                fprintf(clear, "AFC %d %d\n", temp, $1);
                fprintf(coded, "%d %d %d\n", AFC, temp, $1);
                $$ = temp;
        }
        | tID
        {
                $$ = get_address($1);
        }
        ;

print: tPRINTF tLPAREN expr tRPAREN 
        {
                fprintf(clear, "PRI %d\n", $3);
                fprintf(coded, "%d %d\n", PRI, $3);
        }
        ;

%%
void yyerror(const char *s) {
        fprintf(stderr, "%s\n", s);
}

int main(void) {
        clear = fopen("clear.asm", "w");
        coded = fopen("coded.asm", "w");

        if (!clear || !coded) {
                perror("fopen");
                return 1;
        }

        yyparse();

        fclose(clear);
        fclose(coded);
        return 0;
}

