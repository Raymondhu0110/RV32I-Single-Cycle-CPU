# Engineering Notes

This document records selected design decisions, architectural changes, and debugging lessons from the development of the RV32I single-cycle processor. Rather than providing a chronological development log, it focuses on the engineering reasoning that shaped the final implementation.

## 1. From Modules to a Complete Datapath

I began this project after a video explaining how CPUs work made me curious about what was actually happening inside a processor. At that point, however, concepts such as datapaths, instruction formats, and single-cycle execution were still unfamiliar to me. My understanding of the processor therefore developed together with the architecture itself: each new module answered one question, but usually created several new ones.

### 1.1 Learning to Think in Hardware

One of my first conceptual breakthroughs came from learning the D flip-flop.

I pictured a row of DFFs as a line of workers holding data. When a whistle blows—the clock edge—each worker passes the value being held into the next state. The analogy was simplified, but it helped me understand an important distinction that I had previously missed: combinational signals continuously respond to their inputs, while registers provide state that changes at controlled clock events.

This changed the way I read Verilog. `wire`, `reg`, combinational logic, sequential logic, and the clock were no longer isolated syntax rules; they represented different roles in controlling when values are computed and when architectural state is allowed to change.

My earliest model of a CPU was still extremely rough. I imagined execution mainly as:

```text
Fetch → Decode → Execute
```

I thought of the decoder as receiving a task and producing a pattern of control values that told other hardware what to do. Many details of that model were incorrect, but one idea survived the rest of the project: binary encodings only become meaningful because the hardware is designed to interpret particular bit patterns in particular ways.

That idea became much more concrete later when I encountered the actual RV32I `opcode`, `funct3`, and `funct7` fields.

### 1.2 Questioning Data Movement

The ALU was one of the first processor modules I implemented. My early ALU contained outputs such as `carry`, `zero`, `negative`, `overflow`, and `borrow`, before I fully understood which status information the final processor would actually need.

As the architecture developed, that interface changed. The final ALU retained `zero`, `less_signed`, and `less_unsigned`, because those outputs directly supported the comparison and branch behavior used by the processor. This was an early example of an interface being refined according to the needs of the complete system rather than keeping signals simply because they were common in textbook ALU examples.

The register file raised a more fundamental question for me:

> If the ALU can compute a result, why does the processor need another storage structure between computation and memory?

I initially used a kitchen analogy to reason about it. The ALU was the cook, main memory was a large storage room, and the register file was a small workspace immediately beside the cook. Fetching every operand from distant storage for every operation would be inefficient, while keeping operands and intermediate values close to the execution hardware makes repeated computation practical.

The analogy was incomplete, but trying to break it exposed more interesting questions. If an ALU consumes two operands, how are both supplied? What happens when existing values must be read while a result is being written back? Why does the register file have two read ports but only one write port in this processor?

Those questions made the register file stop looking like an unnecessary intermediate station and start looking like part of the processor's data-supply structure.

At one point I compared this problem to *Overcooked*. Supplying ingredients faster does not necessarily make a kitchen faster if the next station cannot consume them at the same rate. Likewise, improving one part of a computing system does not automatically improve the throughput of the entire system.

I was still mixing ideas from pipelines, caches, registers, and my single-cycle processor at the time, so many of the specific questions I asked were not yet well-formed. However, the broader question remained important:

> How should computation and data movement be organized so that the complete system works efficiently?

This was one of the points where my interest shifted from simply learning digital logic toward wanting to understand computer architecture. It also introduced an idea that continued throughout the project: optimizing an individual component is not sufficient if the surrounding system cannot use that improvement, and architectural design often involves balancing responsibilities and trade-offs across components.

### 1.3 From a Task List to a Controlled Datapath

The program counter and instruction memory changed my understanding again.

My first mental model of the PC came from the task list in *Overcooked*: after one task is completed, the system moves to the next one. Learning about `PC + 4` made sequential instruction execution intuitive, but it immediately raised another question:

