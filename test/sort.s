#
# 将内存中的整数数组按照反序排列
# 指令: lw, sw
#
    .data
array: .word 1,2,3,4,5

    .text
    .globl main

main:
    la $s0, array # base
    lw $t0, 0($s0) # 1
    lw $t1, 4($s0) # 2
    lw $t2, 8($s0) # 3
    lw $t3, 12($s0) # 4
    lw $t4, 16($s0) # 5

    sw $t4, 0($s0) # 5
    sw $t3, 4($s0) # 4
    sw $t2, 8($s0) # 3
    sw $t1, 12($s0) # 2
    sw $t0, 16($s0) # 1

    # 打印数组
    addi $v0, $zero, 1

    lw $a0, 0($s0) # 5
    syscall
    lw $a0, 4($s0) # 4
    syscall
    lw $a0, 8($s0) # 3
    syscall
    lw $a0, 12($s0) # 2
    syscall
    lw $a0, 16($s0) # 1
    syscall

    addi $v0, $zero, 10 # exit
    syscall
