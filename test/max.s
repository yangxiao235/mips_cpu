#
# 求整数数组中最大的一项
# slt等
#
    .data
array: .word 1, -1, 4, -3, 0
    .text
    .globl main
main:
    la  $s0, array # array
    lw  $t0, 0($s0) # max
    addi $t1, $zero, 16 # i <- len - 1

loop:
    add  $s2, $s0, $t1  # array + i
    beq $t1, $zero, done # i == 0 ?
    lw  $t2, ($s2)      # tmp <- array[i]
    slt $t3, $t0, $t2  # max < tmp ? 1: 0
    beq $t3, $zero, not_less  # max >= tmp, nothing to do with max
    add $t0, $t2, $zero # max < tmp => max <- tmp
not_less:
    addi $t1, $t1, -4 # i <- i - 4
    j loop

done:
    addi $v0, $zero, 1 # 这里需要说明, 赋值可用ori, 因为ori比addi更快. 然而, 单周期指令的情况下都一样.
    add  $a0, $t0, $zero # max.
    syscall

# 退出
    addi $v0, $zero, 10
    syscall


