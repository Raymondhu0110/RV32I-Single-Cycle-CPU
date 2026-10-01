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


Another detail I encountered while implementing the PC selection logic was the special handling required by `JALR`. Unlike a PC-relative branch or `JAL`, `JALR` calculates its target by adding a sign-extended immediate to the value in `rs1`. The lowest bit of the resulting address must then be cleared.

I implemented this behavior in the PCSrc MUX using `{alu_result[31:1], 1'b0}`. This allowed the ALU to perform the complete address calculation before the final target address was selected. It also helped me understand why the immediate itself should not have its lowest bit cleared: doing so before addition could produce a different target address.

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

Another adjustment involved the boundary between the Decoder and the Immediate Generator. Both modules had an `illegal` output for unsupported opcodes. Initially, I treated R-type instructions as illegal in the Immediate Generator because they do not contain an immediate field. However, an instruction that does not require an immediate is not necessarily an illegal instruction. I revised the Immediate Generator to recognize R-type instructions as valid and output `32'b0` for them. This made its behavior consistent with the Decoder and prevented a legal instruction from incorrectly triggering the processor's illegal-instruction indication.

### 2.4 Lessons in Control Architecture

Revising the ALU Controller taught me that instructions sharing the same execution hardware do not necessarily share the same decoding rules. Separating R-type and I-type control allowed me to interpret their instruction fields correctly instead of relying on an overly broad classification. The branch logic taught me a related but distinct lesson. Multiple instructions can share the same underlying computation while requiring different decisions about how the result is used. By separating instruction decoding, ALU operation selection, comparison, and branch decisions, I developed a clearer understanding of how control responsibilities could be distributed across the processor.



## 3. Designing the Memory System

My initial understanding of memory came from the kitchen analogy I had used while learning about the register file. Memory was the large storage room, located far from the cook, while the register file provided a small workspace close to the execution hardware. Videos explaining memory technologies and the memory hierarchy had already introduced me to the memory wall and the importance of data movement, but implementing memory in my own processor forced me to think about these concepts at a much more concrete level.

### 3.1 Rethinking Memory Organization

As I began connecting the processor modules, I learned to distinguish between Instruction Memory (IMEM), which stores the program, and Data Memory (DMEM), which stores data accessed by load and store instructions. This also changed how I understood the Program Counter. Initially, I imagined the PC as a simple counter moving from one instruction to the next. Learning that sequential execution advances by `PC + 4` made me realize that my instruction memory did not store one complete instruction at each byte address. Instead, each 32-bit instruction occupied four consecutive bytes.

Both memories in my final implementation are byte-addressed and have a capacity of 16 KiB. Instruction Memory combines four consecutive bytes to produce a 32-bit instruction, while Data Memory supports accesses of different widths. For the RV32I base ISA without compressed instructions, instruction addresses must be four-byte aligned, meaning that the lowest two bits of a valid instruction address are zero.

This led me to question my own design: **did Instruction Memory really need to be byte-addressed? Why not store an entire 32-bit instruction at each memory entry?** Byte addressing was clearly useful for Data Memory because the processor needed to support byte, halfword, and word accesses. Instruction Memory, however, only needed to fetch complete 32-bit instructions.

At first, I thought changing IMEM to word addressing would require modifying the PC Adder and several other modules that depended on PC values. Later, I understood that the internal memory organization and the architectural address did not have to be identical. A word-organized IMEM could still accept a byte-addressed PC and use its upper address bits to select the corresponding instruction. I retained the byte-addressed implementation, but exploring this alternative helped me distinguish the processor's architectural addressing rules from the internal organization of a memory module.

### 3.2 Designing Data Memory Access

Another important part of implementing Data Memory was understanding the relationship between combinational reads and synchronous writes. My initial intuition was simple: reading retrieves an existing value, while writing changes stored state. I therefore implemented combinational reads and clock-controlled writes, using separate Verilog blocks.

