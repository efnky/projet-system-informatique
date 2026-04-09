%{
#include <stdio.h>
#include <stdlib.h>

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

#define MAX_INSTR 10000

typedef struct {
    int op;
    int args[3];
    int nargs;
} Instruction;

FILE* yyin;

int mem[1000] = {0};
Instruction prog[MAX_INSTR];
int prog_size = 0;

void run_program(void);
int yylex(void);
void yyerror(const char *s);
%}

%union { int nb; }

%token <nb> INTEGER
%token NEWLINE

%%

program:
    | program program_line NEWLINE
    | program NEWLINE
    ;

program_line: INTEGER INTEGER INTEGER INTEGER
    {
        prog[prog_size].op      = $1;
        prog[prog_size].args[0] = $2;
        prog[prog_size].args[1] = $3;
        prog[prog_size].args[2] = $4;
        prog[prog_size].nargs   = 3;
        prog_size++;
    }
    | INTEGER INTEGER INTEGER
    {
        prog[prog_size].op      = $1;
        prog[prog_size].args[0] = $2;
        prog[prog_size].args[1] = $3;
        prog[prog_size].nargs   = 2;
        prog_size++;
    }
    | INTEGER INTEGER
    {
        prog[prog_size].op      = $1;
        prog[prog_size].args[0] = $2;
        prog[prog_size].nargs   = 1;
        prog_size++;
    }
    ;

%%
void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

void run_program(void) {
    int pc = 0;
    while (pc < prog_size) {
        Instruction ins = prog[pc];
        switch (ins.op) {
            case ADD: mem[ins.args[0]] = mem[ins.args[1]] + mem[ins.args[2]]; pc++; break;
            case MUL: mem[ins.args[0]] = mem[ins.args[1]] * mem[ins.args[2]]; pc++; break;
            case SOU: mem[ins.args[0]] = mem[ins.args[1]] - mem[ins.args[2]]; pc++; break;
            case DIV:
                if (mem[ins.args[2]] == 0) {
                    printf("Error: division by zero\n");
                    exit(1);
                }
                mem[ins.args[0]] = mem[ins.args[1]] / mem[ins.args[2]];
                pc++;
                break;
            case INF: mem[ins.args[0]] = mem[ins.args[1]] < mem[ins.args[2]]; pc++; break;
            case SUP: mem[ins.args[0]] = mem[ins.args[1]] > mem[ins.args[2]]; pc++; break;
            case EQU: mem[ins.args[0]] = mem[ins.args[1]] == mem[ins.args[2]]; pc++; break;
            case COP: mem[ins.args[0]] = mem[ins.args[1]]; pc++; break;
            case AFC: mem[ins.args[0]] = ins.args[1]; pc++; break;
            case PRI: printf("%d\n", mem[ins.args[0]]); pc++; break;

            case JMP:
                pc = ins.args[0];
                break;
            case JMF:
                if (mem[ins.args[0]] == 0)
                    pc = ins.args[1];
                else
                    pc++;
                break;

            default:
                printf("Error: unknown opcode %d\n", ins.op);
                exit(1);
        }
    }
}

int main(void) {
    yyin = fopen("coded.asm", "r");
    if (!yyin) {
        perror("coded.asm");
        return 1;
    }

    yyparse();
    fclose(yyin);

    run_program();
    return 0;
}
