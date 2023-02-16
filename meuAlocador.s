 .section .data
  str1:        .asciz "%d\n"
  str2:        .asciz "\n=== API de alocação de memoria ===\n\n"
  NEW_LINE:    .asciz "\n"
  HEADER:      .asciz "################"
  PLUS:        .asciz "+"
  MINUS:       .asciz "-"
  EQUAL:       .asciz "."
  HEAP_START:  .quad 0
  HEAP_END:    .quad 0
  LIST_END:    .quad 0
  LAST_FIT:    .quad 0    # Variavel usada pelo algoritmo next fit

.section .text
.globl alocaMem 
.globl iniciaAlocador
.globl liberaMem
.globl finalizaAlocador
.globl imprimeMapa


iniciaAlocador:
  pushq %rbp
  movq %rsp, %rbp

# imprime qualquer coisa
  mov $str2, %rdi
  call printf

# Busca inicio da heap
  movq $12, %rax
  movq $0, %rdi
  syscall
  movq %rax, HEAP_START
  movq %rax, HEAP_END
  movq %rax, LIST_END
  movq %rax, LAST_FIT

  popq %rbp
  ret


finalizaAlocador:
  pushq %rbp
  movq %rsp, %rbp

# Restaura brk para inicio da heap
  movq $12, %rax
  movq HEAP_START, %rdi
  syscall
  movq %rax, HEAP_END
  movq %rax, LIST_END
  movq %rax, LAST_FIT

  popq %rbp
  ret


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
  loopImprimeMapa:
  cmpq LIST_END, %rbx
  jge imprimeSpaceLeft    # enquanto rbx diferente de list_end, imprime a lista

    # Imprime header
    mov $HEADER, %rdi

    call printf           # Imprime Header

    movq 8(%rbx), %r15    # r15: tamanho do nodo
    movq $0, %r12         # r12: contador de impressao

    imprimeNodo:
    # Salva em rdi o sinal
    mov $MINUS, %rdi
    cmpq $0, 0(%rbx)
    je imprimeSinal
    mov $PLUS, %rdi
    
    imprimeSinal:
    cmpq %r15, %r12
    jge fimImprimeNodo

    call printf

    addq $1, %r12
    jmp imprimeNodo
    fimImprimeNodo:

    # Salta para o proximo nodo
    addq 8(%rbx), %rbx    
    addq $16, %rbx
    jmp loopImprimeMapa

  imprimeSpaceLeft:       # imprime restante da heap
  movq HEAP_END, %r15
  subq LIST_END, %r15     # r15: space left

  movq $0, %r12           # contador de impressao
  loopSpaceLeft:
  cmpq %r15, %r12
  jge fimLoopSpaceLeft

  mov $EQUAL, %rdi
  call printf

  addq $1, %r12
  jmp loopSpaceLeft
  fimLoopSpaceLeft:

  mov $NEW_LINE,%rdi
  call printf
  mov $NEW_LINE,%rdi
  call printf

  returnImprimeMapa:
  #restaura registradores
  popq %rsi
  popq %rdi 

  popq %rbp
  ret


#tenta alocar rdi bytes no space_left
#retorna endereco da nova alocacao
#caso nao consiga, rax retorna NULL
alocaSpaceLeft:
#rdi: Tamanho solicitado pelo usuario
  pushq %rbp
  movq %rsp, %rbp

  movq $0, %rax
  movq %rdi, %r15
  addq $16, %r15            #r15 possui o tamanho do nodo
    
  movq HEAP_END, %r12
  subq LIST_END, %r12       #r12 possui space left

  cmpq %r12, %r15
  jg callExpandeHeap        #Se nodo maior que spaceLeft expande heap

    ##############
    # seta flags e aloca
    movq LIST_END, %r15
    movq $1, 0(%r15)        #seta flag de ocupado
    movq %rdi, 8(%r15)      #seta tamanho

    movq %r15, %rax
    addq $16, %rax          #seta endereco de retorno
    ##############

    #atualiza LIST_END
    movq LIST_END, %r12
    addq $16, %r12
    addq %rdi, %r12
    movq %r12, LIST_END
    jmp returnAlocaSpaceLeft

  callExpandeHeap:
    call expandeHeap

  returnAlocaSpaceLeft:
  popq %rbp
  ret