> If the processor normally moves to the next instruction, how does it decide not to?

That question eventually led me to branches and jumps.

Before I understood instruction formats or even the term *single-cycle datapath*, I drew my first processor architecture from this task-oriented mental model. I imagined software producing a list of operations, instruction memory holding that list, and the processor moving through it while the decoder directed the required hardware.

![Initial processor concept](/images/datapath_initial.png)

The drawing was incomplete and contained assumptions that were later revised, but it was useful because it exposed what I still could not explain. I could draw blocks and arrows, but I did not yet understand how the processor decided which paths should actually carry meaningful data for each instruction.

Multiplexers and control signals provided the missing idea.

I began thinking of the datapath as a road network. The physical paths may all exist at the same time, but control signals act like traffic lights or valves that determine which values are allowed to affect the current operation.

Signals such as `RegWrite`, `ALUSrc`, `MemRead`, `MemWrite`, `MemtoReg`, and eventually `PCSrc` therefore stopped looking like unrelated Boolean values. Together, they determine how the same hardware is reused by different instructions.

This also corrected an earlier software-like assumption I had been making. Hardware does not inspect a situation and "decide" what to do in the human sense. Combinational logic continuously produces results from its current inputs; control logic determines which results are selected and which state elements are allowed to update.

My second architecture sketch began to reflect this change. Instead of only showing major functional blocks, it increasingly included the control paths and multiplexers required to coordinate them.

![Developing processor datapath](/images/datapath_v2.png)

### 1.4 Growing into an RV32I Datapath

Understanding the 32-bit RV32I instruction formats caused the architecture to grow rapidly.

R-type instructions introduced me to the actual roles of `opcode`, `rd`, `rs1`, `rs2`, `funct3`, and `funct7`. This replaced my earlier idea of an instruction as a generic "task code" with a much more concrete understanding: different instruction fields simultaneously identify operands, destinations, sub-operations, and instruction classes.

This also explained why the decoder alone was not enough to determine every ALU operation. As the supported instruction set expanded, I introduced an ALU Controller and expanded the ALU itself to support operations including `SLL`, `SLT`, `SLTU`, `SRL`, and `SRA`.

The processor was beginning to develop clearer responsibility boundaries:

```text
Decoder
    → identifies the instruction class and generates major datapath controls

ALU Controller
    → translates ALUOp + funct3 + funct7 into a specific ALU operation

ALU
    → performs arithmetic, logic, shifts, and comparisons

Branch/Jump Unit
    → combines branch/jump controls with ALU comparison results to select the next-PC path
```

Branches made these relationships especially clear. Supporting `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU` required more than adding new instructions to a table. The ALU had to provide the appropriate equality, signed-comparison, and unsigned-comparison information; the Branch/Jump Unit had to interpret those results; and the PC path needed a multiplexer capable of selecting a PC-relative target.

My next architecture revision reflected these additional control relationships.

![Processor datapath with branch control](/images/datapath_v3.png)

The Immediate Generator completed another major part of the architecture. Implementing I-, S-, B-, U-, and J-type immediates forced me to understand how instruction bits are reconstructed, sign-extended, and used by different datapath paths.

Adding `JAL`, `JALR`, `LUI`, and `AUIPC` then expanded both next-PC selection and register write-back. The write-back multiplexer eventually grew to support five sources, while the PC Source MUX selected among sequential execution, PC-relative targets, and the JALR target.

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

![Final conceptual datapath](/images/datapath_final.png)

Looking back at the four architecture sketches, the most important change is not simply that the final drawing contains more blocks and wires. The early diagrams represented the processor as a sequence of tasks moving between components. The later diagrams represent it as a controlled datapath in which instruction encoding, combinational computation, state, and control signals work together to determine the architectural state transition of each instruction.

That change in mental model—from asking what each individual module does to asking how responsibilities and data movement should be organized across the complete processor—was one of the most important outcomes of the project.
