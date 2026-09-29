# Engineering Notes

This document records selected design decisions, architectural changes, and debugging lessons from the development of the RV32I single-cycle processor. Rather than providing a chronological development log, it focuses on the engineering reasoning that shaped the final implementation.

## 1. From Modules to a Complete Datapath

I began this project after a video explaining how CPUs work made me curious about what was actually happening inside a processor. At that point, however, concepts such as datapaths, instruction formats, and single-cycle execution were still unfamiliar to me. My understanding of the processor therefore developed together with the architecture itself: each new module answered one question, but usually created several new ones.

### 1.1 Learning to Think in Hardware

One of my first conceptual breakthroughs came from learning the D flip-flop. I pictured a row of DFFs as a line of workers holding data. When a whistle blows—the clock edge—each worker passes the value being held into the next state. The analogy was simplified, but it helped me understand an important distinction that I had previously missed: combinational signals continuously respond to their inputs, while registers provide state that changes at controlled clock events.

This changed the way I read Verilog. `wire`, `reg`, combinational logic, sequential logic, and the clock were no longer isolated syntax rules; they represented different roles in controlling when values are computed and when architectural state is allowed to change.

My earliest model of a CPU was still extremely rough. I imagined execution mainly as:

```text
Fetch → Decode → Execute
```

I thought of the decoder as receiving a task and producing a pattern of control values that told other hardware what to do. Many details of that model were incorrect, but one idea survived the rest of the project: binary encodings only become meaningful because the hardware is designed to interpret particular bit patterns in particular ways. That idea became much more concrete later when I encountered the actual RV32I `opcode`, `funct3`, and `funct7` fields.

### 1.2 Questioning Data Movement

The ALU was one of the first processor modules I implemented. My early ALU contained outputs such as `carry`, `zero`, `negative`, `overflow`, and `borrow`, before I fully understood which status information the final processor would actually need. As the architecture developed, that interface changed. The final ALU retained `zero`, `less_signed`, and `less_unsigned`, because those outputs directly supported the comparison and branch behavior used by the processor. This was an early example of an interface being refined according to the needs of the complete system rather than keeping signals simply because they were common in textbook ALU examples.

The register file raised a more fundamental question for me:

> If the ALU can compute a result, why does the processor need another storage structure between computation and memory?

I initially used a kitchen analogy to reason about it. The ALU was the cook, main memory was a large storage room, and the register file was a small workspace immediately beside the cook. Fetching every operand from distant storage for every operation would be inefficient, while keeping operands and intermediate values close to the execution hardware makes repeated computation practical.

The analogy was incomplete, but trying to break it exposed more interesting questions. If an ALU consumes two operands, how are both supplied? What happens when existing values must be read while a result is being written back? Why does the register file have two read ports but only one write port in this processor? Those questions made the register file stop looking like an unnecessary intermediate station and start looking like part of the processor's data-supply structure.

At one point I compared this problem to the game *Overcooked*. Supplying ingredients faster does not necessarily make a kitchen faster if the next station cannot consume them at the same rate. Likewise, improving one part of a computing system does not automatically improve the throughput of the entire system.

I was still mixing ideas from pipelines, caches, registers, and my single-cycle processor at the time, so many of the specific questions I asked were not yet well-formed. However, the broader question remained important:

> How should computation and data movement be organized so that the complete system works efficiently?

This was one of the points where my interest shifted from simply learning digital logic toward wanting to understand computer architecture. It also introduced an idea that continued throughout the project: optimizing an individual component is not sufficient if the surrounding system cannot use that improvement, and architectural design often involves balancing responsibilities and trade-offs across components.

### 1.3 From a Task List to a Controlled Datapath

The program counter and instruction memory changed my understanding again. My first mental model of the PC came from the task list in *Overcooked*: after one task is completed, the system moves to the next one. Learning about `PC + 4` made sequential instruction execution intuitive, but it immediately raised another question:

> If the processor normally moves to the next instruction, how does it decide not to?

That question eventually led me to branches and jumps. Before I understood instruction formats or even the term *single-cycle datapath*, I drew my first processor architecture from this task-oriented mental model. I imagined software producing a list of operations, instruction memory holding that list, and the processor moving through it while the decoder directed the required hardware.