fragmenta:
# rdi: Tamanho solicitado pelo usuario
# rsi: Endereco do fim do header do nodo a ser fragmentado
  pushq %rbp
  movq %rsp, %rbp

# se (rdi+16+1) < -8(%rsi)          //se tamanho do noh eh pelo menos (aloc do usr + tam do header + 1), fragmenta
#   rsi+rdi = 0                     //seta flag da fragmentacao
#   rsi+rdi+8 = -8(%rsi) - (rdi+16) //seta tamanho 
#   -8(%rsi) =  rdi                 //seta novo tamanho do no

  movq %rdi, %r12
  addq $17,%r12

  cmpq %r12, -8(%rsi)
  jl returnFragmenta            # Se não tiver espaco, nao fragmenta

    movq %rsi, %rbx
    addq %rdi, %rbx             # Rbx aponta para endereco inicial do nodo fragmentado
    
    movq $0, 0(%rbx)            # Seta flag do nodo fragmentado
    movq -8(%rsi), %r13
    subq %rdi, %r13
    subq $16, %r13              # Rdx recebe tamanho alocavel do novo nodo fragmentado
    movq %r13, 8(%rbx)          # Seta tamanho do nodo fragmentado

    movq %rdi, -8(%rsi)         # Seta novo tamanho do nodo original

  returnFragmenta:
  popq %rbp
  ret



firstFit:
#rdi: Tamanho solicitado pelo usuario
  pushq %rbp
  movq %rsp, %rbp

  # Percorre lista
  movq HEAP_START, %rbx
  loopFirstFit:
  cmpq LIST_END, %rbx
  jge fimLoopFirstFit       #se rbx == LIST_END, nao encontrou

    #Testa flag e tamanho
    cmpq $0, 0(%rbx)
    jne nextNodeFF
    cmpq 8(%rbx), %rdi
    jg nextNodeFF

    #Aloca na posição e retorna
    movq $1, 0(%rbx)
    movq %rbx, %rsi
    addq $16, %rsi
    movq %rsi, %rax         #seta endereco de retorno

    call fragmenta
    jmp returnFirstFit

    nextNodeFF:
      movq 8(%rbx), %r12
      addq $16, %r12      #r12 possui total quantidade de bytes do no atual
      addq %r12, %rbx
      jmp loopFirstFit
  fimLoopFirstFit:

  #se chegou aqui, nodo nao encontrado
  call alocaSpaceLeft

  cmpq $0, %rax             #se alocado no space left, retorna
  jne returnFirstFit
    call expandeHeap

  returnFirstFit:
  popq %rbp
  ret



#nextFit:
#  pushq %rbp
#  movq %rsp, %rbp
#
#  movq LAST_FIT, %rbx     # rbx percorre do lastFit ao fim da lista
#  loopListEnd:
#  cmpq LIST_END, %rbx     # Testa se terminou de percorrer as listas
#  jge buscaInicio
#
#  cmpq $0, 0(%rbx)        #Verifica flag
#  jne nextNodeNF1
#  cmpq %rdi, 8(%rbx)      #Verifica tamanho
#  jl nextNodeNF1
#
#  #Aloca espaco
#  movq $1, 0(%rbx)        #Seta flag
#  movq %rbx, %rsi
#  addq $16, %rsi
#  movq %rsi, %rax
#  movq %rbx, LAST_FIT     #Atualiza lastFit
#
#  call fragmenta
#  jmp returnFirstFit
#
#  nextNodeNF1:
#    addq 8(%rbx), %rbx
#    addq $16, %rbx
#    jmp loopListEnd
#
#  buscaInicio:
#  movq HEAP_START, %rbx   #Rbx percore lista do inicio
#  loopListStart:
#  cmpq LAST_FIT, %rbx     #Testa se rbx bateu no lastfit
#  je alocaListEnd
#
#  cmpq $0, 0(%rbx)        #Verifica flag
#  jne nextNodeNF2
#  cmpq %rdi, 8(%rbx)      #Verifica tamanho
#  jl nextNodeNF2
#
#  #Aloca espaco
#  movq $1, 0(%rbx)
#  movq %rbx, %rsi
#  addq $16, %rsi
#  movq %rsi, %rax
#  movq %rbx, LAST_FIT     #Atualiza lastFit
#
#  call fragmenta
#  jmp returnFirstFit
#
#  nextNodeNF2:
#    addq 8(%rbx), %rbx
#    addq $16, %rbx
#    jmp loopListStart
#
#  alocaListEnd:
#  #Nao encontrou nodo, aloca no fim
#  call alocaSpaceLeft
#  movq LIST_END, %r12
#  movq %r12, LAST_FIT
#
#  returnNextFit:
#  popq %rbp
#  ret



