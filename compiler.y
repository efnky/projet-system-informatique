%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// basic operations (codes)
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

// indirect load and store 
#define LOADI 0xD
#define STOREI 0xE

// save the return address, then jump to the function
#define CALL_OP 0xF

// return to the saved address
#define RET_OP 0x10

#define MAX_SYMBOLS 200
#define MAX_INSTR 10000
#define MAX_NESTING 32
#define MAX_FUNCTIONS 50
#define MAX_PARAMS 10
#define MAX_ARGS 10

// start point of the temporary addresses
#define TEMP_BASE 150

// return value from a function
#define RETURN_ADDR 149

// Symbol table
typedef struct {
        char name[50];
        int address;
        int isConst;
        int isPointer;
        int scope;   // depth
} Symbol;

// Instruction table
typedef struct {
    char clear[256]; // clear instruction, human-friendly visual (ex. ADD 105 0 1)
    char coded[256]; // coded instruction, machine-friendly (ex. 1 105 0 1)
} Instr;

// While Stack
typedef struct {
    int loop_start; // the beginning of the loop, where we jump
    int jmf_index; // where to jump after the end of the loop
    int cond_addr; // condition of the while loop
} WhileControl;

WhileControl while_stack[MAX_NESTING];
int      while_sp = 0;

// If/else Stack 
typedef struct {
    int jmf_index;
    int jmp_index;
    int cond_addr;
    int has_else;
} IfControl;

IfControl if_stack[MAX_NESTING];
int   if_sp = 0;

// Function Stack
typedef struct {
    char name[50];
    int instr_addr;
    int num_params;
    int param_addrs[MAX_PARAMS];
    int has_return;
} Function;

Function func_table[MAX_FUNCTIONS];
int func_count = 0;

// List of arguments of a function
typedef struct {
    int args[MAX_ARGS];
    int count;
} ArgFrame;

ArgFrame arg_stack[MAX_NESTING];
int arg_sp = 0;

// available addresses and informations on symbols
int symbol_count = 0;
int next_free_address = 0;
int temp_next_address = TEMP_BASE;
Symbol symbol_table[MAX_SYMBOLS];

// current scope of a symbol
int current_scope = 0;

// Create a list of instructions
Instr program[MAX_INSTR];
int   instr_count = 0;

FILE *clear;
FILE *coded;

// Error
extern int yylineno;
int nb_errors = 0;

// Print the message after detecting an error
void report_error(const char *msg) {
        fprintf(stderr, "Semantic error at line %d: %s\n", yylineno, msg);
        nb_errors++;
}

// Add new symbol to the list
int add_symbol(const char *name, int isConst, int isPointer) {
        int addr = next_free_address;
        for (int i = 0; i < symbol_count; i++) {

                // check if there is another symbol with the same name
                if (strcmp(symbol_table[i].name, name) == 0
                    && symbol_table[i].scope == current_scope) {
                        char buf[256];
                        snprintf(buf, 256, "symbol '%s' already declared in this scope", name);
                        report_error(buf);
                        return addr;
                }
        }

        // check if the there is enough place in the symbol table to put the new symbol
        if (symbol_count >= MAX_SYMBOLS) {
                report_error("symbol table is full");
                return addr;
        }

        // check if the next open address is in the usable address zone ([0-148])
        if (next_free_address >= RETURN_ADDR) {
                report_error("no more space for symbols");
                return addr;
        }

        // add the new symbol to the symbol_table
        strcpy(symbol_table[symbol_count].name, name);
        symbol_table[symbol_count].address = next_free_address;
        symbol_table[symbol_count].isConst = isConst;
        symbol_table[symbol_count].isPointer = isPointer;
        symbol_table[symbol_count].scope = current_scope;

        symbol_count++;
        next_free_address++;

        return addr;
}

// pass to the next temporary address
int new_temp() {
    int addr = temp_next_address;
    temp_next_address++;
    return addr;
}