<p align="center"> <img src="/images/datapath_initial.png" width="75%" alt="Initial processor concept"> <br> <em>Figure 1. Initial processor concept before instruction formats and detailed control paths were understood.</em> </p>

The drawing was incomplete and contained assumptions that were later revised, but it was useful because it exposed what I still could not explain. I could draw blocks and arrows, but I did not yet understand how the processor decided which paths should actually carry meaningful data for each instruction. **Multiplexers and control signals provided the missing idea.**

I began thinking of the datapath as a road network. The physical paths may all exist at the same time, but control signals act like traffic lights or valves that determine which values are allowed to affect the current operation. Signals such as `RegWrite`, `ALUSrc`, `MemRead`, `MemWrite`, `MemtoReg`, and eventually `PCSrc` therefore stopped looking like unrelated Boolean values. Together, they determine how the same hardware is reused by different instructions.

This also corrected an earlier software-like assumption I had been making. Hardware does not inspect a situation and "decide" what to do in the human sense. Combinational logic continuously produces results from its current inputs; control logic determines which results are selected and which state elements are allowed to update. My second architecture sketch began to reflect this change. Instead of only showing major functional blocks, it increasingly included the control paths and multiplexers required to coordinate them.

<p align="center">
  <img src="/images/datapath_v2.png" width="75%" alt="Developing processor datapath">
  <br>
  <em>Figure 2. Developing datapath with operand selection, immediate generation, and additional control signals.</em>
</p>

### 1.4 Growing into an RV32I Datapath

Understanding the 32-bit RV32I instruction formats caused the architecture to grow rapidly. R-type instructions introduced me to the actual roles of `opcode`, `rd`, `rs1`, `rs2`, `funct3`, and `funct7`. This replaced my earlier idea of an instruction as a generic "task code" with a much more concrete understanding: different instruction fields simultaneously identify operands, destinations, sub-operations, and instruction classes.

This also explained why the decoder alone was not enough to determine every ALU operation. As the supported instruction set expanded, I introduced an ALU Controller and expanded the ALU itself to support operations including `SLL`, `SLT`, `SLTU`, `SRL`, and `SRA`.

The processor was beginning to develop clearer responsibility boundaries:

| Module | Responsibility |
| --- | --- |
| Decoder | Identifies the instruction class and generates major datapath controls |
| ALU Controller | Translates `ALUop`, `funct3`, and `funct7` into a specific ALU operation |
| ALU | Performs arithmetic, logic, shifts, and comparisons |
| Branch/Jump Unit | Combines branch/jump controls with ALU comparison results to select the next-PC path |

Branches made these relationships especially clear. Supporting `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU` required more than adding new instructions to a table. The ALU had to provide the appropriate equality, signed-comparison, and unsigned-comparison information; the Branch/Jump Unit had to interpret those results; and the PC path needed a multiplexer capable of selecting a PC-relative target. My next architecture revision reflected these additional control relationships.

<p align="center">
  <img src="/images/datapath_v3.png" width="75%" alt="Processor datapath with branch control">
  <br>
  <em>Figure 3. Architecture revision incorporating branch decisions and next-PC selection.</em>
</p>

The Immediate Generator completed another major part of the architecture. Implementing I-, S-, B-, U-, and J-type immediates forced me to understand how instruction bits are reconstructed, sign-extended, and used by different datapaths. Adding `JAL`, `JALR`, `LUI`, and `AUIPC` then expanded both next-PC selection and register write-back. The write-back multiplexer eventually grew to support five sources, while the PC Source MUX selected among sequential execution, PC-relative targets, and the JALR target.

At this point, adding an instruction no longer meant simply "teaching the ALU another operation." An instruction could affect several parts of the processor simultaneously:

```text
Instruction encoding
        ↓
Decoder / ALU Controller
        ↓
Operand and immediate selection
        ↓
ALU / comparison behavior
        ↓
Memory access or PC selection
        ↓
Register write-back
```

The final conceptual datapath was therefore not something I designed in one step. It emerged through repeated revisions as I learned which data paths were required and which module should be responsible for each decision.

