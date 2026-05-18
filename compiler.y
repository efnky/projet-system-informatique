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
#define LIND 0xD
#define SIND 0xE
#define CALL_OP 0xF
#define RET_OP 0x10

#define MAX_SYMBOLS 200
#define TEMP_BASE 150

#define MAX_INSTR 10000

#define MAX_NESTING 32
#define MAX_FUNCTIONS 50
#define MAX_PARAMS 10
#define MAX_ARGS 10

#define RETURN_ADDR 149

typedef struct {
        char name[50];
        int address;
        int isConst;
        int isPointer;
        int scope;
} Symbol;

typedef struct {
    char clear[256];
    char coded[256];
} Instr;

typedef struct {
    int loop_start;
    int jmf_index;
    int cond_addr;
} WhileCtx;

typedef struct {
    char name[50];
    int instr_addr;
    int num_params;
    int param_addrs[MAX_PARAMS];
    int has_return;
} Function;

int symbol_count = 0;
int next_free_address = 0;
int temp_next_address = TEMP_BASE;
Symbol symbol_table[MAX_SYMBOLS];

Instr program[MAX_INSTR];
int   instr_count = 0;

WhileCtx while_stack[MAX_NESTING];
int      while_sp = 0;

Function func_table[MAX_FUNCTIONS];
int func_count = 0;

int current_scope = 0;

typedef struct {
    int args[MAX_ARGS];
    int count;
} ArgFrame;

ArgFrame arg_stack[MAX_NESTING];
int arg_sp = 0;

FILE *clear;
FILE *coded;

int add_symbol(const char *name, int isConst, int isPointer) {
        int addr = next_free_address;
        for (int i = 0; i < symbol_count; i++) {
                if (strcmp(symbol_table[i].name, name) == 0
                    && symbol_table[i].scope == current_scope) {
                        printf("Error: symbol '%s' already declared in this scope.\n", name);
                        exit(1);
                }
        }

        if (symbol_count >= MAX_SYMBOLS) {
                printf("Error: symbol table is full.\n");
                exit(1);
        }

        if (next_free_address >= RETURN_ADDR) {
                printf("Error: no more space for symbols.\n");
                exit(1);
        }

        strcpy(symbol_table[symbol_count].name, name);
        symbol_table[symbol_count].address = next_free_address;
        symbol_table[symbol_count].isConst = isConst;
        symbol_table[symbol_count].isPointer = isPointer;
        symbol_table[symbol_count].scope = current_scope;

        symbol_count++;
        next_free_address++;

        return addr;
}

int new_temp() {
    int addr = temp_next_address;
    temp_next_address++;
    return addr;
}

void reset_temp_zone() {
    temp_next_address = TEMP_BASE;
}

int get_address(const char *name) {
        for (int i = symbol_count - 1; i >= 0; i--) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].address;
                }
        }
        printf("Error: symbol '%s' not found.\n", name);
        exit(1);
}

int is_constant(const char *name) {
        for (int i = symbol_count - 1; i >= 0; i--) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].isConst;
                }
        }
        printf("Error: symbol '%s' not found.\n", name);
        exit(1);
}

void enter_scope() {
        current_scope++;
}

void leave_scope() {
        int i = symbol_count - 1;
        while (i >= 0 && symbol_table[i].scope == current_scope) {
                i--;
                symbol_count--;
        }
        current_scope--;
}

int add_function(const char *name, int has_return) {
        for (int i = 0; i < func_count; i++) {
                if (strcmp(func_table[i].name, name) == 0) {
                        printf("Error: function '%s' already defined.\n", name);
                        exit(1);
                }
        }
        strcpy(func_table[func_count].name, name);
        func_table[func_count].instr_addr = -1;
        func_table[func_count].num_params = 0;
        func_table[func_count].has_return = has_return;
        return func_count++;
}

