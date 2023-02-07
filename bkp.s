.section .data
  str1:       .string "\n=== API de alocação de memoria ===\n"
  HEAP_START: .quad 0
  HEAP_END:   .quad 0
  SPACE_LEFT: .quad 0

.section .text
.globl main

iniciaAlocador:
# Registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Busca inicio da heap
  movq $12, %rax
  movq $0, %rdi
  syscall
  movq %rax, HEAP_START
  movq %rax, HEAP_END

# Retorna
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

# Retorna
  pop %rbp
  ret


BuscaBestFit:
  pushq %rbp
  movq %rsp, %rbp

  # Pseudo-codigo:
  # se tam+16 >= space_left
  #     A = brk - space left
  #     set flag in A
  #     set tam in A+8
  #     rax = A+16
  #     space left = space left - (tam+16)
  #     return rax
  # else 
  #   rax = 0
  #   rcx = 0
  #   rbx = HEAP_START + 16  #rbx recebe primeiro endereco alocado (apos header)
  #   enquanto rbx < HEAP_END
  #     se (-8(rbx) >= rdi) && (-16(rbx) == 0)  #se "tam da alocacao" >= "tam desejado" e espaco livre
  #       se (rcx == 0) || (-8(rbx) < rcx)     
  #         rcx = -8(%rbx)
  #         rax = rbx
  #     rbx = rbx + -8(rbx)
  

  movq HEAP_END, %rdx
  subq SPACE_LEFT, %rdx   # rdx = endereco do fim da alocacao ocupada

  movq %rdi, %rbx
  addq $16, %rbx          # rbx = user allocation size + 16
  cmpq %rbx, SPACE_LEFT
  jl iniciaBusca          # se espaco nao ocupado nao for suficiente, busca best fit entre ocupados
    movq $1, %rdx
    movq %rdi, 8(%rdx)
    movq %rdx, %rax
    addq $16, %rax        # rax recebe endereco apos header da nova alocacao
    movq SPACE_LEFT, %rdx
    subq %rbx, %rdx       # rdx = space left - (user allocation size +16)
    movq %rdx, SPACE_LEFT
    jmp returnBestFit

  iniciaBusca:
  movq $0, %rax
  movq $0, %rcx
  movq HEAP_START, %rbx
  addq $16, %rbx            # rbx aponta para o final do header da primeira alocacao

  loopBestFit:
  cmpq %rbx, %rdx
  jle fimLoopBestFit       # se (endereco final das alocacoes <= endereco atual), termina busca 
  movq -8(%rbx), %r8       # r8 recebe tamanho da alocacao
  
  if1:
  cmpq %rdi, %r8           # Se tem espaço para a alocacao
  jl incrementaLoopBestFit  # Se nao tem espaco, pula nodo
    if2:
    cmpq $0, -16(%rbx)          # Se a flag esta em 0
    jne incrementaLoopBestFit   # Se flag diferente de 0, pula nodo
      if3:
      cmpq $0, %rcx
      je inside_If3_OR          # Se rcx nao foi setado, seta rcx e rax 
      if3_OR:
      cmpq %rcx, -8(%rbx)
      jge incrementaLoopBestFit  #Se tamanho do nodo maior ou igual rcx, pula nodo
        inside_If3_OR:
        movq %rbx, %rax
        movq %r8, %rcx
  
  incrementaLoopBestFit:
  addq %r8, %rbx           # rbx aponta para proxima alocacao de memoria
  addq $16, %rbx
  jmp loopBestFit
  fimLoopBestFit:

  #testa se a busca achou algum espaco
  if4:
  cmpq $0, %rax
  jne if4_else
    call expandeHeap          # Se nao achou aloca novo espaco na heap
  if4_else:
    movq $1, -16(%rax)        # Se achou seta flag para 1
    jmp returnBestFit
    
  # Retorna bestFit
  returnBestFit:
  pop %rbp
  ret


alocaMem:
  pushq %rbp
  movq %rsp, %rbp