This choice also helped me understand the timing of my single-cycle processor. Between active clock edges, the current architectural state drives the combinational datapath. The processor calculates addresses, retrieves data, selects results, and prepares the values that may update architectural state. At the next active clock edge, enabled state elements—including the register file, PC, and Data Memory writes—capture their new values. The clock period must be long enough for the relevant combinational paths to settle before that edge.

As I expanded the supported instruction set, Data Memory became more complicated than Instruction Memory. Initially, I thought of it mainly as a place to read and write complete values. Supporting `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, and `SW` required it to interpret the instruction's `funct3` field and handle different access widths.

| Access | Behavior |
| --- | --- |
| `LB` | Read one byte and sign-extend it to 32 bits |
| `LBU` | Read one byte and zero-extend it to 32 bits |
| `LH` | Read two bytes and sign-extend the halfword |
| `LHU` | Read two bytes and zero-extend the halfword |
| `LW` | Read four bytes to form a 32-bit word |
| `SB` | Write the lowest byte of the source register |
| `SH` | Write the lowest two bytes of the source register |
| `SW` | Write all four bytes of the source register |

The distinction between signed and unsigned loads was especially important. Both operations retrieve the same stored bits, but they interpret those bits differently when extending the result to 32 bits. Stores, on the other hand, select how many of the source register's lower bytes are written to memory.

### 3.3 Implementing Little-Endian Storage

My initial memory implementation used big-endian byte ordering. However, I later decided to change it to little-endian because I found the relationship between the least significant byte and the lowest memory address more intuitive. I also wanted the memory organization to be consistent with the little-endian RISC-V software and memory images used in the project.

In little-endian storage, the least significant byte of a multi-byte value is placed at the lowest memory address. For example, storing `0x12345678` produces the following layout:

| Address | Stored Byte |
| --- | --- |
| `addr + 0` | `0x78` |
| `addr + 1` | `0x56` |
| `addr + 2` | `0x34` |
| `addr + 3` | `0x12` |

This ordering must be applied consistently to both loads and stores. A word load reconstructs the value by placing the byte at the lowest address in bits `[7:0]`, while a word store performs the reverse operation. Halfword accesses follow the same principle.

Changing the byte order also produced one of my more frustrating debugging experiences. When I converted Data Memory from big-endian to little-endian, I overlooked part of the original implementation. The resulting inconsistency caused verification failures that took time to trace back to the memory byte ordering. Once I found and corrected the remaining code, the memory behavior became consistent with the intended little-endian organization.

### 3.4 Separating Control Validation from Memory Writes

While implementing Data Memory, I also encountered a problem with the responsibility for generating `illegal_control`. I was accustomed to writing a `default` branch for each `case` statement, so my initial implementation attempted to handle illegal operations in both the combinational read logic and the sequential write logic. I eventually realized that this arrangement gave two different procedural blocks responsibility for driving the same signal. I revised the design so that illegal-operation detection was handled by combinational control logic, while the sequential block remained responsible for performing permitted memory writes at the active clock edge.

This separation made the behavior easier to reason about. The control logic checks the requested operation and produces the corresponding validity indication. The read path produces the requested data combinationally, while valid, enabled stores update memory synchronously.

Although this was a smaller change than redesigning the ALU Controller, it reinforced a similar lesson: **a control signal should have one clearly defined source, and the responsibility for deciding whether an operation is valid should be separated from the responsibility for updating stored state.**


## 4. Running Compiled C on a Bare-Metal CPU

After completing the processor and its initial integration tests, I wanted to move beyond manually prepared instructions and execute a program compiled from C. This introduced a new challenge: although my CPU could execute RV32I instructions, it did not have an operating system, a standard C runtime, or a conventional program loader. I needed to understand how the software toolchain produced machine code and how to prepare that code and its data for my own memory system.

### 4.1 From Assembly to Compiled C

I began by installing the xPack GNU RISC-V Embedded GCC toolchain for Windows and learning the roles of three tools: GCC for compiling, assembling, and linking; `objdump` for inspecting the instructions inside an ELF file; and `objcopy` for extracting a raw binary image.

My first experiment used a small hand-written assembly program. I compiled it for RV32I, inspected the resulting instructions, converted the ELF file into a binary image, and used a Python script to generate the text file required by Verilog's `$readmemb`.

The initial workflow was:

```text
Assembly source
      |
      v
     GCC
      |
      v
   ELF file
      |
      +----> objdump (inspect instructions)
      |
      v
   objcopy
      |
      v
  Raw binary
      |
      v
