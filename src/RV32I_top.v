module RV32I_top #(
    parameter DEPTH = 16384
) (
    input wire clk,
    input wire rst_n,
    input wire enable,

    output wire         decoder_illegal_ins,
    output wire              BJ_illegal_ins,
    output wire         imm_gen_illegal_ins,
    output wire  alu_controller_illegal_alu,
    output wire        dmem_illegal_control,
    output wire memtoregMUX_illegal_control,
    output wire    pcsrcMUX_illegal_control
);
    //PC
    wire [31:0]      next_pc;
    wire [31:0]           pc;

    //Instruction Memory
    wire [31:0]  instruction;
    
    //Decoder
    wire  [4:0]     rd;
    wire  [2:0] funct3;
    wire  [4:0]    rs1;
    wire  [4:0]    rs2;
    wire  [6:0] funct7;
    wire          ALUSrc;
    wire  [1:0]    ALUop;
    wire  [2:0] MemtoReg;
    wire        RegWrite;
    wire        MemWrite;
    wire         MemRead;
    wire          Branch;
    wire            Jump;
    wire            Jalr;

    //Branch/Jump Decision Unit
    wire [1:0]   PCSrc;

    //Immediate Generator
    wire [31:0]      imm;

    //PC Adder
    wire [31:0] pc_imm;
    wire [31:0]   pc_4;

    //ALU Controller
    wire [3:0] op;

    //ALU
    wire [31:0] alusrcMUX_b_alu;

    wire [31:0]    alu_result;
    wire                 zero;
    wire          less_signed;
    wire        less_unsigned;

    //Data Memory
    wire [31:0]   mem_data;

    //Regfile
    wire [31:0] memtoregMUX_wdata_reg;
    wire [31:0] rdata1;
    wire [31:0] rdata2;

    pc pc_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),

        .next_pc(next_pc),
        .pc(pc)
    );
    
    imem #(
        .DEPTH(DEPTH)
    )imem_unit(
        .raddr(pc),
        .instruction(instruction)
    );

    decoder decoder_unit(
        .instruction(instruction),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),

        .ALUSrc(ALUSrc),
        .ALUop(ALUop),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Branch(Branch),
        .Jump(Jump),
        .Jalr(Jalr),
        .illegal_ins(decoder_illegal_ins)
    );

    bj_unit bj_unit_unit(
        .Branch(Branch),
        .Jump(Jump),
        .Jalr(Jalr),
        .funct3(funct3),
        .zero(zero),
        .less_signed(less_signed),
        .less_unsigned(less_unsigned),
        .PCSrc(PCSrc),
        .illegal_ins(BJ_illegal_ins)
    );

    imm_gen imm_gen_unit(
        .instruction(instruction),
        .imm(imm),
        .illegal_ins(imm_gen_illegal_ins) 
    );

    pc_adder pc_adder_unit(
        .PC(pc),
        .imm(imm),
        .pc_imm(pc_imm),
        .pc_4(pc_4)
    );

    mux_pcsrc mux_pcsrc_unit(
        .alu_result(alu_result),
        .pc_4(pc_4),
        .pc_imm(pc_imm),

        .PCSrc(PCSrc),

        .next_pc(next_pc),
        .illegal_control(pcsrcMUX_illegal_control)
    );

    mux_alusrc mux_alusrc_unit(
        .imm(imm),
        .rdata2(rdata2),
        .ALUSrc(ALUSrc),
        .b(alusrcMUX_b_alu)
    );

    alu_controller alu_controller_unit(
        .ALUop(ALUop),
        .funct3(funct3),
        .funct7(funct7),

        .op(op),
        .illegal_alu(alu_controller_illegal_alu)
    );

    alu alu_unit (
        .a(rdata1),
        .b(alusrcMUX_b_alu),
        .op(op),
        .result(alu_result),
        .zero(zero),
        .less_signed(less_signed),
        .less_unsigned(less_unsigned)
    );

    dmem #(
        .DEPTH(DEPTH)
    ) dmem_unit (
        .clk(clk),

        .alu_result(alu_result),
        .wdata(rdata2),

        .funct3(funct3),
        .MemWrite(MemWrite),
        .MemRead(MemRead),

        .mem_data(mem_data),
        .illegal_control(dmem_illegal_control)
    );

    mux_memtoreg mux_memtoreg_unit(
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_4(pc_4),
        .imm(imm),
        .pc_imm(pc_imm),
        .MemtoReg(MemtoReg),
        .wdata(memtoregMUX_wdata_reg),
        .illegal_control(memtoregMUX_illegal_control)
    );

    regfile regfile_unit (
        .clk(clk),
        .rst_n(rst_n),

        .raddr1(rs1),
        .rdata1(rdata1),

        .raddr2(rs2),
        .rdata2(rdata2),

        .we(RegWrite),
        .waddr(rd),
        .wdata(memtoregMUX_wdata_reg)
    );
endmodule