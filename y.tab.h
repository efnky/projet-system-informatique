/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    tMAIN = 258,                   /* tMAIN  */
    tPRINTF = 259,                 /* tPRINTF  */
    tLBRACE = 260,                 /* tLBRACE  */
    tRBRACE = 261,                 /* tRBRACE  */
    tLPAREN = 262,                 /* tLPAREN  */
    tRPAREN = 263,                 /* tRPAREN  */
    tCONST = 264,                  /* tCONST  */
    tINT = 265,                    /* tINT  */
    tIF = 266,                     /* tIF  */
    tELSE = 267,                   /* tELSE  */
    tWHILE = 268,                  /* tWHILE  */
    tPLUS = 269,                   /* tPLUS  */
    tMINUS = 270,                  /* tMINUS  */
    tMUL = 271,                    /* tMUL  */
    tDIV = 272,                    /* tDIV  */
    tASSIGN = 273,                 /* tASSIGN  */
    tSEMICOLON = 274,              /* tSEMICOLON  */
    tCOMMA = 275,                  /* tCOMMA  */
    tNEWLINE = 276,                /* tNEWLINE  */
    tERROR = 277,                  /* tERROR  */
    tLT = 278,                     /* tLT  */
    tGT = 279,                     /* tGT  */
    tEQEQ = 280,                   /* tEQEQ  */
    tNEQ = 281,                    /* tNEQ  */
    INTEGER = 282,                 /* INTEGER  */
    tID = 283                      /* tID  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define tMAIN 258
#define tPRINTF 259
#define tLBRACE 260
#define tRBRACE 261
#define tLPAREN 262
#define tRPAREN 263
#define tCONST 264
#define tINT 265
#define tIF 266
#define tELSE 267
#define tWHILE 268
#define tPLUS 269
#define tMINUS 270
#define tMUL 271
#define tDIV 272
#define tASSIGN 273
#define tSEMICOLON 274
#define tCOMMA 275
#define tNEWLINE 276
#define tERROR 277
#define tLT 278
#define tGT 279
#define tEQEQ 280
#define tNEQ 281
#define INTEGER 282
#define tID 283

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 146 "compiler.y"
 int nb; char *str; 

#line 126 "y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
