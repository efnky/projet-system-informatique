BISON = /opt/homebrew/opt/bison/bin/bison
FLEX  = /opt/homebrew/opt/flex/bin/flex

compiler: compiler.l compiler.y
	$(BISON) -d -y compiler.y
	$(FLEX) compiler.l
	gcc y.tab.c lex.yy.c -o compiler

interpreter: interpreter.l interpreter.y
	$(BISON) -d -y interpreter.y
	$(FLEX) interpreter.l
	gcc y.tab.c lex.yy.c -o interpreter

clean:
	rm -f *.tab.c *.tab.h lex.yy.c y.tab.* compiler interpreter *.asm
