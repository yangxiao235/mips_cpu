#
# Calculating sum of 1 to 100.
# for (int i = 0, sum = 0; i < 100; ++i)
#   sum += i;
# Instructions for testing:
# arithmetic inst., branch inst., jump inst..
#

    .text
    .globl main
main:
    add $s1, $zero, $zero # sum
    addi $t0, $zero, 100   # i
    addi $t1, $zero, 1
loop:
    beq $t0, $zero, done  # i == 0 ?
    add $s1, $s1, $t0 #  sum <- sum + i
    sub $t0, $t0, $t1 # i <- i - 1
    j loop

done:
    # print sum
    addi $v0, $v0, 1  # syscall 1 (print integer)
    add $a0, $s1, $zero # integer to print
    syscall

    addi $v0, $zero, 10  # exit
    syscall

