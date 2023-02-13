imprimeMapa:
  pushq %rbp
  movq %rsp, %rbp
  pushq %rdi
  pushq %rsi
  
  # Testa heap vazia
  movq HEAP_END, %rbx
  cmpq HEAP_START,  %rbx
  jle returnImprimeMapa   # se Heap_End <= Heap_Start, return
  
  movq HEAP_START, %rbx
  looplistaNodo:
  cmpq LIST_END, %rbx
  jge imprimeSpaceLeft    # enquanto rbx diferente de list_end, imprime a lista
  
    # Imprime header
    mov $HEADER, %rdi
    call printf           # Imprime Header

    # Salva o sinal que tem que imprimir
    mov $MINUS, %rdi
    cmpq $0, 0(%rbx)
    je imprimeNodo
    mov $PLUS, %rdi

    # Configura loop
    movq 8(%rbx), %r15    # Tamanho do nodo
    movq $0, %r12         # Contador de impressao

    imprimeNodo:






    movq 8(%rbx), %r15    # r15 tem o tamanho do nodo
    movq $0, %r12         # r12 tem o contador de impressão
    loopAlocacao:
    # Salva em rdi o sinal para imprimir
    mov $MINUS, %rdi
    cmpq $0, 0(%rbx)
    je imprimeAlocacao
    mov $PLUS, %rdi
  
    imprimeAlocacao:
    cmpq %r15, %r12
    jge fimImprimeAlocacao
  
    call printf
  
    addq $1, %r12
    jmp loopAlocacao
    fimImprimeAlocacao:
  
    # Salta para o proximo nodo
    addq 8(%rbx), %rbx
    addq $16, %rbx
    jmp loopListaNodo
  
  imprimeSpaceLeft:       # imprime restante da heap
  movq HEAP_END, %r12
  subq LIST_END, %r12     # r12 possui space left
  
  movq $0, %r15
  loopSpaceLeft:
  cmpq %r12, %r15
  jge fimLoopSpaceLeft
  
  mov $EQUAL, %rdi
  call printf
  
  addq $1, %r15
  jmp loopSpaceLeft
  fimLoopSpaceLeft:
  
  mov $NEW_LINE,%rdi
  call printf
  
  returnImprimeMapa:
  #restaura registradores
  popq %rsi
  popq %rdi
  
  popq %rbp
  ret

