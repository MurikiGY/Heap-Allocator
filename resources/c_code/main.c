#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char **argv){
  void *a;
  int i;

  for ( i=0; i<100; i++ ) {
    a = malloc(100);
    strcpy(a, "TESTE") ;
    printf("%p %s\n", a, (char *) a);
    free(a);
  }

  return (0) ;
}
