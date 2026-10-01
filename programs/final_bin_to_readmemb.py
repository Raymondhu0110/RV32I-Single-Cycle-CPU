# ==========================================
# final_bin_to_readmemb.py
#
# final_program.bin
#        ↓
#   ┌──────────────┐
#   ↓              ↓
# imem_code.txt   dmem_data.txt
# ==========================================

from pathlib import Path

# Resolve paths relative to this Python script.
PROGRAMS_DIR = Path(__file__).resolve().parent
MEMORY_DIR = PROGRAMS_DIR.parent / "memory"
MEM_DEPTH = 16384

# Final Program memory layout
TEXT_START = 0x0000
TEXT_END   = 0x006F

DATA_START = 0x1070
DATA_END   = 0x1073


# ==========================================
# Read final binary
# ==========================================
with open(PROGRAMS_DIR / "final_program.bin", "rb") as f:
    program = f.read()


# ==========================================
# Generate IMEM
#
# Only copy instruction bytes:
# 0x0000 ~ 0x006F
#
# Everything else = 0
# ==========================================
with open(MEMORY_DIR / "final_imem_code.txt", "w") as f:

    for address in range(MEM_DEPTH):

        if TEXT_START <= address <= TEXT_END:
            byte = program[address]
        else:
            byte = 0

        f.write(f"{byte:08b}\n")


# ==========================================
# Generate DMEM
#
# global_offset:
# 0x1070 ~ 0x1073
#
# Everything else initially = 0
# ==========================================
with open(MEMORY_DIR / "final_dmem_code.txt", "w") as f:

    for address in range(MEM_DEPTH):

        if DATA_START <= address <= DATA_END:
            byte = program[address]
        else:
            byte = 0

        f.write(f"{byte:08b}\n")


print("Generation complete.")
print("memory/final_imem_code.txt generated.")
print("memory/final_dmem_code.txt generated.")
