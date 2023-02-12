 .section .data
  str1:        .asciz "%d\n"
  str2:        .asciz "\n=== API de alocação de memoria ===\n\n"
  NEW_LINE:    .asciz "\n"
  HEADER:      .asciz "################"
  HEAP_START:  .quad 0
  HEAP_END:    .quad 0
  LAST_FIT:    .quad 0    # Variavel usada pelo algoritmo next fit
  LIST_END:    .quad 0

.section .text
.globl main


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

  pop %rbp
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

  pop %rbp
  ret


  
imprimeChar:
# rsi possui quantidade de caracteres a serem impressos
# rdi possui o caractere a ser impresso
  pushq %rbp
  movq %rsp, %rbp
  pushq %rbx
  
  movq $1,%rbx
  loopImprimeChar:
  cmpq %rsi, %rbx
  jg returnImprimeChar
    call putchar
    addq $1, %rbx
  jmp loopImprimeChar

  returnImprimeChar:
  popq %rbx
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
  jle returnImprimeMapa   # se Heap_End == Heap_Start, return

  movq HEAP_START, %rbx
  loopImprimeMapa:
  cmpq LIST_END, %rbx
  jge imprimeSpaceLeft    # enquanto rbx diferente de list_end, imprime a lista

    # Imprime header
    mov $HEADER, %rdi
    call printf           # Imprime Header

    movq 8(%rbx), %rsi    
    movq $'-', %rdi
    cmpq $0, 0(%rbx)
    je imprimeAlocacao
    movq $'+', %rdi
    
    imprimeAlocacao:
        call imprimeChar
    
    addq 8(%rbx), %rbx    # Salta area alocada
    addq $16, %rbx        # Salta Header
    jmp loopImprimeMapa

  imprimeSpaceLeft:       # imprime spaco restante da heap
  movq HEAP_END, %rsi
  subq LIST_END, %rsi     # rsi possui space left
  movq $'-', %rdi
  call imprimeChar
  
  mov $NEW_LINE,%rdi
  call printf

  #restaura registradores
  popq %rsi
  popq %rdi 

  returnImprimeMapa:
  pop %rbp
  ret



fragmenta:
# rdi possui tamanho da alocacao do usuario
# rsi possui endereco do fim do header do noh a ser fragmentado
  pushq %rbp
  movq %rsp, %rbp

# se (rdi+16+1) < -8(%rsi) //se tamanho do noh eh pelo menos (aloc do usr + tam do header + 1), fragmenta
#   rsi+rdi = 0 //seta flag da fragmentacao
#   rsi+rdi+8 = -8(%rsi) - (rdi+16) //seta tamanho 
#   -8(%rsi) =  rdi //seta novo tamanho do no

  push %rdi
  addq $17,%rdi
  cmpq %rdi, -8(%rsi)
  jl returnFragmenta
    popq %rdi
    movq %rsi, %rbx
    addq %rdi, %rbx             # Rbx recebe endereco inicial do noh fragmentado
    movq $0, 0(%rbx)            # Seta flag do noh fragmentado
    
    movq -8(%rsi), %rdx
    subq %rdi, %rdx
    subq $16, %rdx              # Rdx recebe tamanho alocavel do novo noh fragmentado
    movq %rdx, 8(%rbx)          # Seta tamanho do noh fragmentado

    movq %rdi, -8(%rsi)         # Seta tamanho do no original

  returnFragmenta:
  popq %rbp
  ret



liberaMem:
# rdi possui endereco de espaco a ser liberado
  pushq %rbp
  movq %rsp, %rbp

  movq $0, -16(%rdi)        # Seta flag pra zero

# Retorna
  pop %rbp
  ret



buscaFirstFit:
  pushq %rbp
  movq %rsp, %rbp

  # Percorre lista
  movq HEAP_START, %rbx
  loopBuscaFirstFit:
  cmpq LIST_END, %rbx
  jge fimLoopFirstFit
    #Testa flag
    cmpq $0, 0(%rbx)
    jne nextNode
    cmpq 8(%rbx), %rdi
    jg nextNode

    # Aloca posição
    movq $1, 0(%rbx)
    movq %rbx, %rsi
    addq $16, %rsi
    call fragmenta
    movq %rsi, %rax
    jmp fimLoopFirstFit

    nextNode:
        addq 8(%rbx), %rbx
        jmp loopBuscaFirstFit

  fimLoopFirstFit:
  pop %rbp
  ret