#tenta alocar rdi bytes no nodo passado por parametro
#se conseguiu, retorna endereco da alocacao,
#retorna 0 se nao conseguiu
alocaNodo:
# rdi possui tamanho a ser alocado
# rsi possui endereco do fim do header do nodo
  pushq %rbp
  movq %rsp, %rbp

  movq $0, %rax
  cmpq $0, -16(%rsi)        #se flag de ocupado eh zero
  jne fimAlocaNodo
    cmpq %rdi, -8(%rsi)     #se tamanho eh suficiente
    jl fimAlocaNodo
      movq $1, -16(%rsi)
#      movq %rdi, -8(%rsi)
      movq %rsi, %rax
      call fragmenta

  fimAlocaNodo:
  popq %rbp
  ret



nextFit:
  pushq %rbp
  movq %rsp, %rbp
  subq $16, %rsp

  movq $0, %rax

  movq %rsi, -8(%rbp)         #salva registrador rsi
  movq %rdx, -16(%rbp)        #salva registrador rdx
  movq LAST_FIT, %rdx

  movq %rdx, %rsi
  addq $16, %rsi
  call alocaNodo
  cmpq $0, %rax               #se conseguir alocar no nodo, retorna 
  jne returnNF

  loopNF:
  addq  8(%rdx), %rdx         #salta rdx para proximo nodo
  addq $16, %rdx

  cmpq %rdx, LAST_FIT         #se rdx voltou ao Last Fit, nao ha nodo disponivel
  je notFoundNF

    cmpq %rdx, LIST_END
    jg testNodeNF

      movq HEAP_START, %rdx   
      cmpq %rdx, LAST_FIT     #se rdx voltou ao Last Fit, nao ha nodo disponivel
      je notFoundNF
    testNodeNF:
    movq %rdx, %rsi
    addq $16, %rsi
    call alocaNodo
    cmpq $0, %rax             #se conseguiu, retorna
    jne returnNF

    jmp loopNF
    
  notFoundNF:
  #movq $LIST_END, LAST_FIT #nao alterar antigo last fit neste caso?

  #se chegou aqui, nodo nao encontrado
  call alocaSpaceLeft
  cmpq $0, %rax             #se alocado no space left, retorna
  jne returnNF
    call expandeHeap

  returnNF:
  movq %rdx, LAST_FIT
  movq -8(%rbp), %rsi
  movq -16(%rbp), %rdx
  addq $16, %rsp
  popq %rbp
  ret



bestFit:
  pushq %rbp
  movq %rsp, %rbp

  movq $0, %rax     # Endereco de retorno
  movq $0, %rcx     # Nodo do BestFit

  # Percorre lista
  movq HEAP_START, %rbx
  loopBestFit:
  cmpq LIST_END, %rbx
  jge fimLoopBestFit

    # Testa flag e tamanho
    cmpq $0, 0(%rbx)
    jne nextNodeBF
    cmpq 8(%rbx), %rdi
    jg nextNodeBF

    # Testa rcx em 0
    cmpq $0, %rcx
    je rcxUpdate

    # Testa rcx maior que nodo encontrado
    movq 8(%rbx), %r12
    movq 8(%rcx), %r15
    cmpq %r12, %r15
    jle nextNodeBF

  rcxUpdate:
  movq %rbx, %rcx

  nextNodeBF:
        movq 8(%rbx), %r12
        addq $16, %r12      #r12 possui total quantidade de bytes do no atual
        addq %r12, %rbx
        jmp loopBestFit
  fimLoopBestFit:

  # Testa se encontrou algo
  cmpq $0, %rcx
  je callAlocaSpaceLeft

    # Aloca onde aponta rcx
    movq $1, 0(%rcx)        # Seta a flag
    movq %rcx, %rsi
    addq $16, %rsi
    movq %rsi, %rax
    call fragmenta
    jmp returnBestFit

  # Nao encontrou nada, aloca logo apos LIST_END
  callAlocaSpaceLeft:
    call alocaSpaceLeft

  returnBestFit:
  popq %rbp
  ret