// reset the temporay address index to the start
void reset_temp_zone() {
    temp_next_address = TEMP_BASE;
}

// Starting from the top of the stack, search the address of the symbol
int get_address(const char *name) {
        for (int i = symbol_count - 1; i >= 0; i--) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].address;
                }
        }

        char buf[256];
        snprintf(buf, 256, "symbol '%s' not found", name);
        report_error(buf);
        return 0;
}

// check the symbol if it is a constant from the stack of symbols
int is_constant(const char *name) {
        for (int i = symbol_count - 1; i >= 0; i--) {
                if (strcmp(symbol_table[i].name, name) == 0) {
                        return symbol_table[i].isConst;
                }
        }

        char buf[256];
        snprintf(buf, 256, "symbol '%s' not found", name);
        report_error(buf);
        return 0;
}

// increment the scope when the symbols are created inside a function
void enter_scope() {
        current_scope++;
}

// pop off the symbols after the end of a function
void leave_scope() {
        int i = symbol_count - 1;
        while (i >= 0 && symbol_table[i].scope == current_scope) {
                i--;
                symbol_count--;
        }
        current_scope--;
}

// add new function inside the function stack
int add_function(const char *name, int has_return) {

        // check for another function with the same name
        for (int i = 0; i < func_count; i++) {
                if (strcmp(func_table[i].name, name) == 0) {
                        char buf[256];
                        snprintf(buf, 256, "function '%s' already defined", name);
                        report_error(buf);
                        return i;
                }
        }

        strcpy(func_table[func_count].name, name);
        func_table[func_count].instr_addr = -1;
        func_table[func_count].num_params = 0;
        func_table[func_count].has_return = has_return;
        return func_count++;
}

// get function from the function stack using its name
Function* get_function(const char *name) {
        for (int i = 0; i < func_count; i++) {
                if (strcmp(func_table[i].name, name) == 0) {
                        return &func_table[i];
                }
        }
        char buf[256];
        snprintf(buf, 256, "function '%s' not found", name);
        report_error(buf);
        static Function dummy = { .name = "?", .instr_addr = 0, .num_params = 0, .has_return = 0 };
        return &dummy;
}

// add instructions to the instructions stack
int add_instruction(const char *instClear, const char *instCoded) {
        if (instr_count >= MAX_INSTR) {
                report_error("program too large");
                return instr_count - 1;
        }
        strcpy(program[instr_count].clear, instClear);
        strcpy(program[instr_count].coded, instCoded);
        return instr_count++;
}


// JMF to the instruction when the jump target is known
static void backpatch_jmf(int idx, int cond_addr, int target) {
    snprintf(program[idx].clear, 256, "JMF %d %d", cond_addr, target);
    snprintf(program[idx].coded, 256, "%d %d %d", JMF, cond_addr, target);
}

// JMP to the instruction when the jump target is known
static void backpatch_jmp(int idx, int target) {
    snprintf(program[idx].clear, 256, "JMP %d", target);
    snprintf(program[idx].coded, 256, "%d %d", JMP, target);
}

// write all the programs inside a file
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

// 
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


/*
FUNCTION DEFINITIONS
*/
func_defs:
    | func_defs func_def
;

