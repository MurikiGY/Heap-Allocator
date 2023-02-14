#include <stdio.h>
extern long int* alocaMem();
extern void iniciaAlocador();
extern void liberaMem();
extern void finalizaAlocador();
extern void imprimeMapa();

int main(int argc, char const *argv[])
{
     void *a,*b,*c,*d,*e,*f,*g;

  iniciaAlocador(); 
  imprimeMapa();

  a=(void *) alocaMem(50);
  imprimeMapa();

  b=(void *) alocaMem(40);
  imprimeMapa();

  c=(void *) alocaMem(55);
  imprimeMapa();

  d=(void *) alocaMem(35);
  imprimeMapa();

  e=(void *) alocaMem(60);
  imprimeMapa();

  liberaMem(b);
  imprimeMapa();

  liberaMem(d);
  imprimeMapa();

  f=(void *) alocaMem(15);
  imprimeMapa();

  g=(void *) alocaMem(41);
  imprimeMapa();

  printf("d=%p e f=%p\n", d, f);

  //Destroi todo o mapa
  liberaMem(a);
  imprimeMapa();

  liberaMem(c);
  imprimeMapa();

  liberaMem(e);
  imprimeMapa();

  liberaMem(f);
  imprimeMapa();

  finalizaAlocador();
  return 0;
}
