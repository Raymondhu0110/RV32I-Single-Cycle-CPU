`timescale 1ns/1ps

module imm_gen_tb;
    reg  [31:0] instruction;
    wire [31:0]         imm;
    wire        illegal_ins;

    imm_gen dut(
        .instruction(instruction),
        .imm(imm),
        .illegal_ins(illegal_ins)
    );
    
    initial begin
        $dumpfile("imm_gen_wave.vcd");
        $dumpvars(0, imm_gen_tb);

        // ==========================================
        // Test 1: I-type positive immediate
        // ADDI x?, x?, +5
        // imm = 5
        // ==========================================
        instruction = 32'b000000000101_00001_000_00010_0010011;
        #1;

        if (imm === 32'd5 && illegal_ins === 1'b0)
            $display("I-type +5:       PASS");
        else
            $display("I-type +5:       FAIL");


        // ==========================================
        // Test 2: I-type negative immediate
        // immediate = -4
        // 12-bit two's complement = 111111111100
        // ==========================================
        instruction = 32'b111111111100_00001_000_00010_0010011;
        #1;

        if (imm === 32'hFFFF_FFFC && illegal_ins === 1'b0)
            $display("I-type -4:       PASS");
        else
            $display("I-type -4:       FAIL");


        // ==========================================
        // Test 3: Load also uses I-type immediate
        // immediate = +12
        // ==========================================
        instruction = 32'b000000001100_00001_010_00010_0000011;
        #1;

        if (imm === 32'd12 && illegal_ins === 1'b0)
            $display("Load I-type +12: PASS");
        else
            $display("Load I-type +12: FAIL");


        // ==========================================
        // Test 4: S-type positive immediate
        //
        // imm = 12 = 000000001100
        //
        // imm[11:5] = 0000000
        // imm[4:0]  = 01100
        // ==========================================
        instruction = 32'b0000000_00010_00001_010_01100_0100011;
        #1;

        if (imm === 32'd12 && illegal_ins === 1'b0)
            $display("S-type +12:      PASS");
        else
            $display("S-type +12:      FAIL");


        // ==========================================
        // Test 5: S-type negative immediate
        //
        // imm = -8
        // 12-bit = 111111111000
        //
        // imm[11:5] = 1111111
        // imm[4:0]  = 11000
        // ==========================================
        instruction = 32'b1111111_00010_00001_010_11000_0100011;
        #1;

        if (imm === 32'hFFFF_FFF8 && illegal_ins === 1'b0)
            $display("S-type -8:       PASS");
        else
            $display("S-type -8:       FAIL");


        // ==========================================
        // Test 6: B-type positive immediate
        //
        // branch offset = +8
        //
        // imm[12]   = 0
        // imm[11]   = 0
        // imm[10:5] = 000000
        // imm[4:1]  = 0100
        // imm[0]    = 0
        // ==========================================
        instruction = 32'b0_000000_00010_00001_000_0100_0_1100011;
        #1;

        if (imm === 32'd8 && illegal_ins === 1'b0)
            $display("B-type +8:       PASS");
        else
            $display("B-type +8:       FAIL");


        // ==========================================
        // Test 7: B-type negative immediate
        //
        // branch offset = -4
        // 13-bit representation = 1_11111111110_0
        // ==========================================
        instruction = 32'b1_111111_00010_00001_000_1110_1_1100011;
        #1;

        if (imm === 32'hFFFF_FFFC && illegal_ins === 1'b0)
            $display("B-type -4:       PASS");
        else
            $display("B-type -4:       FAIL");


        // ==========================================
        // Test 8: U-type
        //
        // imm[31:12] = 0x12345
        // expected = 0x12345000
        // ==========================================
        instruction = 32'b00010010001101000101_00010_0110111;
        #1;

        if (imm === 32'h1234_5000 && illegal_ins === 1'b0)
            $display("U-type LUI:      PASS");
        else
            $display("U-type LUI:      FAIL");


        // ==========================================
        // Test 9: AUIPC also uses U-type
        // ==========================================
        instruction = 32'b10101011110011011110_00010_0010111;
        #1;

        if (imm === 32'hABCDE000 && illegal_ins === 1'b0)
            $display("U-type AUIPC:    PASS");
        else
            $display("U-type AUIPC:    FAIL");


        // ==========================================
        // Test 10: J-type positive immediate
        //
        // offset = +8
        //
        // imm[20]    = 0
        // imm[19:12] = 00000000
        // imm[11]    = 0
        // imm[10:1]  = 0000000100
        // imm[0]     = 0
        // ==========================================
        instruction = 32'b0_0000000100_0_00000000_00001_1101111;
        #1;

        if (imm === 32'd8 && illegal_ins === 1'b0)
            $display("J-type +8:       PASS");
        else
            $display("J-type +8:       FAIL");


        // ==========================================
        // Test 11: JALR uses I-type immediate
        // immediate = +16
        // ==========================================
        instruction = 32'b000000010000_00001_000_00010_1100111;
        #1;

        if (imm === 32'd16 && illegal_ins === 1'b0)
            $display("JALR I-type +16: PASS");
        else
            $display("JALR I-type +16: FAIL");


        // ==========================================
        // Test 12: Illegal opcode
        // ==========================================
        instruction = 32'b0000000_00000_00000_000_00000_1111111;
        #1;

        if (illegal_ins === 1'b1)
            $display("Illegal opcode:  PASS");
        else
            $display("Illegal opcode:  FAIL");


        $finish;
    end

endmodule