Function* get_function(const char *name) {
        for (int i = 0; i < func_count; i++) {
                if (strcmp(func_table[i].name, name) == 0) {
                        return &func_table[i];
                }
        }
        printf("Error: function '%s' not found.\n", name);
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
%token tCONST tINT tVOID
%token tIF tELSE tWHILE tRETURN
%token tPLUS tMINUS tMUL tDIV tASSIGN 
%token tAMPERSAND
%token tSEMICOLON tCOMMA tNEWLINE tERROR
%token tLT tGT tEQEQ tNEQ
%token <nb> INTEGER
%token <str> tID

%left tLT tGT tEQEQ tNEQ
%left tPLUS tMINUS
%left tMUL tDIV
%right UDEREF UADDR

%type <nb> expr func_call

%%
/*
PROGRAM: function definitions then main
*/
program:
    func_defs tMAIN tLPAREN tRPAREN tLBRACE declarations statements tRBRACE
;

func_defs:
    | func_defs func_def
;

/*
FUNCTION DEFINITIONS
*/
func_def:
    tINT tID tLPAREN
        {
                int idx = add_function($2, 1);
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP ???");
                snprintf(bd, 256, "%d ???", JMP);
                int jmp_idx = add_instruction(bc, bd);
                func_table[idx].instr_addr = jmp_idx;
                enter_scope();
        }
    param_list tRPAREN tLBRACE declarations statements return_stmt tSEMICOLON tRBRACE
        {
                leave_scope();
                Function *f = get_function($2);
                int jmp_over = f->instr_addr;
                snprintf(program[jmp_over].clear, 256, "JMP %d", instr_count);
                snprintf(program[jmp_over].coded, 256, "%d %d", JMP, instr_count);
                f->instr_addr = jmp_over + 1;
                printf("Function '%s' defined (%d params)\n", $2, f->num_params);
        }
    | tVOID tID tLPAREN
        {
                int idx = add_function($2, 0);
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP ???");
                snprintf(bd, 256, "%d ???", JMP);
                int jmp_idx = add_instruction(bc, bd);
                func_table[idx].instr_addr = jmp_idx;
                enter_scope();
        }
    param_list tRPAREN tLBRACE declarations statements tRBRACE
        {
                char bc[256], bd[256];
                snprintf(bc, 256, "RET");
                snprintf(bd, 256, "%d", RET_OP);
                add_instruction(bc, bd);

                leave_scope();
                Function *f = get_function($2);
                int jmp_over = f->instr_addr;
                snprintf(program[jmp_over].clear, 256, "JMP %d", instr_count);
                snprintf(program[jmp_over].coded, 256, "%d %d", JMP, instr_count);
                f->instr_addr = jmp_over + 1;
                printf("Void function '%s' defined (%d params)\n", $2, f->num_params);
        }
;

param_list:
    | param_list_items
;

param_list_items:
    tINT tID
        {
                int addr = add_symbol($2, 0, 0);
                Function *f = &func_table[func_count - 1];
                f->param_addrs[f->num_params] = addr;
                f->num_params++;
        }
    | param_list_items tCOMMA tINT tID
        {
                int addr = add_symbol($4, 0, 0);
                Function *f = &func_table[func_count - 1];
                f->param_addrs[f->num_params] = addr;
                f->num_params++;
        }
;

return_stmt:
    tRETURN expr
        {
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", RETURN_ADDR, $2);
                snprintf(bd, 256, "%d %d %d", COP, RETURN_ADDR, $2);
                add_instruction(bc, bd);

                snprintf(bc, 256, "RET");
                snprintf(bd, 256, "%d", RET_OP);
                add_instruction(bc, bd);
        }
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
        | tINT ptr_list
        {
                printf("declaring a pointer.\n");
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
                int addr = add_symbol($1, 0, 0);
                printf("Variable %s declared at address %d\n", $1, addr);
        }
        | tID tASSIGN expr 
        {
                int addr = add_symbol($1, 0, 0);
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $3);
                snprintf(bd, 256, "%d %d %d", COP, addr, $3);
                add_instruction(bc, bd);
        }
        ;

ptr_list: ptr_decl_item
        | ptr_list tCOMMA ptr_decl_item
        ;

ptr_decl_item: tMUL tID
        {
                int addr = add_symbol($2, 0, 1);
                printf("Pointer %s declared at address %d\n", $2, addr);
        }
        | tMUL tID tASSIGN expr
        {
                int addr = add_symbol($2, 0, 1);
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $4);
                snprintf(bd, 256, "%d %d %d", COP, addr, $4);
                add_instruction(bc, bd);
                printf("Pointer %s declared and initialized at address %d\n", $2, addr);
        }
        ;

const_list: decl_item_const 
        | const_list tCOMMA decl_item_const
        ;

