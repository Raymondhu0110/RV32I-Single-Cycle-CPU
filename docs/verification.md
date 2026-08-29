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


## Branch/Jump Unit Verification

**Testbench:** `tb/BJ_unit_tb.v`

The Branch/Jump Unit testbench verifies that branch, jump, and sequential-execution conditions generate the correct `PCSrc` selection. It also verifies branch taken/not-taken behavior using the ALU comparison outputs `zero`, `less_signed`, and `less_unsigned`.

| Control Class | Verification Coverage |
| --- | --- |
| Sequential execution | No branch or jump → `PCSrc = 00` (`PC + 4`) |
| JAL | `Jump = 1` → `PCSrc = 01` (`PC + immediate`) |
| JALR | `Jalr = 1` → `PCSrc = 10` (ALU-generated target) |
| Equality branches | `BEQ`, `BNE`, both taken and not taken |
| Signed branches | `BLT`, `BGE`, both taken and not taken |
| Unsigned branches | `BLTU`, `BGEU`, both taken and not taken |
| Illegal conditions | Unsupported branch `funct3` and conflicting `Branch`/`Jump`/`Jalr` control combinations |

All six conditional branch types are tested in both taken and not-taken cases. Signed and unsigned branch decisions are verified independently using `less_signed` and `less_unsigned`, while equality branches use the ALU `zero` output.

Unsupported branch encodings and mutually conflicting control signals are also tested to verify assertion of `illegal_ins`. The testbench generates `bj_unit_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## Data Memory Verification

**Testbench:** `tb/Data_mem_tb.v`

The Data Memory testbench verifies byte-addressed load/store behavior, little-endian byte ordering, signed and unsigned load extension, synchronous store timing, and memory-control legality.

Stores are performed synchronously on the rising clock edge, while loads are verified through the combinational read path. Stored values are reused by subsequent load tests so that write behavior, byte ordering, and read-back behavior can be verified together.

| Test Category | Verification Coverage |
| --- | --- |
| Idle / control | Idle behavior and legal load/store control states |
| Word access | `SW` followed by `LW` read-back |
| Byte access | `SB`, `LB`, and `LBU` |
| Halfword access | `SH`, `LH`, and `LHU` |
| Extension behavior | Sign extension for `LB`/`LH` and zero extension for `LBU`/`LHU` |
| Little-endian behavior | Correct byte ordering during word, halfword, and byte accesses |
| Partial stores | `SB` modifies only one byte and `SH` modifies only two bytes |
| Illegal control | Unsupported load/store `funct3`, simultaneous read/write, and recovery to idle |

The testbench verifies little-endian behavior through store/load read-back and partial-write cases. For example, after storing `0x11223344`, overwriting the byte at `addr + 1` with `0xAA` produces `0x1122AA44`, confirming both byte addressing and preservation of unaffected bytes.

Signed and unsigned loads are tested using values with the most significant byte or halfword bit set. This verifies that `LB` and `LH` perform sign extension while `LBU` and `LHU` perform zero extension.

Legal store operations are explicitly checked to ensure that they do not assert `illegal_control`. Unsupported load/store encodings and simultaneous `MemRead`/`MemWrite` activation are also tested to verify illegal-control detection and recovery to the normal idle state.

The testbench automatically records pass/fail results and reports a final summary. It also generates `dmem_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS
