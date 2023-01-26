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

imprime_inteiro:
# Registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Imprime
  mov $str5, %rdi
  call printf

# Retorna
  pop %rbp
  ret


imprime_ponteiro:
# Registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Imprime
  movq HEAP_END, %rax
  cmpq %rax, HEAP_START     # Previne segfault
  jge ret_pointer
  mov $str3, %rdi
  call printf

  ret_pointer:
# Retorna
  pop %rbp
  ret


imprime_string:
# Registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Imprime
  mov $str4, %rdi
  call printf

  ret_string:
# Retorna
  pop %rbp
  ret


alocaMem:
# registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# quant a alocar esta em rdi
# mod 4096
# rbx multiplicador
# rcx resultado final
  movq $1, %rbx
  loop_mult:
  movq $4096, %rcx
  imul %rbx, %rcx
  addq $1, %rbx
  cmpq %rdi, %rcx
  jl loop_mult

  movq %rcx, %rdi
  call expandeHeap

# Retorna
  pop %rbp
  ret

expandeHeap:
  pushq %rbp
  movq %rsp, %rbp

# expande brk, rdi tem o espaco a alocar
  movq %rdi, %rcx
  movq $12, %rax
  movq HEAP_END, %rbx
  addq $16, %rbx        # rbx aponta para o fim do header
  addq %rbx, %rdi
  syscall
  movq %rax, HEAP_END   # Atualiza fim da heap
  movq %rbx, %rax       # Retorna pointeiro alocado
  movq $1, -16(%rbx)    # Seta flag pra 1
  movq %rcx, -8(%rbx)   # Configura size

# Retorna
  pop %rbp
  ret


liberaMem:
# registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# rdi aponta para fim do header
  movq -16(%rdi), %rsi
  call imprime_inteiro
  movq -8(%rdi), %rsi
  call imprime_inteiro
  movq $0, -16(%rdi)        # Seta flag pra zero
  movq -16(%rdi), %rsi
  call imprime_inteiro

# Retorna
  pop %rbp
  ret


main:
#Inicia main e declara variaveis
  pushq %rbp
  movq  %rsp, %rbp
  subq  $16, %rsp 
  movq  $0, -16(%rbp)

# Configura alocador
  call iniciaAlocador

# Imprime algo
  mov $str2, %rsi
  call imprime_string

#imprime fim da heap
  movq HEAP_END, %rsi
  call imprime_ponteiro


loop:
  movq -16(%rbp), %rbx
  cmpq $5, %rbx
  jge fim_loop 

# Aloca bytes
  movq $100, %rdi
  call alocaMem

# Salva ponteiro
  movq %rax, -8(%rbp)

#imprime fim da heap
  movq HEAP_END, %rsi
  call imprime_ponteiro

# Desaloca bytes
  movq -8(%rbp), %rdi
  call liberaMem

  movq -16(%rbp), %rbx
  addq $1, %rbx
  movq %rbx, -16(%rbp)
  jmp loop
fim_loop:

# Destroi alocador
  call finalizaAlocador

#Finaliza programa
  movq  $60, %rax
  syscall
