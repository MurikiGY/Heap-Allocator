extern long int* alocaMem();
extern void iniciaAlocador();
extern void liberaMem();
extern void finalizaAlocador();
extern void imprimeMapa();

int main() {
  void *a, *b, *c, *d, *e;
  imprimeMapa();

  iniciaAlocador();
  imprimeMapa();

  a=alocaMem(100);
  imprimeMapa();

  b=alocaMem(50);
  imprimeMapa();

  c=alocaMem(40);
  imprimeMapa();

  d=alocaMem(40);
  imprimeMapa();

  liberaMem(a);
  imprimeMapa();

  liberaMem(c);
  imprimeMapa();

  a=alocaMem(15);
  imprimeMapa();

  liberaMem(a);
  imprimeMapa();

  e=alocaMem(20);
  imprimeMapa();

  finalizaAlocador();
  imprimeMapa();
}
