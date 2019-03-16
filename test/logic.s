#
# 逻辑运算指令测试
# and, or
#





    .text
    .globl main
main:
    addi $t0, $zero, 0x0f0f
    addi $s0, $zero, 0xf0ff
    and $s0, $s0, $t0

    addi $t0, $zero, 0xf0f0
    addi $s1, $zero, 0xff0f
    or   $s1, $s1, $t0

    # 显示and, or结果
    addi $v0, $zero, 34  # syscall 34, print integer in hexadecimal
    add $a0, $s0, $zero
    syscall  # and, 0x0000_000f

    add $a0, $s1, $zero
    syscall  # or, 0xffff_ffff

    addi $v0, $zero, 10
    syscall
