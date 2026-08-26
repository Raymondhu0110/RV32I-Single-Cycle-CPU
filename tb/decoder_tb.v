`timescale 1ns/1ps

module decoder_tb;
    reg [31:0] instruction;

    wire [4:0]     rd;
    wire [2:0] funct3;
    wire [4:0]    rs1;
    wire [4:0]    rs2;
    wire [6:0] funct7;

    wire          ALUSrc;
    wire  [1:0]    ALUop;
    wire  [2:0] MemtoReg;
    wire        RegWrite;
    wire        MemWrite;
    wire         MemRead;
    wire          Branch;
    wire            Jump;
    wire            Jalr;
    wire     illegal_ins;

    decoder dut(
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
        .illegal_ins(illegal_ins)
    );

    initial begin
        $dumpfile("decoder_wave.vcd");
        $dumpvars(0, decoder_tb);

        // ==========================================
        // Test 1: R-type ALU
        // ==========================================
        instruction = 32'b0000000_00010_00001_000_00011_0110011;
        #1;

        if (
            ALUSrc      === 1'b0 &&
            ALUop       === 2'b11 &&
            MemtoReg    === 3'b000 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0 &&

            rd           === 5'b00011 &&
            funct3       === 3'b000 &&
            rs1          === 5'b00001 &&
            rs2          === 5'b00010 &&
            funct7       === 7'b0000000
        )
            $display("R-type:              PASS");
        else
            $display("R-type:              FAIL");


        // ==========================================
        // Test 2: I-type ALU
        // ==========================================
        instruction = 32'b000000000101_00001_000_00010_0010011;
        #1;

        if (
            ALUSrc      === 1'b1 &&
            ALUop       === 2'b10 &&
            MemtoReg    === 3'b000 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0
        )
            $display("I-type ALU:          PASS");
        else
            $display("I-type ALU:          FAIL");


        // ==========================================
        // Test 3: Load
        // ==========================================
        instruction = 32'b000000000100_00001_010_00010_0000011;
        #1;

        if (
            ALUSrc      === 1'b1 &&
            ALUop       === 2'b00 &&
            MemtoReg    === 3'b001 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b1 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0
        )
            $display("Load:                PASS");
        else
            $display("Load:                FAIL");


        // ==========================================
        // Test 4: Store
        // ==========================================
        instruction = 32'b0000000_00010_00001_010_00100_0100011;
        #1;

        if (
            ALUSrc      === 1'b1 &&
            ALUop       === 2'b00 &&
            RegWrite    === 1'b0 &&
            MemWrite    === 1'b1 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0
        )
            $display("Store:               PASS");
        else
            $display("Store:               FAIL");


        // ==========================================
        // Test 5: Branch
        // ==========================================
        instruction = 32'b0000000_00010_00001_000_00000_1100011;
        #1;

        if (
            ALUSrc      === 1'b0 &&
            ALUop       === 2'b01 &&
            RegWrite    === 1'b0 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b1 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0
        )
            $display("Branch:              PASS");
        else
            $display("Branch:              FAIL");


        // ==========================================
        // Test 6: LUI
        //
        // rd <- immediate
        // MemtoReg = 011
        // ==========================================
        instruction = 32'b00010010001101000101_00010_0110111;
        #1;

        if (
            MemtoReg    === 3'b011 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0 &&
            rd           === 5'b00010
        )
            $display("LUI:                 PASS");
        else
            $display("LUI:                 FAIL");


        // ==========================================
        // Test 7: AUIPC
        //
        // rd <- PC + imm
        // MemtoReg = 100
        // ==========================================
        instruction = 32'b00010010001101000101_00010_0010111;
        #1;

        if (
            MemtoReg    === 3'b100 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0 &&
            rd           === 5'b00010
        )
            $display("AUIPC:               PASS");
        else
            $display("AUIPC:               FAIL");


        // ==========================================
        // Test 8: JAL
        //
        // rd <- PC + 4
        // PC <- PC + imm
        // ==========================================
        instruction = 32'b0_0000000100_0_00000000_00001_1101111;
        #1;

        if (
            MemtoReg    === 3'b010 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b1 &&
            Jalr        === 1'b0 &&
            illegal_ins === 1'b0 &&
            rd           === 5'b00001
        )
            $display("JAL:                 PASS");
        else
            $display("JAL:                 FAIL");


        // ==========================================
        // Test 9: JALR
        //
        // ALU computes rs1 + imm
        // rd <- PC + 4
        // ==========================================
        instruction = 32'b000000010000_00001_000_00010_1100111;
        #1;

        if (
            ALUSrc      === 1'b1 &&
            ALUop       === 2'b00 &&
            MemtoReg    === 3'b010 &&
            RegWrite    === 1'b1 &&
            MemWrite    === 1'b0 &&
            MemRead     === 1'b0 &&
            Branch      === 1'b0 &&
            Jump        === 1'b0 &&
            Jalr        === 1'b1 &&
            illegal_ins === 1'b0 &&

            rd           === 5'b00010 &&
            rs1          === 5'b00001 &&
            funct3       === 3'b000
        )
            $display("JALR:                PASS");
        else
            $display("JALR:                FAIL");


        // ==========================================
        // Test 10: Illegal opcode
        // ==========================================
        instruction = 32'b0000000_00000_00000_000_00000_1111111;
        #1;

        if (illegal_ins === 1'b1)
            $display("Illegal instruction: PASS");
        else
            $display("Illegal instruction: FAIL");


        $finish;
    end
endmodule