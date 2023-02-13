LINK = -dynamic-linker /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
			 /usr/lib/x86_64-linux-gnu/crt1.o \
			 /usr/lib/x86_64-linux-gnu/crti.o \
			 /usr/lib/x86_64-linux-gnu/crtn.o

all: meuAlocador

meuAlocador: alocador.o main.o
	ld alocador.o main.o -o meuAlocador $(LINK) -lc

main.o: main.c
	gcc -g -c main.c -o main.o

alocador.o: alocador.s
	as alocador.s -o alocador.o -g

clean: 
	-rm -f alocador.o main.o

purge: clean
	-rm -f meuAlocador
