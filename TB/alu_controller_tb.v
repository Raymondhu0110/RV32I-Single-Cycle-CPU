`timescale 1ns/1ps

module alu_controller_tb;
    reg [1:0]  ALUop;
    reg [2:0] funct3;
    reg [6:0] funct7;

    wire [3:0]    op;
    wire illegal_alu;

    alu_controller dut(
        .ALUop(ALUop),
        .funct3(funct3),
        .funct7(funct7),

        .op(op),
        .illegal_alu(illegal_alu)
    );

    initial begin
        $dumpfile("alu_controller_wave.vcd");
        $dumpvars(0, alu_controller_tb);


        // ==========================================
        // Test 1: ALUOp = 00
        // Load / Store -> ADD
        // ==========================================
        ALUop  = 2'b00;
        funct3 = 3'bxxx;
        funct7 = 7'bxxxxxxx;
        #1;

        if (op === 4'b0000 && illegal_alu === 1'b0)
            $display("Direct ADD:     PASS");
        else
            $display("Direct ADD:     FAIL");


        // ==========================================
        // Test 2: BEQ -> SUB
        // ==========================================
        ALUop  = 2'b01;
        funct3 = 3'b000;
        funct7 = 7'bxxxxxxx;
        #1;

        if (op === 4'b1000 && illegal_alu === 1'b0)
            $display("BEQ:            PASS");
        else
            $display("BEQ:            FAIL");


        // ==========================================
        // Test 3: BNE -> SUB
        // ==========================================
        funct3 = 3'b001;
        #1;

        if (op === 4'b1000 && illegal_alu === 1'b0)
            $display("BNE:            PASS");
        else
            $display("BNE:            FAIL");


        // ==========================================
        // Test 4: BLT -> SLT
        // ==========================================
        funct3 = 3'b100;
        #1;

        if (op === 4'b0010 && illegal_alu === 1'b0)
            $display("BLT:            PASS");
        else
            $display("BLT:            FAIL");


        // ==========================================
        // Test 5: BGE -> SLT
        // ==========================================
        funct3 = 3'b101;
        #1;

        if (op === 4'b0010 && illegal_alu === 1'b0)
            $display("BGE:            PASS");
        else
            $display("BGE:            FAIL");


        // ==========================================
        // Test 6: BLTU -> SLTU
        // ==========================================
        funct3 = 3'b110;
        #1;

        if (op === 4'b0011 && illegal_alu === 1'b0)
            $display("BLTU:           PASS");
        else
            $display("BLTU:           FAIL");


        // ==========================================
        // Test 7: BGEU -> SLTU
        // ==========================================
        funct3 = 3'b111;
        #1;

        if (op === 4'b0011 && illegal_alu === 1'b0)
            $display("BGEU:           PASS");
        else
            $display("BGEU:           FAIL");


        // ==========================================
        // Test 8: Illegal Branch funct3
        // 010 is not a valid branch encoding
        // ==========================================
        funct3 = 3'b010;
        #1;

        if (illegal_alu === 1'b1)
            $display("Illegal Branch: PASS");
        else
            $display("Illegal Branch: FAIL");


        // ==========================================
        // Test 9: ADDI
        // ALUOp = 10, funct3 = 000
        // ==========================================
        ALUop  = 2'b10;
        funct3 = 3'b000;
        funct7 = 7'b1010101; // deliberately irrelevant
        #1;

        if (op === 4'b0000 && illegal_alu === 1'b0)
            $display("ADDI:           PASS");
        else
            $display("ADDI:           FAIL");


        // ==========================================
        // Test 10: SLLI
        // ==========================================
        funct3 = 3'b001;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0001 && illegal_alu === 1'b0)
            $display("SLLI:           PASS");
        else
            $display("SLLI:           FAIL");


        // ==========================================
        // Test 11: SLTI
        // ==========================================
        funct3 = 3'b010;
        #1;

        if (op === 4'b0010 && illegal_alu === 1'b0)
            $display("SLTI:           PASS");
        else
            $display("SLTI:           FAIL");


        // ==========================================
        // Test 12: SLTIU
        // ==========================================
        funct3 = 3'b011;
        #1;

        if (op === 4'b0011 && illegal_alu === 1'b0)
            $display("SLTIU:          PASS");
        else
            $display("SLTIU:          FAIL");


        // ==========================================
        // Test 13: XORI
        // ==========================================
        funct3 = 3'b100;
        #1;

        if (op === 4'b0100 && illegal_alu === 1'b0)
            $display("XORI:           PASS");
        else
            $display("XORI:           FAIL");


        // ==========================================
        // Test 14: SRLI
        // instruction[31:25] = 0000000
        // ==========================================
        funct3 = 3'b101;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0101 && illegal_alu === 1'b0)
            $display("SRLI:           PASS");
        else
            $display("SRLI:           FAIL");


        // ==========================================
        // Test 15: SRAI
        // instruction[31:25] = 0100000
        // ==========================================
        funct7 = 7'b0100000;
        #1;

        if (op === 4'b1101 && illegal_alu === 1'b0)
            $display("SRAI:           PASS");
        else
            $display("SRAI:           FAIL");


        // ==========================================
        // Test 16: Illegal I-type shift encoding
        // ==========================================
        funct7 = 7'b1111111;
        #1;

        if (illegal_alu === 1'b1)
            $display("Illegal I-type Shift: PASS");
        else
            $display("Illegal I-type Shift: FAIL");


        // ==========================================
        // Test 17: ORI
        // ==========================================
        funct3 = 3'b110;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0110 && illegal_alu === 1'b0)
            $display("ORI:            PASS");
        else
            $display("ORI:            FAIL");


        // ==========================================
        // Test 18: ANDI
        // ==========================================
        funct3 = 3'b111;
        #1;

        if (op === 4'b0111 && illegal_alu === 1'b0)
            $display("ANDI:           PASS");
        else
            $display("ANDI:           FAIL");


        // ==========================================
        // Test 19: R-type ADD
        // ==========================================
        ALUop  = 2'b11;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0000 && illegal_alu === 1'b0)
            $display("ADD:            PASS");
        else
            $display("ADD:            FAIL");


        // ==========================================
        // Test 20: R-type SUB
        // ==========================================
        funct7 = 7'b0100000;
        #1;

        if (op === 4'b1000 && illegal_alu === 1'b0)
            $display("SUB:            PASS");
        else
            $display("SUB:            FAIL");


        // ==========================================
        // Test 21: SLL
        // ==========================================
        funct3 = 3'b001;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0001 && illegal_alu === 1'b0)
            $display("SLL:            PASS");
        else
            $display("SLL:            FAIL");


        // ==========================================
        // Test 22: SLT
        // ==========================================
        funct3 = 3'b010;
        #1;

        if (op === 4'b0010 && illegal_alu === 1'b0)
            $display("SLT:            PASS");
        else
            $display("SLT:            FAIL");


        // ==========================================
        // Test 23: SLTU
        // ==========================================
        funct3 = 3'b011;
        #1;

        if (op === 4'b0011 && illegal_alu === 1'b0)
            $display("SLTU:           PASS");
        else
            $display("SLTU:           FAIL");


        // ==========================================
        // Test 24: XOR
        // ==========================================
        funct3 = 3'b100;
        #1;

        if (op === 4'b0100 && illegal_alu === 1'b0)
            $display("XOR:            PASS");
        else
            $display("XOR:            FAIL");


        // ==========================================
        // Test 25: SRL
        // ==========================================
        funct3 = 3'b101;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0101 && illegal_alu === 1'b0)
            $display("SRL:            PASS");
        else
            $display("SRL:            FAIL");


        // ==========================================
        // Test 26: SRA
        // ==========================================
        funct7 = 7'b0100000;
        #1;

        if (op === 4'b1101 && illegal_alu === 1'b0)
            $display("SRA:            PASS");
        else
            $display("SRA:            FAIL");


        // ==========================================
        // Test 27: OR
        // ==========================================
        funct3 = 3'b110;
        funct7 = 7'b0000000;
        #1;

        if (op === 4'b0110 && illegal_alu === 1'b0)
            $display("OR:             PASS");
        else
            $display("OR:             FAIL");


        // ==========================================
        // Test 28: AND
        // ==========================================
        funct3 = 3'b111;
        #1;

        if (op === 4'b0111 && illegal_alu === 1'b0)
            $display("AND:            PASS");
        else
            $display("AND:            FAIL");


        // ==========================================
        // Test 29: Illegal R-type funct7
        // funct3=000 but neither ADD nor SUB
        // ==========================================
        funct3 = 3'b000;
        funct7 = 7'b1111111;
        #1;

        if (illegal_alu === 1'b1)
            $display("Illegal ADD/SUB encoding: PASS");
        else
            $display("Illegal ADD/SUB encoding: FAIL");


        // ==========================================
        // Test 30: Illegal SRL/SRA funct7
        // ==========================================
        funct3 = 3'b101;
        funct7 = 7'b1111111;
        #1;

        if (illegal_alu === 1'b1)
            $display("Illegal SRL/SRA encoding: PASS");
        else
            $display("Illegal SRL/SRA encoding: FAIL");


        $finish;    
    end
endmodule