Python converter
      |
      v
  bin_code.txt
      |
      v
Instruction Memory
```

The experiment succeeded: Instruction Memory loaded the generated machine code, and the processor passed the corresponding test. However, this was still a relatively simple program that did not exercise Data Memory. I had confirmed that the basic instruction-loading workflow worked, but not that my processor could execute a compiled C program with functions, stack usage, and initialized global variables.

For the C program, I used compiler options including `-march=rv32i`, `-mabi=ilp32`, `-O1`, and `-ffreestanding`. I also disabled the standard startup files and libraries because my processor had no conventional runtime environment. Using `objdump` with `no-aliases,numeric` helped me inspect the resulting instructions using their explicit register numbers and instruction forms, making them easier to compare with my RTL implementation.

### 4.2 Bootstrapping the Processor

I designed the final C program to exercise more than arithmetic instructions. It included a function call, a structure, conditional execution, and an initialized global variable. I deliberately declared `global_offset` as `volatile` so that the compiler would preserve accesses to the variable rather than simply substituting its known value. I also used GCC's `noinline` attribute to preserve a separate function call, allowing me to observe the corresponding RISC-V calling convention and stack behavior.

This exposed a problem that my earlier assembly test had not encountered. When I inspected the compiled instructions, I found a stack allocation instruction:

```asm
addi x2, x2, -32
```

In the RISC-V calling convention, `x2` is the stack pointer. My register file initialized it to zero, so subtracting 32 produced `0xFFFFFFE0`, far outside my 16 KiB Data Memory address range of `0x00000000` to `0x00003FFF`. I realized that compiling a C program was not enough. A normal execution environment would establish the initial stack pointer before running the program, but my bare-metal processor had no such environment. I therefore wrote `startup.S` to perform the initialization explicitly:

```asm
lui  x2, 0x4
addi x2, x2, -16
```

These instructions initialize the stack pointer to `0x00003FF0`, near the top of Data Memory. After a 32-byte stack allocation, it becomes `0x00003FD0`, which is within the implemented memory range.

The startup code then calls `main`, providing a controlled entry point for the compiled C program. This was an important change in how I understood software execution: the first instruction of a program cannot always be its application logic. Even a small bare-metal program may depend on architectural state that must be established before its compiled code can execute correctly.

### 4.3 Bridging ELF and Harvard Memory

Once the stack pointer problem was addressed, I encountered another limitation of my earlier workflow. The simple assembly program only required an instruction image, but the C program contained an initialized global variable:

```c
volatile int global_offset = 50000;
```

My processor uses separate Instruction Memory and Data Memory arrays. Loading the entire raw binary into IMEM would not initialize the global variable in DMEM, even though the compiler and linker had already assigned it a location in the program image.

I inspected the ELF file and its binary representation to identify the locations required by each memory. In my final program, the instruction bytes occupied the region beginning at `0x0000`, while the initialized value of `global_offset` was located at `0x1070`. The program also used the following memory location, beginning at `0x1074`, for its final result.

I then wrote a Python converter to split the binary image into two separate initialization files:

```text
C source + startup.S
          |
          v
         GCC
          |
          v
       ELF file
          |
          +----> objdump
          |
          v
        objcopy
          |
          v
      Raw binary
          |
          v
    Python converter
       /        \
      v          v
 IMEM image   DMEM image
      |          |
      v          v
     IMEM       DMEM
