.section .data
  str1: .string "Digite dois numeros :\n"
  str2: .string "%d %d"
  str3: .string "Os numeros digitados foram %d %d \n"
.section .text
.globl main
main:
#Inicia Função Main
  pushq %rbp
  movq %rsp, %rbp

#Declara variaveis x e y
  subq $16, %rsp

#Printa digite dois numeros
  mov $str1, %rdi
  call printf

#Faz %rdx apontar para -16 de %rbp
  movq %rbp, %rax
  subq $16, %rax
  movq %rax, %rdx

#Faz %rsi apontar para -8 de %rbp
  movq %rbp, %rax
  subq $8, %rax
  movq %rax, %rsi

#Chamada do scanf
  mov $str2, %rdi
  call scanf

#Salva numeros lidos em %rdx e %rsi
  movq -16(%rbp ), %rdx
  movq -8(%rbp ), %rsi

#Printa os numeros
  mov $str3, %rdi
  call printf

#Finaliza programa
  movq $60, %rax
  syscall
