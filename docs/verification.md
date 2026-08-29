## ALU Verification

**Testbench:** `tb/ALU_tb.v`

The ALU testbench is a self-checking combinational testbench that verifies the arithmetic, logical, shift, and comparison operations implemented by the ALU.

Each test applies an operation code and two 32-bit operands, waits for the combinational outputs to settle, and compares the resulting outputs against the expected values.

| Test | Operation | Verification Target |
| --- | --- | --- |
| 1 | `ADD` | Addition result |
| 2 | `ADD` | Zero-result detection |
| 3 | `SUB` | Subtraction result |
| 4 | `SUB` | Zero-result detection |
| 5 | `SLL` | Logical left shift |
| 6 | `SLT` | Signed comparison — true case |
| 7 | `SLT` | Signed comparison — false case |
| 8 | `SLTU` | Unsigned comparison — false case |
| 9 | `SLTU` | Unsigned comparison — true case |
| 10 | `XOR` | Bitwise XOR |
| 11 | `SRL` | Logical right shift with zero fill |
| 12 | `SRA` | Arithmetic right shift with sign extension |
| 13 | `OR` | Bitwise OR |
| 14 | `AND` | Bitwise AND |
| 15 | Unsupported `op` | Default ALU output behavior |

Signed and unsigned comparisons are tested separately using operand values whose interpretation differs depending on signedness. Logical and arithmetic right shifts are also tested independently to verify zero-fill and sign-extension behavior.

The testbench automatically records pass/fail results for each test case and reports a final summary. It also generates `alu_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## ALU Controller Verification

**Testbench:** `tb/alu_controller_tb.v`

The ALU Controller testbench verifies that combinations of `ALUop`, `funct3`, and `funct7` are correctly translated into the ALU operation code (`op`). It also verifies that unsupported instruction encodings assert the `illegal_alu` output.

| Instruction Class | Verification Coverage |
| --- | --- |
| Direct ALU control | `ALUop = 00` → `ADD` |
| Branch | `BEQ`, `BNE` → `SUB`; `BLT`, `BGE` → `SLT`; `BLTU`, `BGEU` → `SLTU` |
| I-type ALU | `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI` |
| R-type ALU | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| Illegal encodings | Invalid branch `funct3` and invalid I-type/R-type shift or arithmetic `funct7` combinations |

The testbench covers the defined ALU-control mappings for branch, I-type ALU, and R-type instructions. Cases that require `funct7` to distinguish operations, such as `ADD`/`SUB`, `SRL`/`SRA`, and `SRLI`/`SRAI`, are tested separately.

Representative unsupported encodings are also applied to verify that `illegal_alu` is asserted instead of treating the encoding as a valid ALU operation. The testbench also generates `alu_controller_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