decl_item_const: tID tASSIGN expr 
        {       
                int addr = add_symbol($1, 1, 0);
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
        | while { reset_temp_zone(); }
        | func_call tSEMICOLON { reset_temp_zone(); }
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
        | tMUL tID tASSIGN expr
        {
                int ptr_addr = get_address($2);
                char bc[256], bd[256];
                snprintf(bc, 256, "SIND %d %d", ptr_addr, $4);
                snprintf(bd, 256, "%d %d %d", SIND, ptr_addr, $4);
                add_instruction(bc, bd);
                printf("Dereference write through %s\n", $2);
        }
        ;

// ====================================
//             EXPRESSIONS
// ====================================
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
        | tAMPERSAND tID %prec UADDR 
        {
                int addr = get_address($2);
                int temp = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "AFC %d %d", temp, addr);
                snprintf(bd, 256, "%d %d %d", AFC, temp, addr);
                add_instruction(bc, bd);
                $$ = temp;
                printf("Address-of %s (address %d)\n", $2, addr);
        }
        | tMUL tID %prec UDEREF
        {
                int ptr_addr = get_address($2);
                int temp = new_temp();
                char bc[256], bd[256];
                snprintf(bc, 256, "LIND %d %d", temp, ptr_addr);
                snprintf(bd, 256, "%d %d %d", LIND, temp, ptr_addr);
                add_instruction(bc, bd);
                $$ = temp;
                printf("Dereference read of %s\n", $2);
        }
        | tID
        {
                $$ = get_address($1);
        }
        | func_call
        {
                $$ = $1;
        }
        ;  

// ====================================
//      WHILE CONDITION
// ====================================
while: tWHILE while_start tLPAREN expr tRPAREN while_cond tLBRACE statements tRBRACE 
        {
                // Put a JMP instruction at the end to jump back to the beginning of while
                WhileCtx ctx = while_stack[--while_sp];
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP %d", ctx.loop_start);
                snprintf(bd, 256, "%d %d", JMP, ctx.loop_start);
                add_instruction(bc, bd);
                
                // Replace the ??? with the next instruction after while condition
                snprintf(program[ctx.jmf_index].clear, 256, "JMF %d %d", ctx.cond_addr, instr_count);
                snprintf(program[ctx.jmf_index].coded, 256, "%d %d %d", JMF, ctx.cond_addr, instr_count);
        }
        ;

while_start: 
        {
                while_stack[while_sp].loop_start = instr_count;
        }
        ;

while_cond:
        {
                int cond_addr = $<nb>-1;

                char bc[256], bd[256];
                snprintf(bc, 256, "JMF %d ???", cond_addr);
                snprintf(bd, 256, "%d %d ???", JMF, cond_addr);
                int idx = add_instruction(bc, bd);

                while_stack[while_sp].jmf_index = idx;
                while_stack[while_sp].cond_addr = cond_addr;
                while_sp++;
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

/*
FUNCTION CALL
*/
func_call: tID tLPAREN
        {
                arg_stack[arg_sp].count = 0;
                arg_sp++;
        }
    arg_list tRPAREN
        {
                arg_sp--;
                ArgFrame *frame = &arg_stack[arg_sp];
                Function *f = get_function($1);

                if (frame->count != f->num_params) {
                        printf("Error: function '%s' expects %d args, got %d.\n",
                               $1, f->num_params, frame->count);
                        exit(1);
                }

                char bc[256], bd[256];
                for (int i = 0; i < frame->count; i++) {
                        snprintf(bc, 256, "COP %d %d", f->param_addrs[i], frame->args[i]);
                        snprintf(bd, 256, "%d %d %d", COP, f->param_addrs[i], frame->args[i]);
                        add_instruction(bc, bd);
                }

                snprintf(bc, 256, "CALL %d", f->instr_addr);
                snprintf(bd, 256, "%d %d", CALL_OP, f->instr_addr);
                add_instruction(bc, bd);

                int ret_temp = new_temp();
                snprintf(bc, 256, "COP %d %d", ret_temp, RETURN_ADDR);
                snprintf(bd, 256, "%d %d %d", COP, ret_temp, RETURN_ADDR);
                add_instruction(bc, bd);

                $$ = ret_temp;
        }
        ;

arg_list:
        | arg_list_items
        ;

arg_list_items:
        expr
        {
                ArgFrame *frame = &arg_stack[arg_sp - 1];
                frame->args[frame->count++] = $1;
        }
        | arg_list_items tCOMMA expr
        {
                ArgFrame *frame = &arg_stack[arg_sp - 1];
                frame->args[frame->count++] = $3;
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

