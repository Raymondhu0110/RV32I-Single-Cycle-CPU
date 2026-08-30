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


## Decoder Verification

**Testbench:** `tb/decoder_tb.v`

The Decoder testbench verifies instruction classification and control-signal generation based on the instruction opcode. It also checks selected instruction-field outputs (`rd`, `rs1`, `rs2`, `funct3`, and `funct7`) that are extracted directly from fixed instruction bit fields.

| Instruction Class | Verification Coverage |
| --- | --- |
| R-type ALU | Register-source ALU operation and register write-back control |
| I-type ALU | Immediate ALU operation and register write-back control |
| Load | Address calculation, memory read, and memory-to-register write-back |
| Store | Address calculation and memory write control |
| Branch | Branch comparison control |
| `LUI` | Immediate write-back selection |
| `AUIPC` | PC-plus-immediate write-back selection |
| `JAL` | Jump control and `PC + 4` write-back |
| `JALR` | ALU-generated jump target and `PC + 4` write-back |
| Illegal opcode | Assertion of `illegal_ins` for an unsupported opcode |

The primary verification focus is the mapping from each supported opcode to the expected datapath control signals. Instruction fields that are directly extracted from fixed bit positions are also checked in representative cases.

An unsupported opcode is applied to verify that `illegal_ins` is asserted. The testbench also generates `decoder_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## Immediate Generator Verification

**Testbench:** `tb/ImmediateGenerator_tb.v`

The Immediate Generator testbench verifies immediate-field reconstruction and extension for the instruction formats that require immediate operands. The tests cover both contiguous and split immediate encodings, including sign extension and the implicit low-order zero bit used by branch and jump offsets.

| Immediate Type | Verification Coverage |
| --- | --- |
| I-type | Positive and negative sign extension; ALU-immediate, load, and `JALR` cases |
| S-type | Split-field reconstruction with positive and negative immediates |
| B-type | Split-field reconstruction with positive and negative offsets, including sign extension and implicit `imm[0] = 0` |
| U-type | Upper-immediate placement in bits `[31:12]` with the lower 12 bits cleared; `LUI` and `AUIPC` |
| J-type | Split-field reconstruction with positive and negative offsets, including sign extension and implicit `imm[0] = 0` |
| Illegal opcode | Assertion of `illegal_ins` for an unsupported opcode |

Positive and negative immediates are tested for I-, S-, B-, and J-type formats to verify correct reconstruction and sign extension to 32 bits. B- and J-type tests additionally verify the split immediate encoding and the implicit low-order zero bit used by PC-relative branch and jump offsets.


## Datapath Component Verification

Several simple combinational datapath components are verified with dedicated testbenches. Because these modules primarily implement multiplexing and address-generation behavior, their verification coverage is summarized together.

| Module | Testbench | Verification Coverage |
| --- | --- | --- |
| ALU Source MUX | `tb/mux_alusrc_tb.v` | Verifies both ALU operand selections: register data (`ALUSrc = 0`) and generated immediate (`ALUSrc = 1`) |
| Memory-to-Register MUX | `tb/mux_memtoreg_tb.v` | Verifies all five supported register write-back sources, illegal `MemtoReg` encodings, and recovery from an illegal control state |
| PC Source MUX | `tb/mux_pcsrc_tb.v` | Verifies `PC + 4`, `PC + immediate`, and JALR target selection, including clearing bit 0 of the JALR target; also verifies illegal `PCSrc` detection and recovery |
| PC Adder | `tb/pc_adder_tb.v` | Verifies `PC + 4`, positive and negative PC-relative offsets, and 32-bit address wrap-around |

The ALU Source MUX testbench verifies both possible selections of the second ALU operand. The Memory-to-Register MUX testbench covers the five implemented write-back sources: ALU result, memory data, `PC + 4`, immediate, and `PC + immediate`. Unsupported `MemtoReg` values are also tested to verify `illegal_control`.

The PC Source MUX verifies all implemented next-PC paths. In addition to sequential execution and PC-relative branch/jump targets, the JALR path is tested with both even and odd ALU-generated addresses. An odd target such as `0x00003005` is converted to `0x00003004`, verifying the RISC-V requirement that bit 0 of the JALR target is cleared.

The PC Adder testbench verifies both forward and backward PC-relative address generation using positive and negative immediates. It also checks 32-bit wrap-around behavior at the upper address boundary.

Each testbench generates a VCD file for optional waveform inspection and debugging.

**Result:** PASS
U-type tests verify that the 20-bit immediate field is placed in bits `[31:12]` of the generated value while the lower 12 bits are cleared. Both `LUI` and `AUIPC` opcode cases are covered.

The testbench also verifies that an unsupported opcode asserts `illegal_ins`. It generates `imm_gen_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## Program Counter Verification