buscaNextFit:
  pushq %rbp
  movq %rsp, %rbp

  #  se LAST_FIT == 0
  #      rbx = HEAP_START
  #  else 
  #      rbx = LAST_FIT
  #
  #  if (0(%rbx) == 0) 
  #      0(%rbx) = 1
  #      rdi = rdi
  #      rax = rbx+16
  #      rsi = rax
  #      fragmenta()
  #      return
  #  
  #  rbx = rbx+8(%rbx)
  #  while (rbx != LAST_FIT){
  #    if (%rbx == HEAP_END)
  #        %rbx = HEAP_START
  #    else{
  #        if (0(%rbx) == 0) {
  #            0(%rbx) = 1
  #            rdi = rdi
  #            rax = rbx+16
  #            rsi = rax
  #            fragmenta()
  #            return
  #        }
  #        rbx = rbx+8(%rbx)
  #    }
  #  }
  #
  #  if (space_left  eh suficiente)
  #      0(%LIST_END) = 1
  #      8(%LIST_END) = rdi
  #      rax = LIST_END + 16
  #      LIST_END = LIST_END + 16 + rdi
  #  else 
  #      expande
 
  popq %rbp
  ret


buscaBestFit:
  pushq %rbp
  movq %rsp, %rbp

  #rax = 0 
  #rcx = 0 
  #rbx = HEAP_START + 16
  #enquanto rbx < LIST_END
  #  se (-8(%rbx) > %rdi) e (-16(%rbx) == 0)
  #      se (se rcx == 0) ou (-8(%rbx) < rcx)
  #          rcx = -8(%rbx)
  #          rax = rbx
  #  rbx = rbx + -8(%rbx)
  #se rax
  #  -16(%rax) = 1
  #  rdi = rdi
  #  rsi = rax 
  #  fragmenta_no()
  #else
  #  space_left = HEAP_END - LIST_END
  #  se space_left > %rdi
  #    rax = LIST_END+16
  #    -16(%rax) = 1
  #    rdi = rdi
  #    rsi = rax
  #    fragmenta_no()
  #  else 
  #    expande
  #ret

  returnBestFit:
  pop %rbp
  ret





#Expande heap e seta flag
expandeHeap:
#rdi possui tamanho a ser alocado para o usuario
  pushq %rbp
  movq %rsp, %rbp

  pushq %rdi            #Salva o rdi
  add $16, %rdi         #rdi guarda a quantidade a expandir

  # Calcula space left e soma 4096
  movq HEAP_END, %rbx
  subq LIST_END, %rbx
  addq $4096, %rbx
  
  divLoop:
  cmpq %rbx, %rdi
  jle fimDivLoop
  
    addq $4096, %rbx
    jmp divLoop
  fimDivLoop:

  # Expande brk
  movq $12, %rax
  addq LIST_END, %rbx
  movq %rbx, %rdi
  syscall
  pop %rdi

  # Seta flags
  movq LIST_END, %rbx
  movq $1, 0(%rbx)
  movq %rdi, 8(%rbx)
  
  # Atualiza variaveis
  movq %rax, HEAP_END       #Atualiza HEAP_END  
  addq $16, %rbx
  movq %rbx, %rax           #Atualiza rax
  addq %rdi, %rbx
  movq %rbx, LIST_END       #Atualiza LIST_END
  
  pop %rbp
  ret



alocaMem:
# rdi possui a quantidade a ser alocada
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
    jg callBuscaFirstFit   # Se heap não vazia, chama Busca
    
    #jg callBuscaBestFit    # Se heap não vazia, chama Busca
    #jg callBuscaNextFit    # Se heap não vazia, chama Busca
    
        call expandeHeap
        jmp returnAlocaMem

    callBuscaFirstFit:
        call buscaFirstFit
        jmp returnAlocaMem

    #callBuscaBestFit:
    #    call buscaBestFit
    #    jmp returnAlocaMem

    #callBuscaNextFit:
    #    call buscaNextFit
    #    jmp returnAlocaMem

  returnAlocaMem:
  pop %rbp
  ret


main:
#Inicia main e declara variaveis
  pushq %rbp
  movq  %rsp, %rbp
  subq  $16, %rsp 

# Configura alocador
  call iniciaAlocador


# Aloca bytes
  movq $8, %rdi
  call alocaMem
  movq %rax, -8(%rbp)

# imprime Mapa
  call imprimeMapa

# Desaloca bytes
  movq -8(%rbp), %rdi
  call liberaMem

# imprime Mapa
  call imprimeMapa

## Aloca bytes
#  movq $16, %rdi
#  call alocaMem
#  movq %rax, -24(%rbp)
#
## Desaloca bytes
#  movq -16(%rbp), %rdi
#  call liberaMem
#
## Desaloca bytes
#  movq -24(%rbp), %rdi
#  call liberaMem


# Destroi alocador
  call finalizaAlocador

#Finaliza programa
  movq  $60, %rax
  popq %rbp
  syscall
