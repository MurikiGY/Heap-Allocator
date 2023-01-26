# Para retornar posição do ponteiro brk da heap:
  movq $12, %rax
  movq $0, %rdi
  # Com isso %rax irá possuir o enderesso 

# Algoritmo do syscall para brk
altere brk com o valor passado em %rdi
retorne a posicao de brk em %rax

alocaMem:
  Testa se heap vazia
    expandeHeap
  else
    busca bestFit
    se econtrou{
      seta flag,
      seta tamanho,
      retorna endereco da alocacao
    } else
      expandeHeap