**Testbench:** `tb/PC_tb.v`

The Program Counter testbench verifies the sequential update behavior of the PC register, including asynchronous reset, clock-controlled updates, enable-based hold behavior, and reset priority.

| Test Category | Verification Coverage |
| --- | --- |
| Asynchronous reset | Verifies that asserting active-low `rst_n` immediately clears the PC without waiting for a clock edge |
| Enabled update | Verifies that `pc` captures `next_pc` on the rising clock edge when `enable = 1` |
| Disabled hold | Verifies that the previous PC value is preserved when `enable = 0` |
| Clocked behavior | Verifies that changes to `next_pc` do not affect the PC before a rising clock edge |
| Reset during operation | Verifies that asynchronous reset clears the PC while the processor is otherwise enabled |
| Reset priority | Verifies that reset overrides `enable` when both conditions are active |
| Recovery | Verifies normal PC updates after reset is released |

The testbench distinguishes asynchronous reset behavior from normal clocked PC updates. In particular, changing `next_pc` alone does not modify the stored PC value; the update occurs only on a rising clock edge when `enable` is asserted.

Reset priority is also explicitly tested by keeping `enable` asserted while `rst_n` remains low. The PC remains cleared, confirming that reset takes precedence over normal state updates.

The testbench automatically records pass/fail results and reports a final summary. It also generates `pc_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## Register File Verification

**Testbench:** `tb/regfile_tb.v`

The Register File testbench verifies synchronous register writes, asynchronous dual-port reads, write-enable behavior, x0 protection, reset behavior, and access across the 5-bit register address range.

| Test Category | Verification Coverage |
| --- | --- |
| Reset | Verifies that registers x1–x31 are cleared by the asynchronous active-low reset |
| Register write/read | Writes 32-bit values on rising clock edges and verifies correct read-back |
| Dual-port read | Verifies simultaneous reads from two different registers through `rdata1` and `rdata2` |
| Write disable | Verifies that `we = 0` prevents modification of the selected register |
| x0 behavior | Verifies that x0 always reads zero and rejects attempted writes |
| Address range | Verifies access to x31, covering the upper end of the 5-bit register address space |
| Write timing | Verifies that register contents do not change before the rising clock edge and are updated at the edge |
| Runtime reset | Verifies that asynchronous reset clears previously written register values during operation |

The reset test iterates through registers x1–x31 and verifies that every register has been cleared. A testbench flag is used to combine these individual checks into a single reset pass/fail result.

Register writes are verified as synchronous operations: write data does not become visible before the rising clock edge, and a write occurs only when `we` is asserted. In contrast, the two read ports are combinational and are tested simultaneously using independently selected register addresses.

The architectural x0 register is verified separately. Both read ports return zero when addressing x0, and an attempted write to x0 does not change its externally visible value.

The testbench automatically records pass/fail results and reports a final summary. It also generates `regfile_wave.vcd` for optional waveform inspection and debugging.

**Result:** PASS


## CPU Integration Verification

**Testbench:** `tb/RV32I_top_tb.v`

The complete processor is verified at the integration level by executing a small hand-defined RV32I program. Unlike the module-level tests, this testbench verifies that the individual datapath and control modules operate correctly when connected as a complete processor.

The test program performs the following instruction sequence:

```text
ADDI x1, x0, 5
ADDI x2, x0, 7
ADD  x3, x1, x2
SUB  x4, x3, x1
JAL  x0, 0
```

The final `JAL` instruction forms a self-loop at PC = 16. The testbench monitors execution until this PC value is observed for three consecutive cycles, with a maximum-cycle limit used to prevent an incorrect processor state from causing an infinite simulation.

| Integration Check | Expected Behavior |
| --- | --- |
| Program completion | Processor reaches and remains in the final `JAL` loop at PC = 16 |
| Register results | `x1 = 5`, `x2 = 7`, `x3 = 12`, and `x4 = 7` |
| x0 behavior | Every observed read of x0 returns zero |
| Illegal-condition monitoring | No illegal-condition signal is observed during program execution |

Illegal-condition outputs from the Decoder, Branch/Jump Unit, Immediate Generator, ALU Controller, Data Memory, Memory-to-Register MUX, and PC Source MUX are monitored throughout execution. Sticky verification flags record any illegal condition once it occurs, ensuring that a transient error cannot be hidden by the signal returning to zero later.

The testbench also monitors architectural x0 behavior during execution. Whenever either source-register address selects x0, the corresponding register-file read output is checked to ensure that it remains zero.

Execution is observed cycle by cycle, allowing the current PC, instruction, register state, and control behavior to be correlated with the generated `RV32I_top_wave.vcd` waveform. If an integration error occurs, the failing instruction can therefore be located in the execution sequence and traced through the relevant datapath and control signals.

This integration test verifies the interaction of instruction fetch, decode, register access, ALU execution, PC update, and register write-back across multiple instructions rather than testing these components in isolation.

The testbench automatically records pass/fail results and reports a final summary. It also generates `RV32I_top_wave.vcd` for cycle-by-cycle waveform inspection and debugging.

**Result:** PASS


## End-to-End Software Verification

**Testbench:** `tb/RV32I_final_tb.v`

The final verification stage executes a bare-metal C program compiled for RV32I using the RISC-V GCC toolchain. This test extends beyond the hand-defined integration program by verifying the processor with compiler-generated instructions, initialized global data, stack usage, function calls, memory accesses, conditional control flow, and function return behavior.

The processor executes the program until it reaches the final self-loop at PC = `0x0000006C`. A maximum-cycle limit is used to prevent an incorrect processor state from causing an infinite simulation.

| End-to-End Check | Expected Behavior |
| --- | --- |
| Program completion | Processor reaches the final loop at PC = `0x0000006C` |
| Global data initialization | `global_offset` at DMEM address `0x1070` contains `50000` |
| C program result | `final_result` at DMEM address `0x1074` contains `150` |
| Stack placement | Stack pointer `x2` remains within the implemented 16 KiB DMEM address range |
| Current illegal conditions | All illegal-condition outputs are zero at the end of execution |
| Full-execution illegal monitoring | No illegal-condition output was observed during program execution |

The initialized global variable `global_offset` is read directly from DMEM and checked against its expected value of `50000`. This verifies that initialized program data is correctly represented in the generated data-memory image.

The final program result is also read directly from DMEM. The expected value of `150` verifies that the compiler-generated program successfully executes the required arithmetic, shift, load/store, branch, function-call, and function-return behavior.

The stack pointer is checked against the implemented memory depth to ensure that stack execution remains within the processor's 16 KiB data-memory address range.

As in the CPU integration test, illegal-condition outputs from the Decoder, Branch/Jump Unit, Immediate Generator, ALU Controller, Data Memory, Memory-to-Register MUX, and PC Source MUX are monitored throughout execution. Sticky verification flags preserve any illegal condition observed during execution, allowing transient errors to be detected even if the corresponding signal later returns to zero.

The final test therefore verifies the complete execution path from compiler-generated software and initialized memory images through processor execution to the expected architectural and memory state.

The testbench automatically records pass/fail results and reports a final summary. It also generates `RV32I_final_wave.vcd` for cycle-by-cycle waveform inspection and debugging.

**Result:** 6/6 checks passed
