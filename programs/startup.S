.section .text.start
.globl _start

_start:
    lui  x2, 0x4
    addi x2, x2, -16

    jal  x1, main

end:
    jal  x0, end