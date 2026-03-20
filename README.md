# Calculator Lexer - Lex Project

This project contains a lexical analyzer implementation using Lex (Flex) for a simple calculator.

## Files

- `compiler.l` - Lexical analyzer for the compiler with additional token rules
- `compiler.y` - Parser rules (likely for Yacc/Bison)
- `lex.yy.c` - Generated C code from the Lex compiler
- `compiler` - Compiled executable

## Prerequisites

Make sure you have Lex (or Flex) and a C compiler installed:

```bash
brew install flex gcc  # macOS
# or
sudo apt-get install flex gcc  # Linux
```

## Building

To compile the Lex code and generate the scanner:

```bash
lex compiler.l
yacc compiler.y
gcc y.tab.c lex.yy.c -o compiler
```

## Running

```bash
./compiler
```

Then enter mathematical expressions:
- `123` - numbers
- `+`, `-`, `*`, `/` - operators
- `(`, `)` - parentheses
- `=` - assignment
- `a`, `b`, etc. - variables (single letters)

Example:
```
2 + 3 * 4
x = 5
```

## What the Lexer Does

The `calc.l` file tokenizes input and recognizes:
- Numbers and exponential notation
- Arithmetic operators
- Variable names
- Printf statements
- Integer declarations