func_def:

        // Add the info of the new created function to the function stack
    tINT tID tLPAREN
        {
                int idx = add_function($2, 1);
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP ???"); // unknown destination to jump
                snprintf(bd, 256, "%d ???", JMP);
                int jmp_idx = add_instruction(bc, bd);
                func_table[idx].instr_addr = jmp_idx;
                enter_scope();
        }
        // Check the parameters and put them inside the parameter list
    param_list tRPAREN tLBRACE declarations statements func_return tSEMICOLON tRBRACE
        {
                leave_scope();
                Function *f = get_function($2);
                int jmp_over = f->instr_addr;
                snprintf(program[jmp_over].clear, 256, "JMP %d", instr_count); // backpatch
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
        // void functions don't return anything, so we pass directly to the next instruction
    param_list tRPAREN tLBRACE declarations statements tRBRACE
        {
                char bc[256], bd[256];
                snprintf(bc, 256, "RET"); // end of a function
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

/*
PARAMETER LIST
*/
param_list:
    | param_list_items
;

param_list_items:
    tINT tID
        {
                int addr = add_symbol($2, 0, 0);
                Function *f = &func_table[func_count - 1];
                f->param_addrs[f->num_params] = addr; // get the parameters for that function
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

// return the integer obtained after an int function
func_return:
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
    | declarations error tSEMICOLON  { yyerrok; fprintf(stderr, "  -> recovered at ';' (declaration)\n"); } // return an error if a declaration missed ";"
;

declaration: tINT id_list 
        {
                printf("declaring an integer.\n"); // debug
                reset_temp_zone();
        }
        | tINT ptr_list
        {
                printf("declaring a pointer.\n"); // debug
                reset_temp_zone();
        }
        | tCONST tINT const_list 
        {
                printf("declaring a constant integer.\n"); // debug
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

/*
POINTERS
*/
ptr_list: ptr_decl_item
        | ptr_list tCOMMA ptr_decl_item
        ;

ptr_decl_item: tMUL tID
        {
                int addr = add_symbol($2, 0, 1);
                printf("Pointer %s declared at address %d\n", $2, addr); // debug
        }
        | tMUL tID tASSIGN expr
        {
                int addr = add_symbol($2, 0, 1);
                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $4);
                snprintf(bd, 256, "%d %d %d", COP, addr, $4);
                add_instruction(bc, bd);
                printf("Pointer %s declared and initialized at address %d\n", $2, addr); // debug
        }
        ;


/*
CONSTANTS
*/
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
        | if_state { reset_temp_zone(); }    
        | func_call tSEMICOLON { reset_temp_zone(); }
        | error tSEMICOLON { yyerrok; reset_temp_zone(); fprintf(stderr, "  -> recovered at ';' (statement)\n"); }
        | error tRBRACE    { yyerrok; reset_temp_zone(); fprintf(stderr, "  -> recovered at '}' (block)\n"); }
        ;

/*
ASSIGNMENTS
*/
assignment: tID tASSIGN expr
        { 
                int found = 0;
                int addr = 0;
                for (int i = symbol_count - 1; i >= 0; i--) {

                        // find the symbol in the table
                        if (strcmp(symbol_table[i].name, $1) == 0) {
                                found = 1;
                                addr = symbol_table[i].address;

                                // check if the symbol is a constant
                                if (symbol_table[i].isConst) {
                                        char buf[256];
                                        snprintf(buf, 256, "cannot assign to constant '%s'", $1);
                                        report_error(buf);
                                }
                                break;
                        }
                }

                // error if we cannot find the symbol
                if (!found) {
                        char buf[256];
                        snprintf(buf, 256, "symbol '%s' not found", $1);
                        report_error(buf);
                }

                char bc[256], bd[256];
                snprintf(bc, 256, "COP %d %d", addr, $3);
                snprintf(bd, 256, "%d %d %d", COP, addr, $3);
                add_instruction(bc, bd);
                printf("Assigned expression result to %s at address %d\n", $1, addr);
        }
        // pointer dereference
        | tMUL tID tASSIGN expr
        {
                int ptr_addr = get_address($2);
                char bc[256], bd[256];
                snprintf(bc, 256, "STOREI %d %d", ptr_addr, $4); // store the value expr into the pointer address
                snprintf(bd, 256, "%d %d %d", STOREI, ptr_addr, $4);
                add_instruction(bc, bd);
                printf("Dereference write through %s\n", $2);
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
        // not equal
        | expr tNEQ expr
        {
                int res = new_temp();
                int tmp1 = new_temp();
                int tmp2 = new_temp();
                char bc[256], bd[256];

                // put a verifier 1 to a temporary address
                snprintf(bc, 256, "AFC %d 1", tmp1);
                snprintf(bd, 256, "%d %d 1", AFC, tmp1);
                add_instruction(bc, bd);

                snprintf(bc, 256, "EQU %d %d %d", tmp2, $1, $3);
                snprintf(bd, 256, "%d %d %d %d", EQU, tmp2, $1, $3);
                add_instruction(bc, bd);

                // check if the result of EQU and invert it
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
        // address of a pointer, %prec is to assigns unary address-of precedence
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
                snprintf(bc, 256,  "LOADI %d %d", temp, ptr_addr);
                snprintf(bd, 256, "%d %d %d", LOADI, temp, ptr_addr);
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

/*
IF / ELSE
*/
if_cond:
        {
                if (if_sp >= MAX_NESTING) {
                        report_error("if statements nested too deeply");
                }
                int cond_addr = $<nb>-1;   // the expr result sits just before us 
                char bc[256], bd[256];
                snprintf(bc, 256, "JMF %d ???", cond_addr);
                snprintf(bd, 256, "%d %d ???", JMF, cond_addr);
                int idx = add_instruction(bc, bd);

                if_stack[if_sp].cond_addr = cond_addr;
                if_stack[if_sp].jmf_index = idx;
                if_stack[if_sp].jmp_index = -1;
                if_stack[if_sp].has_else  = 0;
                if_sp++;
                reset_temp_zone();
        }
        ;

if_state:
        tIF tLPAREN expr tRPAREN if_cond tLBRACE statements tRBRACE else_part
        {
                --if_sp;
                IfControl *ctx = &if_stack[if_sp];

                if (ctx->has_else) {
                        // JMF skips to just after the JMP-over-else 
                        backpatch_jmf(ctx->jmf_index, ctx->cond_addr,
                                      ctx->jmp_index + 1);
                        // JMP skips over the else body to current instr
                        backpatch_jmp(ctx->jmp_index, instr_count);
                } else {
                        // No else: JMF jumps straight past the if body 
                        backpatch_jmf(ctx->jmf_index, ctx->cond_addr,
                                      instr_count);
                }
                reset_temp_zone();
        }
        ;

else_part:
        | tELSE
        {
                // Emit a JMP placeholder to skip over the else body.
                // Record its index so the closing action can backpatch it.
                // We use if_sp-1 because if_sp was already incremented. 

                IfControl *ctx = &if_stack[if_sp - 1];
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP ???");
                snprintf(bd, 256, "%d ???", JMP);
                ctx->jmp_index = add_instruction(bc, bd);
                ctx->has_else  = 1;
                reset_temp_zone();
        }
        tLBRACE statements tRBRACE
        ;

/*
WHILE CONDITION 
*/
while: tWHILE while_start tLPAREN expr tRPAREN while_cond tLBRACE statements tRBRACE 
        {
                WhileControl ctx = while_stack[--while_sp];
                char bc[256], bd[256];
                snprintf(bc, 256, "JMP %d", ctx.loop_start);
                snprintf(bd, 256, "%d %d", JMP, ctx.loop_start);
                add_instruction(bc, bd);
                
                // Replace the "???" with instr_count
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

                // check if the number of parameters passes the limit
                if (frame->count != f->num_params) {
                        char buf[256];
                        snprintf(buf, 256, "function '%s' expects %d args, got %d",
                                 $1, f->num_params, frame->count);
                        report_error(buf);
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
        fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
        nb_errors++;
}

int main(void) {
        clear = fopen("clear.asm", "w");
        coded = fopen("coded.asm", "w");

        if (!clear || !coded) {
                perror("fopen");
                return 1;
        }

        yyparse();

        if (nb_errors > 0) {
                fprintf(stderr, "\nCompilation failed: %d error(s) detected.\n", nb_errors);
                fclose(clear);
                fclose(coded);
                return 1;
        }

        printf("Parsing finished successfully.\n");
        flush_program();

        fclose(clear);
        fclose(coded);
        return 0;
}