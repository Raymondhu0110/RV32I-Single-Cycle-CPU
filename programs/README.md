
# Programs

This directory contains the bare-metal C program, startup assembly, and binary conversion script used for the final RV32I processor verification.

The program is compiled using the xPack RISC-V GNU Toolchain, targeting RV32I with the ILP32 ABI.

## Build

Run the following commands from the `programs/` directory.

```powershell
# Compile and link the final bare-metal C program.
riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -O1 -ffreestanding -nostdlib -nostartfiles "-Wl,-Ttext=0x0" "-Wl,--no-relax" -o final_program.elf startup.S final_code.c

# Inspect the generated machine instructions.
riscv-none-elf-objdump -d -M no-aliases,numeric final_program.elf

# Extract the raw binary.
riscv-none-elf-objcopy -O binary final_program.elf final_program.bin

# Generate separate IMEM and DMEM initialization files.
python final_bin_to_readmemb.py
```

## Generated Memory Images

The conversion script generates two byte-addressed memory images:

| File | Contents |
| --- | --- |
| `imem_code.txt` | Instruction bytes from addresses `0x0000`–`0x006F`. |
| `dmem_data.txt` | Initialized global data from addresses `0x1070`–`0x1073`. |

Both files contain 16,384 lines of 8-bit binary values. Unused addresses are initialized to zero.

The generated files are loaded into the processor's separate instruction and data memories using `$readmemb`.

See [Memory Images](../memory/README.md) for the early assembly test and the memory files used in each verification stage.


## Verification

The generated memory images are used by `RV32I_final_tb.v` to execute the compiled C program on the single-cycle processor.

See [Verification](../docs/verification.md) for the test coverage and results.