# Testa se vai ser aloção mais que 0 bytes
  cmpq $1, %rdi
  jge aloca
  movq $0, %rax
  jmp returnAlocaMem  #Se tamanho menor que 1, retorna 0
    aloca:
    movq HEAP_START, %rbx
    cmpq %rbx, HEAP_END
    jg callBuscaBestFit   # Se heap não vazia, chama bestFit
      #movq %rcx, %rdi
      call expandeHeap
      jmp returnAlocaMem

    callBuscaBestFit:
    #movq %rcx, %rdi
    call BuscaBestFit
  returnAlocaMem:
# Retorna
  pop %rbp
  ret


expandeHeap:
#rdi possui tamanho a ser alocado para o usuario
  pushq %rbp
  movq %rsp, %rbp

  ## Pseudo-codigo##
  # tam_aloc_usr = rdi
  # end_inic_nova_alocacao = HEAP_END - SPACE_LEFT
  # x = 4096
  #
  # while ( x+(SPACE_LEFT) < tam_aloc_usr+16 )
  #   x += 4096
  #
  # rdi = HEAP_END+x
  # syscall
  # HEAP_END = rax
  #
  # (end_inic_nova_alocacao) = 1
  # 8(end_inic_nova_alocacao) = tam_aloc_usr
  # SPACE_LEFT = HEAP_END - (end_inic_nova_alocacao + (tam_aloc_usr+16))
  # rax = end_inic_nova_alocacao + 16 //endereco logo apos header
  # return 

  movq HEAP_END, %rcx 
  subq SPACE_LEFT, %rcx # rcx possui endereco inicial da nova alocacao

  movq %rdi, %rdx
  addq $16, %rdx        # rdi recebe tamanho minimo a ser alocado (contando com header)

  movq $4096, %rbx         #!!! tmp
  addq SPACE_LEFT, %rbx

  loopExpandeHeap:
  cmpq %rdx, %rbx
  jge expandeBrk
    addq $4096, %rbx       #!!! tmp
    jmp loopExpandeHeap

  #rbx contem quantidade que deve ser efetivamente alocada + SPACE_LEFT

  expandeBrk:
  subq SPACE_LEFT, %rbx # rbx recebe quantidade a ser alocada
  movq $12, %rax
  pushq %rdi            # salva valor de rdi na stack
  pushq %rcx            # salva valor de rcx na stack
  pushq %rdx            # salva valor de rdx na stack
  movq HEAP_END, %rdi
  addq %rbx, %rdi
  syscall               # expande brk
  popq %rdx             # restaura valor inicial de rdx
  popq %rcx             # restaura valor inicial de rcx
  popq %rdi             # restaura valor inicial de rdi
  movq %rax, HEAP_END   # seta novo HEAP_END
  movq $1, 0(%rcx)      # seta flag de "ocupado" no header
  movq %rdi, 8(%rcx)    # seta o tamanho da alocacao no header

  addq %rcx, %rdx       # rdx recebe (endereco de inicio da nova alocacao + (rdi+16))
  movq HEAP_END, %rbx
  subq %rdx, %rbx       # rbx recebe (endereco da brk - rdx), espaco que sobrou na heap
  movq %rbx, SPACE_LEFT

  movq %rcx, %rax       # rax recebe endereco do inicio da nova alocacao
  addq $16, %rax
   
  pop %rbp
  ret


liberaMem:
# rdi possui endereco de espaco a ser liberado
  pushq %rbp
  movq %rsp, %rbp

  movq $0, -16(%rdi)        # Seta flag pra zero

# Retorna
  pop %rbp
  ret

main:
#Inicia main e declara variaveis
  pushq %rbp
  movq  %rsp, %rbp
  subq  $32, %rsp 

# Configura alocador
  call iniciaAlocador

# Aloca bytes
  movq $8, %rdi
  call alocaMem
  movq %rax, -16(%rbp)

# Aloca bytes
  movq $16, %rdi
  call alocaMem
  movq %rax, -24(%rbp)

# Desaloca bytes
  movq -16(%rbp), %rdi
  call liberaMem

# Desaloca bytes
  movq -24(%rbp), %rdi
  call liberaMem

# Destroi alocador
  call finalizaAlocador

#Finaliza programa
  movq  $60, %rax
  syscall
