# Heap Allocator
  Implementação de uma biblioteca para alocação dinâmica de memoria.
  
## Alocador de Bartlett
  Algoritmo de lista encadeada usado para implementar o controle da memória onde um nó é dividido em duas partes, uma gerencial e outra de dados:
  
  - Gerencial: Representando os primeiros 16 bytes da alocação, os primeiros 8 bytes são para definir se a região está sendo utilizada ou se foi liberada. Já os 8 bytes conseguintes são utilizados para especificar o tamanho do espaço alocado.
  
  - Dados: Região em que é armazenado os dados.
  
## Implementação
  Para garantir um melhor uso da heap e evitar constantemente realizar chamadas ao sistema operacinal os seguintes procedimentos foram criados:
  
  - Espaços multiplos de 4096: Quando não houver espaço para alocar memoria dentro da heap, ao invés de solicitar ao sistema operacional que reajuste o ponteiro da brk de acordo com a quantidade que se quer alocar, o ponteiro da brk é somado com um multiplo de 4096 que seja maior ou igual a quantidade necessária para a alocação.
  - First Fit: Ao ser solicitado uma alocação, percorre a lista em busca do primeiro espaço encontrado que for maior ou igual a quantidade solicitada.
  - Best Fit: Ao ser solicitado uma alocação, percore a lista em busca do melhor espaço em que se possa atribuir a alocação
  - Next Fit: Semelhante ao First Fit, percorre a lista em busca do primeiro espaço possível, porém ao invés de começar a busca do inicio da heap, a busca começa pela última região alocada.
  
## Imprime Heap
  Para fins de verificação, uma função `imprimeheap()` foi implementada, onde a região de gerenciamento é representada por '#', região de dados alocada por '+', região de dados não alocada por '-' e espaço vazio por '.'.
