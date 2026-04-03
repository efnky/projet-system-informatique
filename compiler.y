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
#define NEQ 0xD

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


//if conditon  new

typedef struct {
    int jmf_index;    /* index of JMF at end of condition             */
    int jmp_index;    /* index of JMP at end of if-body (for else)    */
    int cond_addr;    /* memory address of the boolean result         */
    int has_else;     /* 1 if an else branch is present               */
} IfCtx;

IfCtx if_stack[MAX_NESTING];
int   if_sp = 0;

FILE *clear_file;
FILE *coded_file;

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
int new_temp(void) {
    return temp_next_address++;
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

static int emit(const char *c1, const char *co){
        if (instr_count >= MAX_INSTR){ fprintf(stderr,"programme est tres grand.\n");exit(1);}
        strncpy(program[instr_count].clear, cl, 255);
        strncpy(program[instr_count].coded, co, 255);
        return instr_count++

}

static void backpatch(int idx, int cond_addr, int target) {
    char cl[128], co[128];
    sprintf(cl, "JMF %d %d",      cond_addr, target);
    sprintf(co, "%d %d %d", JMF,  cond_addr, target);
    strncpy(program[idx].clear, cl, 255);
    strncpy(program[idx].coded, co, 255);
}

static int emit_afc(int dst, int val) {
    char cl[128], co[128];
    sprintf(cl, "AFC %d %d",      dst, val);
    sprintf(co, "%d %d %d", AFC,  dst, val);
    return emit(cl, co);
}

static int emit_afc(int dst, int val) {
    char cl[128], co[128];
    sprintf(cl, "AFC %d %d",      dst, val);
    sprintf(co, "%d %d %d", AFC,  dst, val);
    return emit(cl, co);
}
static int emit_cop(int dst, int src) {
    char cl[128], co[128];
    sprintf(cl, "COP %d %d",      dst, src);
    sprintf(co, "%d %d %d", COP,  dst, src);
    return emit(cl, co);
}
static int emit_add(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "ADD %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", ADD,   r, a, b);
    return emit(cl, co);
}
static int emit_sou(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "SOU %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", SOU,   r, a, b);
    return emit(cl, co);
}
static int emit_mul(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "MUL %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", MUL,   r, a, b);
    return emit(cl, co);
}
static int emit_div(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "DIV %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", DIV,   r, a, b);
    return emit(cl, co);
}
static int emit_inf(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "INF %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", INF,   r, a, b);
    return emit(cl, co);
}
static int emit_sup(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "SUP %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", SUP,   r, a, b);
    return emit(cl, co);
}
static int emit_equ(int r, int a, int b) {
    char cl[128], co[128];
    sprintf(cl, "EQU %d %d %d",       r, a, b);
    sprintf(co, "%d %d %d %d", EQU,   r, a, b);
    return emit(cl, co);
}

static int emit_neq(int a, int b) {
    int eq  = new_temp();
    int inv = new_temp();
    int one = new_temp();
    emit_equ(eq, a, b);
    emit_afc(one, 1);
    /* inv = 1 - eq */
    char cl[128], co[128];
    sprintf(cl, "SOU %d %d %d",       inv, one, eq);
    sprintf(co, "%d %d %d %d", SOU,   inv, one, eq);
    emit(cl, co);
    return inv;
}
static int emit_pri(int src) {
    char cl[128], co[128];
    sprintf(cl, "PRI %d",      src);
    sprintf(co, "%d %d", PRI,  src);
    return emit(cl, co);
}
static int emit_jmp(int target) {
    char cl[128], co[128];
    sprintf(cl, "JMP %d",      target);
    sprintf(co, "%d %d", JMP,  target);
    return emit(cl, co);
}
static int emit_jmf_placeholder(int cond_addr) {
    char cl[128], co[128];
    sprintf(cl, "JMF %d -1",      cond_addr);
    sprintf(co, "%d %d -1", JMF,  cond_addr);
    return emit(cl, co);
}
static int emit_jmp_placeholder(void) {
    return emit("JMP -1", "-1 -1");   /* target filled in by backpatch_jmp */
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

        fclose(clear);
        fclose(coded);
        return 0;
}