<p align="center">
  <img src="/images/datapath_final.png" width="75%" alt="Final conceptual datapath">
  <br>
  <em>Figure 4. Final conceptual datapath showing the expanded control, memory, write-back, and next-PC paths.</em>
</p>

Looking back at the four architecture sketches, the most important change is not simply that the final drawing contains more blocks and wires. The early diagrams represented the processor as a sequence of tasks moving between components. The later diagrams represent it as a controlled datapath in which instruction encoding, combinational computation, state, and control signals work together to determine the architectural state transition of each instruction.

That change in mental model—from asking what each individual module does to asking how responsibilities and data movement should be organized across the complete processor—was one of the most important outcomes of the project.



## 2. Refining the Control Architecture

As I became more familiar with the RV32I instruction formats, I began to reconsider some of my earlier control logic decisions. One of the most significant changes involved the ALU Controller. My initial design appeared reasonable when I understood only a limited set of instructions, but learning the remaining instruction formats exposed a fundamental problem in how I had classified ALU operations.

### 2.1 Rethinking ALU Control

My initial ALU Controller used a hierarchical decoding structure based on `ALUop`, `funct3`, and `funct7`. The main Decoder generated `ALUop` to identify the general operation category, while the ALU Controller interpreted the remaining instruction fields to select a specific ALU operation. 

Initially, I divided ALU operations into three categories:

| ALUop | Instruction Category | ALU Controller Behavior |
| --- | --- | --- |
| `00` | Load / Store | Force ADD for address calculation |
| `01` | Branch | Select SUB, SLT, or SLTU according to `funct3` |
| `10` | R-type / I-type ALU | Select the operation using `funct3` and `funct7` |

At first, combining R-type and I-type arithmetic instructions seemed reasonable. Both instruction types ultimately use the same ALU hardware: `ADD` and `ADDI`, for example, require the same addition operation once their operands have been selected. I initially focused on this similarity in execution rather than the differences in instruction encoding. However, after studying the complete RV32I instruction formats, I realized that the original classification contained a significant design flaw. In R-type instructions, `instruction[31:25]` represents `funct7`, which distinguishes operations such as `ADD` and `SUB`, or `SRL` and `SRA`. In ordinary I-type arithmetic instructions, those same bits are part of the immediate operand. Interpreting them unconditionally as `funct7` could therefore cause a valid I-type instruction to be incorrectly classified as illegal.

<p align="center">
  <img src="/images/instruction_formats_notes.png" width="90%" alt="Handwritten notes on the six RV32I instruction formats">
  <br>
  <em>Figure 5. My handwritten notes on the six RV32I instruction formats.</em>
</p>

I identified this problem by revisiting my earlier design after learning the instruction formats, rather than through a failing testbench. The issue was not that the ALU could not perform the required operations; it was that my ALU Controller did not correctly distinguish the meaning of the instruction fields before decoding them.

I redesigned `ALUop` to separate R-type and I-type arithmetic instructions:

| ALUop | Instruction Category | ALU Controller Behavior |
| --- | --- | --- |
| `00` | Load / Store | Force ADD for address calculation |
| `01` | Branch | Select SUB, SLT, or SLTU |
| `10` | I-type ALU | Decode I-type arithmetic and shift-immediate instructions |
| `11` | R-type ALU | Decode R-type arithmetic and logical instructions |

This separation allowed the ALU Controller to interpret each instruction format according to its actual encoding, rather than applying the same `funct7` checks to both categories. The distinction became especially clear when examining shift instructions. RV32I R-type instructions contain ten arithmetic and logical operations, so `funct3` alone cannot distinguish every operation. The combinations `funct3=000` and `funct3=101` use additional encoding bits to distinguish `ADD` from `SUB` and `SRL` from `SRA`, respectively. I-type arithmetic instructions present a related but different situation. Most use a 12-bit immediate operand, while `SLLI`, `SRLI`, and `SRAI` use a five-bit shift amount in RV32I. Their remaining upper instruction bits contain the encoding information needed to distinguish the shift operations and validate their instruction encodings. In particular, `SRLI` and `SRAI` share `funct3=101` and are distinguished by their upper encoding bits.

