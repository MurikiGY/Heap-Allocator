LINK = -dynamic-linker /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
			 /usr/lib/x86_64-linux-gnu/crt1.o \
			 /usr/lib/x86_64-linux-gnu/crti.o \
			 /usr/lib/x86_64-linux-gnu/crtn.o
#LINK = -dynamic-linker usr/lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o  /usr/lib/crti.o /usr/lib/crtn.o

all: teste

teste: teste.o
	ld teste.o -o teste $(LINK) -lc

teste.o: teste.s
	as teste.s -o teste.o -g

clean: 
	-rm -f teste.o

purge: clean
	-rm -f teste
