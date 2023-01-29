.section .data
  str1:       .string "ESTE EH UM TESTE"
  str2:       .string "\n=== API de alocação de memoria ===\n"
  str3:       .string "%p\n"
  str4:       .string "%s\n"
  str5:       .string "%d\n"
  HEAP_START: .quad 0
  HEAP_END:   .quad 0

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
# Registro de ativacao
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
  # rax = 0
  # rcx = 0
  # rbx = heap_start + 16
  # enquanto rbx < heap_end
  #   se (-8(rbx) >= rdi) && (-16(rbx) == 0) 
  #     se (rcx == 0) || (-8(rbx) < rcx)
  #       rcx = -8(%rbx)
  #       rax = rbx
  #   rbx = rbx + -8(rbx)
  
  movq $0, %rax
  movq $0, %rcx
  movq HEAP_START, %rbx
  addq $16, %rbx            # rbx aponta para o final do header

  loopBestFit:
  cmpq %rbx, HEAP_END
  jle fimLoopBestFit
  movq -8(%rbx), %rdx       # rbx recebe tamanho da alocacao
  
  if1:
  cmpq %rdi, %rdx           # Se tem espaço para a alocacao
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
          movq %rdx, %rcx
  
  incrementaLoopBestFit:
  addq %rdx, %rbx           # rbx aponta para proxima alocacao de memoria
  addq $16, %rbx
  jmp loopBestFit
  fimLoopBestFit:

# Se não achou espaço, abre novo espaço
  if4:
  cmpq $0, %rax
  jne if4_else
    call expandeHeap          # Expande a heap
  if4_else:
    movq $1, -16(%rax)        # Seta flag para 1
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
  jge calcMult
  movq $0, %rax
  jmp returnAlocaMem  #Se tamanho menor que 1, retorna 0
  
  calcMult:
# quantidade a alocar esta em rdi | mod 4096 | rbx multiplicador | rcx resultado final
  movq $1, %rbx
  loop_mult:
  movq $8, %rcx
  imul %rbx, %rcx
  addq $1, %rbx
  cmpq %rdi, %rcx
  jl loop_mult

# Testa se a heap esta vazia
  movq HEAP_START, %rbx
  cmpq %rbx, HEAP_END
  jg callBuscaBestFit   # Se heap não vazia, chama bestFit
  
  movq %rcx, %rdi
  call expandeHeap
  jmp returnAlocaMem

  callBuscaBestFit:
  movq %rcx, %rdi
  call BuscaBestFit
  
  returnAlocaMem:
# Retorna
  pop %rbp
  ret


expandeHeap:
  pushq %rbp
  movq %rsp, %rbp
  subq $16,%rsp

# expande brk, rdi tem o tamanho da alocacao
  movq %rdi,-8(%rbp)    # Salva tamanho da alocacao na stack
  movq $12, %rax
  movq HEAP_END, %rbx
  addq $16, %rbx        # rbx aponta para o fim do header da nova alocacao
  addq %rbx, %rdi       # rdi recebe nova posicao do brk
  movq %rbx, -16(%rbp)  # Salva valor de rbx na stack, pois tem que retornar na chamada
  syscall
  movq -16(%rbp), %rbx  # Retorna valor de rbx 
  movq %rax, HEAP_END   # Atualiza fim da heap
  movq $1, -16(%rbx)    # Seta flag da memoria alocada pra 1
  movq -8(%rbp), %rcx   # rcx recebe tamanho da alocacao
  movq %rcx, -8(%rbx)   # Configura flag com tamanho da memoria alocada
  movq %rbx, %rax       # Seta pointeiro alocado como retorno da funcao

# Desfaz stack e retorna
  movq -8(%rbp),%rdi
  addq $16,%rsp
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
  subq  $40, %rsp 

# Configura alocador
  call iniciaAlocador

# loop:
#   movq -16(%rbp), %rbx
#   cmpq $5, %rbx
#   jge fim_loop 

# Aloca bytes
  movq $15, %rdi
  call alocaMem
  movq %rax, -8(%rbp)

# Aloca bytes
  movq $7, %rdi
  call alocaMem
  movq %rax, -16(%rbp)

# Aloca bytes
  movq $25, %rdi
  call alocaMem
  movq %rax, -24(%rbp)

# Aloca bytes
  movq $40, %rdi
  call alocaMem
  movq %rax, -32(%rbp)

# Desaloca bytes
  movq -8(%rbp), %rdi
  call liberaMem

# Desaloca bytes
  movq -24(%rbp), %rdi
  call liberaMem

# Aloca bytes
  movq $20, %rdi
  call alocaMem
  movq %rax, -24(%rbp)


#  movq -16(%rbp), %rbx
#  addq $1, %rbx
#  movq %rbx, -16(%rbp)
#  jmp loop
#fim_loop:

# Destroi alocador
  call finalizaAlocador

#Finaliza programa
  movq  $60, %rax
  syscall
