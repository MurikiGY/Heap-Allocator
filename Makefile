LINK = -dynamic-linker /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
			 /usr/lib/x86_64-linux-gnu/crt1.o \
			 /usr/lib/x86_64-linux-gnu/crti.o \
			 /usr/lib/x86_64-linux-gnu/crtn.o

all: meuAlocador

meuAlocador: meuAlocador.o avalia.o
	ld meuAlocador.o avalia.o -o meuAlocador $(LINK) -lc

avalia.o: avalia.c
	gcc -g -c avalia.c -o avalia.o

meuAlocador.o: meuAlocador.s
	as meuAlocador.s -o meuAlocador.o -g

clean: 
	-rm -f meuAlocador.o avalia.o

purge: clean
	-rm -f meuAlocador
