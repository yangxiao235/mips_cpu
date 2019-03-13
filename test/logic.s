#
# 逻辑运算指令测试
# and, or
#





    .text
    .globl main
main:
    addi $t0, $zero, 0x0f0f  # 20080f0f
    addi $s0, $zero, 0xf0ff  # 2010f0ff
    and $s0, $s0, $t0        # 02088024

    addi $t0, $zero, 0xf0f0  # 2008f0f0
    addi $s1, $zero, 0xff0f  # 2011ff0f
    or   $s1, $s1, $t0       # 02288825

    # 显示and, or结果
    addi $v0, $zero, 34  # syscall 34, print integer in hexadecimal, 20020022
    add $a0, $s0, $zero # 02002020
    syscall             # 0000000c

    add $a0, $s1, $zero # 02202020
    syscall             # 0000000c

    addi $v0, $zero, 10  # exit,  2002000a
    syscall              # 0000000c
