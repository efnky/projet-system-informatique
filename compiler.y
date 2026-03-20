/* Semantic values */
%union {
    double num;
    char *str;
}

/* Tokens coming from Lex */
%token MAIN PRINTF CONST INT
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON COMMA ASSIGN
%token PLUS MINUS MUL DIV
%token <num> INTEGER
%token <str> ID

%type <num> expr

/* Operator priority */
%left PLUS MINUS
%left MUL DIV
%right UMINUS

%%