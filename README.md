# RV32I Single-Cycle CPU

A 32-bit single-cycle RV32I processor implemented in Verilog, featuring separate byte-addressed instruction and data memories with little-endian organization. The processor supports integer arithmetic and logical operations, load/store instructions, conditional branches, and jump instructions. The complete design was verified by executing a bare-metal C program compiled with the RISC-V GCC toolchain.

## Key Features

- 32-bit RV32I single-cycle datapath
- 32 × 32-bit register file with x0 hardwired to zero
- Separate 16 KiB byte-addressed instruction and data memories
- Little-endian memory organization
- Support for R-, I-, S-, B-, U-, and J-type instruction formats
- Conditional branch and jump support, including JAL and JALR
- Separate illegal-condition indicators for major control blocks
- Bare-metal C program execution using the RISC-V GCC toolchain