```

The converter preserved the appropriate byte addresses and filled unused locations with zeros. This was necessary because my Verilog memories were byte-addressed arrays rather than a conventional program loader capable of interpreting an ELF file directly.

One of the most useful checks was confirming that the initialized global variable had actually reached the Data Memory image. The value `50000` is `0x0000C350`, so its little-endian representation at addresses `0x1070` through `0x1073` was:

```text
Address    Byte
0x1070     0x50
0x1071     0xC3
0x1072     0x00
0x1073     0x00
```

This confirmed that the value came from the compiled C program and had been transferred through the toolchain and converter, rather than being manually inserted into the testbench.

### 4.4 Verifying the Complete Execution Flow

With the startup code and separate memory images prepared, I could finally test the complete path from C source code to processor execution. The CPU fetched the compiled instructions from IMEM, used the initialized stack pointer for function execution, accessed the global variable in DMEM, and wrote its computed result back to memory.

The final testbench checked more than whether the simulation completed. It verified that execution reached the expected final loop, that `global_offset` retained its initialized value of `50000`, and that the computed result was `150`. It also checked the stack pointer and monitored illegal-instruction and illegal-control indications throughout execution.

This final test connected several parts of the project that I had previously verified independently. The ALU, control logic, register file, memories, branch and jump behavior, and software toolchain all had to work together for the compiled program to produce the expected result.


## 5. Debugging and Verification Lessons


### 5.1 Improving My Verification Approach

Writing testbenches gradually changed the way I thought about verification. Beyond checking whether each module produced the expected outputs, I sometimes designed additional experiments to better understand the behavior I was observing in simulation.

One example came from testing the Register File. My testbench already included a runtime asynchronous reset test, which asserted `rst_n` without waiting for a clock edge and verified that registers returned zero. However, I became curious about the registers' initial state. If a register already appeared to contain zero before reset, simply observing zero afterward would not help me visualize what the reset had changed. To investigate this, I deliberately selected nonzero register addresses before initialization and observed their unknown (`X`) values in simulation. After asserting reset, I could see those values become zero. This was an additional experiment to understand the initial state and reset behavior, rather than a replacement for the existing reset tests.

<p align="center">
  <img src="/images/regfile_reset_experiment.png" width="75%" alt="Register File reset experiment showing unknown values before reset and zero values afterward">
  <br>
  <em>Figure 6. An early Register File simulation experiment showing unknown register values before reset and zero values after reset was asserted.</em>
</p>

I also became more deliberate about testbench timing. Instead of relying entirely on fixed delays such as `#10`, I began synchronizing some checks with `@(posedge clk)` and inserting a short delay before examining the outputs. This allowed the simulator to process clock-triggered nonblocking assignments before the testbench checked their results.


### 5.2 Debugging the Simulation Environment

Not every problem I encountered came from incorrect Verilog logic. Some of the most frustrating failures were caused by the simulation environment and the way I organized my project.

One particularly simple mistake was modifying the source code but forgetting to save the file before compiling. I kept investigating why my changes had not fixed the problem, even though the simulator was still reading the previous version of the code.

I encountered another issue when loading machine code into Instruction Memory. I learned that `$readmemb` normally resolves a relative file path from the simulator's current working directory, rather than automatically searching relative to the Verilog source file. The location from which I executed `vvp` therefore mattered when loading `bin_code.txt`.

As the processor grew, manually listing every Verilog source file in the terminal became increasingly inconvenient. I learned to use an Icarus Verilog command file, `files.f`, to maintain the list of modules required for compilation:

```powershell
iverilog -g2012 -o RV32I_top_sim -c files.f
```

Even this small improvement led to an unexpected problem. Compilation repeatedly failed with the message `File name not terminated`. After investigating the file list, I discovered that the final line of `files.f` was missing its terminating newline. Adding it resolved the parsing error.

These incidents were small compared with implementing the datapath or debugging the control logic, but they were part of learning to manage a growing hardware project. They also reminded me to check the source files, build configuration, and execution environment before assuming that every simulation failure originated in the RTL.
