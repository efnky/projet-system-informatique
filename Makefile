BISON = /opt/homebrew/opt/bison/bin/bison
FLEX  = /opt/homebrew/opt/flex/bin/flex

compiler: compiler.l compiler.y
	$(BISON) -d -y compiler.y
	$(FLEX) compiler.l
	gcc y.tab.c lex.yy.c -o compiler

interpreter: interp.l interp.y
	$(BISON) -d interp.y
	$(FLEX) interp.l
	gcc interp.tab.c lex.yy.c -o interp

clean:
	rm -f *.tab.c *.tab.h lex.yy.c y.tab.* compiler interp *.asm