#Expande heap e seta flag
expandeHeap:
#rdi: Tamanho solicitado pelo usuario
  pushq %rbp
  movq %rsp, %rbp

  pushq %rdi            #Salva o rdi
  add $16, %rdi         #rdi guarda a quantidade a expandir

  # Calcula space left e soma 4096
  movq HEAP_END, %rbx
  subq LIST_END, %rbx
  addq $4096, %rbx    # 4096 aqui
  
  multLoop:
  cmpq %rbx, %rdi
  jle fimMultLoop
  
    addq $4096, %rbx    # 4096 aqui
    jmp multLoop
  fimMultLoop:

  # Expande brk
  movq $12, %rax
  addq LIST_END, %rbx
  movq %rbx, %rdi
  syscall
  pop %rdi

  # Seta flags e tamanho
  movq LIST_END, %rbx
  movq $1, 0(%rbx)
  movq %rdi, 8(%rbx)
  
  # Atualiza variaveis
  movq %rax, HEAP_END       #Atualiza HEAP_END  
  addq $16, %rbx
  movq %rbx, %rax           #Atualiza retorno rax
  addq %rdi, %rbx
  movq %rbx, LIST_END       #Atualiza LIST_END
  
  pop %rbp
  ret


alocaMem:
# rdi: Tamanho solicitado pelo usuario
  pushq %rbp
  movq %rsp, %rbp

  # Testa alocação maior que zero
  cmpq $1, %rdi
  jge aloca
  movq $0, %rax
  jmp returnAlocaMem

    aloca:
    # Testa se a heap esta vazia
    movq HEAP_START, %rbx
    cmpq %rbx, HEAP_END
    #jg callFirstFit   # Se heap não vazia, chama Busca
    jg callBestFit    # Se heap não vazia, chama Busca
    #jg callNextFit    # Se heap não vazia, chama Busca
    
        call expandeHeap
        jmp returnAlocaMem

    #callFirstFit:
    #    call firstFit
    #    jmp returnAlocaMem

    callBestFit:
        call bestFit
        jmp returnAlocaMem

    #callNextFit:
    #    call nextFit
    #    jmp returnAlocaMem

  returnAlocaMem:
  pop %rbp
  ret


liberaMem:
# rdi: Endereço do nodo a ser liberado
  pushq %rbp
  movq %rsp, %rbp

  movq $0, -16(%rdi)        # Seta flag pra zero

  # Percorre juntando
  movq HEAP_START, %rbx
  loopJuntaNodo:
  cmpq LIST_END, %rbx
  jge returnLiberaMem
    
    cmpq $0, 0(%rbx)
    jne juntaNextNode

    # r12 aponta para o proximo nodo
    movq %rbx, %r12
    addq 8(%rbx), %r12
    addq $16, %r12

    # Testa se chegou no fim
    cmpq LIST_END, %r12
    jge returnLiberaMem

    # Testa flag
    cmpq $0, 0(%r12)
    jne juntaNextNode

      # Junta nodos
      movq 8(%r12), %r12
      addq $16, %r12
      addq %r12, 8(%rbx)
      jmp loopJuntaNodo

  juntaNextNode:
    addq $16, %rbx
    addq -8(%rbx), %rbx
    jmp loopJuntaNodo

# Retorna
  returnLiberaMem:
  popq %rbp
  ret

