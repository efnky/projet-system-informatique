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

// instruction buffer new

#define MAX_INSTR 10000

typedef struct {
    char clear[256];   /* human-readable  e.g.  "JMF 101 7"  */
    char coded[256];   /* numeric         e.g.  "8 101 7"     */
} Instr;

Instr program[MAX_INSTR];
int   instr_count = 0;

// while loop: new
#define MAX_NESTING 32

typedef struct {
    int loop_start;   /* instruction index where condition begins     */
    int jmf_index;    /* instruction index of the JMF (backpatched)   */
    int cond_addr;    /* memory address of the boolean result         */
} WhileCtx;

WhileCtx while_stack[MAX_NESTING];
int      while_sp = 0;


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
    int addr = temp_next_address;
    temp_next_address++;
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

int add_instruction(const char *instClear, const char *instCoded) {
        if (instr_count >= MAX_INSTR) {
                printf("Error: program too large.\n");
                exit(1);
        }
        strcpy(program[instr_count].clear, instClear);
        strcpy(program[instr_count].coded, instCoded);
        return instr_count++;
}

void flush_program() {
        for (int i = 0; i < instr_count; i++) {
                fprintf(clear, "%s\n", program[i].clear);
                fprintf(coded, "%s\n", program[i].coded);
        }
}

int yylex(void);
void yyerror(const char *s);
%}

%union { int nb; char *str; }
%token tMAIN tPRINTF tLBRACE tRBRACE tLPAREN tRPAREN 
%token tCONST tINT 
%token tIF tELSE tWHILE  
%token tPLUS tMINUS tMUL tDIV tASSIGN 
%token tSEMICOLON tCOMMA tNEWLINE tERROR
%token tLT tGT tEQEQ tNEQ
%token <nb> INTEGER
%token <str> tID

%left tLT tGT tEQEQ tNEQ
%left tPLUS tMINUS
%left tMUL tDIV

%type <nb> expr

%%
/*
PROGRAM
*/
program:
    tMAIN tLPAREN tRPAREN tLBRACE declarations statements tRBRACE
;

/*
DECLARATION
*/
declarations:
    | declarations declaration tSEMICOLON
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
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $3);
                snprintf(bd, 256, "%d %d %d", COP, addr, $3);
                add_instruction(bc, bd);
        }
        ;

const_list: decl_item_const 
        | const_list tCOMMA decl_item_const
        ;

decl_item_const: tID tASSIGN expr 
        {       
                int addr = add_symbol($1, 1);
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $3);
                snprintf(bd, 256, "%d %d %d", COP, addr, $3);
                add_instruction(bc, bd);
        }
        ;

/*
STATEMENTS
*/
statements:
        | statements statement
;

statement:
        assignment tSEMICOLON { reset_temp_zone(); }
        | print tSEMICOLON { reset_temp_zone(); }
        | while 
        ;

/*
ASSIGNMENTS
*/
assignment: tID tASSIGN expr
        { 
                int addr = get_address($1);

                if (is_constant($1)) {
                printf("Error: cannot assign to constant '%s'\n", $1);
                exit(1);
                }

                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $3);
                snprintf(bd, 256, "%d %d %d", COP, addr, $3);
                add_instruction(bc, bd);
                printf("Assigned expression result to %s at address %d\n", $1, addr);
        }
        ;

/*
EXPRESSIONS
*/
expr: expr tPLUS expr   
        { 
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "ADD %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", ADD, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
        }
        | expr tMINUS expr  
        { 
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "SOU %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", SOU, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
        }
        | expr tMUL expr    
        { 
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "MUL %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", MUL, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
        }
        | expr tDIV expr    
        { 
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "DIV %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", DIV, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
        }
        | tLPAREN expr tRPAREN  
        { 
                $$ = $2;
        }
        | expr tLT expr
        {
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "INF %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", INF, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
                printf("Compared values with less than.\n");
        }
        | expr tGT expr
        {
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "SUP %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", SUP, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
                printf("Compared values with greater than.\n");
        }
        | expr tEQEQ expr
        {
                int res = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "EQU %d %d %d", res, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", EQU, res, $1, $3);
                add_instruction(bc, bd);
                $$ = res;
                printf("Compared values with equal to.\n");
        }
        | expr tNEQ expr
        {
                int res = new_temp();
                int tmp1 = new_temp();
                int tmp2 = new_temp();
                char bc[256], bd[256];

                snprintf(bc, 256, "AFC %d 1", tmp1);
                snprintf(bd, 256, "%d %d 1", AFC, tmp1);
                add_instruction(bc, bd);

                snprintf(bc, 256, "EQU %d %d %d", tmp2, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", EQU, tmp2, $1, $3);
                add_instruction(bc, bd);

                snprintf(bc, 256, "SOU %d %d %d", res, tmp1, tmp2);
                snprintf(bd, 256, "%d %d %d %d", SOU, res, tmp1, tmp2);
                add_instruction(bc, bd);

                $$ = res;
                printf("Compared values with not equal.\n");
        }
        | INTEGER 
        {
                int temp = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "AFC %d %d", temp, $1);
                snprintf(bd, 256, "%d %d %d", AFC, temp, $1);
                add_instruction(bc, bd);
                $$ = temp;
        }
        | tID
        {
                $$ = get_address($1);
        }
        ;  

/*
WHILE CONDITION
*/ 
while: tWHILE tLPAREN expr tRPAREN inside_while { reset_temp_zone(); }
        ;

inside_while: tLBRACE declarations statements tRBRACE 
        {

        }
        ;

/*
PRINT
*/
print: tPRINTF tLPAREN expr tRPAREN 
        {
                char bc[256], bd[256];
                snprintf(bc, 256, "PRI %d", $3);
                snprintf(bd, 256, "%d %d", PRI, $3);
                add_instruction(bc, bd);
                printf("Generated PRI for address %d\n", $3);
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
        printf("Parsing finished\n");

        flush_program();

        fclose(clear);
        fclose(coded);
        return 0;
}

