# Memory Images

| Files | Used by |
| --- | --- |
| `top_imem_code.txt`, `top_dmem_code.txt` | Early assembly-based CPU integration test |
| `final_imem_code.txt`, `final_dmem_code.txt` | Final GCC-compiled C program test |

## Early Assembly Test

`top_imem_code.txt` contains the machine code for a simple assembly program used during early CPU testing:

```asm
.section .text
.globl _start

_start:
    addi x1, x0, 5
    addi x2, x0, 7
    add  x3, x1, x2
    sub  x4, x3, x1

end:
    jal  x0, end
```

The program tests basic arithmetic instructions and an unconditional jump. It does not execute any load or store instructions, so `top_dmem_code.txt` contains only zeros.

The final memory images are used for the more comprehensive GCC-compiled C program test. See [Programs](../programs/README.md) for the build instructions.
