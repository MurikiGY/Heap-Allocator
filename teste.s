.section .data
  str1:       .string "ESTE EH UM TESTE\n"
  str2:       .string "%d\n"
  str3:       .string "%p\n"
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


imprime:
# Registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Imprime
  movq HEAP_END, %rax
  cmpq %rax, HEAP_START     # Previne segfault
  jge ret
  mov $str3, %rdi
  call printf

  ret:
# Retorna
  pop %rbp
  ret


malloca:
# registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Aumenta brk
  movq $12, %rax
  addq HEAP_END, %rdi
  syscall
  movq %rax, HEAP_END

# Retorna
  pop %rbp
  ret


desmalloca:
# registro de ativacao
  pushq %rbp
  movq %rsp, %rbp

# Diminui brk
  movq $12, %rax
  movq %rdi, %rbx
  movq HEAP_END, %rdi
  subq %rbx, %rdi
  syscall
  movq %rax, HEAP_END

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



# Aloca 100 bytes
  movq $100, %rdi
  call malloca

# Imprime nova alocacao muda brk
  movq HEAP_END, %rsi
  call imprime

# Desaloca 50 bytes
  movq $50, %rdi
  call desmalloca

# Imprime nova alocacao muda brk
  movq HEAP_END, %rsi
  call imprime

# Desaloca 50 bytes
  movq $50, %rdi
  call desmalloca

# Imprime nova alocacao muda brk
  movq HEAP_END, %rsi
  call imprime

# Aloca 100 bytes
  movq $100, %rdi
  call malloca

# Imprime nova alocacao muda brk
  movq HEAP_START, %rsi
  call imprime



# Destroi alocador
  call finalizaAlocador

#Finaliza programa
  movq  $60, %rax
  syscall