Studying these differences helped me understand that instruction encoding and ALU operation selection are related but separate concerns. Two instructions may perform the same ALU operation while requiring different decoding rules. The revised `ALUop` classification made that distinction explicit in my implementation.


### 2.2 Decoding Branch Instructions

While implementing the ALU Controller, I noticed an interesting feature of the six RV32I conditional branch instructions. Although they use six different `funct3` encodings, the ALU only needs three operations to support their comparisons: SUB, SLT, and SLTU.

The ALU Controller therefore maps each pair of branch instructions to the same operation:

| `funct3` | Branch | ALU Operation |
| --- | --- | --- |
| `000` | BEQ | SUB |
| `001` | BNE | SUB |
| `100` | BLT | SLT |
| `101` | BGE | SLT |
| `110` | BLTU | SLTU |
| `111` | BGEU | SLTU |

However, the six encodings cannot simply be reduced to three categories throughout the entire processor. Although the ALU Controller only needs to select the comparison operation, the Branch/Jump Unit still needs to distinguish the exact branch instruction. It uses `funct3` to determine whether the corresponding comparison result should cause a branch to be taken. For example, BEQ and BNE both require subtraction to determine whether two operands are equal, but they interpret the resulting `zero` flag in opposite ways. The same relationship applies to BLT/BGE and BLTU/BGEU, which respectively use signed and unsigned comparisons.

This helped me understand why the same instruction field may serve different purposes in different control modules. The ALU Controller interprets `funct3` to select the required comparison operation, while the Branch/Jump Unit uses it to distinguish the six branch conditions. The three ALU operations are sufficient for computation, but the six instruction encodings remain necessary for selecting the correct branch behavior.

### 2.3 Refining the ALU Interface and Module Responsibilities

My early ALU included five status outputs: `zero`, `carry`, `negative`, `overflow`, and `borrow`. At that stage, I was learning how arithmetic flags worked, but I had not yet determined which information the complete processor would actually need. After extending the ALU to support `SLL`, `SRL`, `SRA`, `SLT`, and `SLTU`, and studying the six conditional branch instructions, I reconsidered the ALU interface. Rather than retaining every status flag from the original design, I decided to expose three outputs that directly supported the processor's branch logic: `zero`, `less_signed`, and `less_unsigned`.

This change was also connected to how I wanted to divide responsibilities between modules. I assigned arithmetic and comparison operations to the ALU, while the Branch/Jump Unit would interpret the comparison results and determine the next-PC selection. The Branch/Jump Unit therefore uses three kinds of information: the `Branch`, `Jump`, and `Jalr` control signals generated by the Decoder; the comparison flags generated by the ALU; and the instruction's `funct3` field, which distinguishes individual branch conditions.

| Module | Responsibility |
| --- | --- |
| Decoder | Decodes the instruction and generates major control signals, including `Branch`, `Jump`, and `Jalr` |
| ALU Controller | Selects the ALU operation using `ALUop` and the relevant instruction fields |
| ALU | Performs the selected operation and generates `zero`, `less_signed`, and `less_unsigned` |
| Branch/Jump Unit | Interprets branch/jump controls, `funct3`, and comparison flags to generate `PCSrc` |

The distinction was particularly important for the Branch/Jump Unit. It did not need to perform subtraction or signed and unsigned comparisons itself. Instead, it received the results of those operations and determined whether the current instruction required sequential execution, a PC-relative branch or jump, or a JALR target. I did not choose this organization because I had demonstrated that it would produce the fastest processor. My goal was to establish clear responsibilities between the modules so that I could understand each part of the control architecture independently and verify its behavior with dedicated testbenches.

### 2.4 Lessons in Control Architecture

Revising the ALU Controller taught me that instructions sharing the same execution hardware do not necessarily share the same decoding rules. Separating R-type and I-type control allowed me to interpret their instruction fields correctly instead of relying on an overly broad classification. The branch logic taught me a related but distinct lesson. Multiple instructions can share the same underlying computation while requiring different decisions about how the result is used. By separating instruction decoding, ALU operation selection, comparison, and branch decisions, I developed a clearer understanding of how control responsibilities could be distributed across the processor.
