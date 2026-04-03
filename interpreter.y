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

FILE* yyin;

int mem[1000] = {0};
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
        int op = $1;
        int a = $2;
        int b = $3;
        int c = $4;

        switch(op) {
            case ADD: mem[a] = mem[b] + mem[c]; break;
            case MUL: mem[a] = mem[b] * mem[c]; break;
            case SOU: mem[a] = mem[b] - mem[c]; break;
            case DIV: if (mem[c] == 0) {
                printf("Error: division by zero\n");
                exit(1);
            }
            mem[a] = mem[b] / mem[c]; break;
            default: printf("Error: cannot find the operator\n");
                    exit(1);
        }
    }
    | INTEGER INTEGER INTEGER 
    {
        int op = $1;
        int a = $2;
        int b = $3;

        switch(op) {
            case COP: mem[a] = mem[b]; break;
            case AFC: mem[a] = b; break;
            default: printf("Error: cannot find the operator\n");
                    exit(1);
        }
    }
    | INTEGER INTEGER
    {
        int op = $1;
        int a = $2;

        switch(op) {
            case PRI: printf("%d\n",mem[a]); break;
            default: printf("Error: cannot find the operator\n");
                    exit(1);
        }
    }
    ;

%%
void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyin = fopen("coded.asm", "r");
    if (!yyin) {
        perror("coded.asm");
        return 1;
    }

    int result = yyparse();
    fclose(yyin);
    return result;
}
