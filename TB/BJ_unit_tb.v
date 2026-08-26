`timescale 1ns/1ps

module bj_unit_tb;
    reg          Branch;
    reg            Jump;
    reg            Jalr; 
    reg    [2:0] funct3;

    reg            zero;
    reg     less_signed;
    reg   less_unsigned;

    wire    [1:0]  PCSrc;
    wire     illegal_ins;

    bj_unit dut(
        .Branch(Branch),
        .Jump(Jump),
        .Jalr(Jalr),
        .funct3(funct3),
        .zero(zero),
        .less_signed(less_signed),
        .less_unsigned(less_unsigned),
        .PCSrc(PCSrc),
        .illegal_ins(illegal_ins)
    );

    initial begin
        $dumpfile("bj_unit_wave.vcd");
        $dumpvars(0, bj_unit_tb);


        // ==========================================
        // Test 1: Normal sequential execution
        // PCSrc = PC + 4
        // ==========================================
        Branch        = 1'b0;
        Jump          = 1'b0;
        Jalr          = 1'b0;
        funct3        = 3'b000;
        zero          = 1'b0;
        less_signed   = 1'b0;
        less_unsigned = 1'b0;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("Normal PC+4:                   PASS");
        else
            $display("Normal PC+4:                   FAIL");


        // ==========================================
        // Test 2: JAL
        // PCSrc = PC + imm
        // ==========================================
        Jump = 1'b1;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("JAL:                           PASS");
        else
            $display("JAL:                           FAIL");


        // ==========================================
        // Test 3: JALR
        // PCSrc = ALU Result = rs1 + imm
        // ==========================================
        Jump = 1'b0;
        Jalr = 1'b1;

        #1;

        if (PCSrc === 2'b10 && illegal_ins === 1'b0)
            $display("JALR:                          PASS");
        else
            $display("JALR:                          FAIL");


        // ==========================================
        // Test 4: BEQ taken
        // zero = 1
        // ==========================================
        Jalr   = 1'b0;
        Branch = 1'b1;
        funct3 = 3'b000;
        zero   = 1'b1;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BEQ taken:                     PASS");
        else
            $display("BEQ taken:                     FAIL");


        // ==========================================
        // Test 5: BEQ not taken
        // zero = 0
        // ==========================================
        zero = 1'b0;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BEQ not taken:                 PASS");
        else
            $display("BEQ not taken:                 FAIL");


        // ==========================================
        // Test 6: BNE taken
        // zero = 0
        // ==========================================
        funct3 = 3'b001;
        zero   = 1'b0;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BNE taken:                     PASS");
        else
            $display("BNE taken:                     FAIL");


        // ==========================================
        // Test 7: BNE not taken
        // zero = 1
        // ==========================================
        zero = 1'b1;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BNE not taken:                 PASS");
        else
            $display("BNE not taken:                 FAIL");


        // ==========================================
        // Test 8: BLT taken
        // less_signed = 1
        // ==========================================
        funct3      = 3'b100;
        less_signed = 1'b1;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BLT taken:                     PASS");
        else
            $display("BLT taken:                     FAIL");


        // ==========================================
        // Test 9: BLT not taken
        // ==========================================
        less_signed = 1'b0;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BLT not taken:                 PASS");
        else
            $display("BLT not taken:                 FAIL");


        // ==========================================
        // Test 10: BGE taken
        // less_signed = 0
        // ==========================================
        funct3      = 3'b101;
        less_signed = 1'b0;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BGE taken:                     PASS");
        else
            $display("BGE taken:                     FAIL");


        // ==========================================
        // Test 11: BGE not taken
        // ==========================================
        less_signed = 1'b1;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BGE not taken:                 PASS");
        else
            $display("BGE not taken:                 FAIL");


        // ==========================================
        // Test 12: BLTU taken
        // less_unsigned = 1
        // ==========================================
        funct3        = 3'b110;
        less_unsigned = 1'b1;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BLTU taken:                    PASS");
        else
            $display("BLTU taken:                    FAIL");


        // ==========================================
        // Test 13: BLTU not taken
        // ==========================================
        less_unsigned = 1'b0;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BLTU not taken:                PASS");
        else
            $display("BLTU not taken:                FAIL");


        // ==========================================
        // Test 14: BGEU taken
        // less_unsigned = 0
        // ==========================================
        funct3        = 3'b111;
        less_unsigned = 1'b0;

        #1;

        if (PCSrc === 2'b01 && illegal_ins === 1'b0)
            $display("BGEU taken:                    PASS");
        else
            $display("BGEU taken:                    FAIL");


        // ==========================================
        // Test 15: BGEU not taken
        // ==========================================
        less_unsigned = 1'b1;

        #1;

        if (PCSrc === 2'b00 && illegal_ins === 1'b0)
            $display("BGEU not taken:                PASS");
        else
            $display("BGEU not taken:                FAIL");


        // ==========================================
        // Test 16: Illegal Branch funct3 = 010
        // ==========================================
        funct3 = 3'b010;

        #1;

        if (illegal_ins === 1'b1)
            $display("Illegal Branch funct3:         PASS");
        else
            $display("Illegal Branch funct3:         FAIL");


        // ==========================================
        // Test 17: Illegal control combination
        // Branch and Jump cannot both be 1
        // ==========================================
        Branch = 1'b1;
        Jump   = 1'b1;
        Jalr   = 1'b0;

        #1;

        if (illegal_ins === 1'b1)
            $display("Illegal control combination:   PASS");
        else
            $display("Illegal control combination:   FAIL");


        // ==========================================
        // Test 18: Another illegal combination
        // Jump and Jalr both active
        // ==========================================
        Branch = 1'b0;
        Jump   = 1'b1;
        Jalr   = 1'b1;

        #1;

        if (illegal_ins === 1'b1)
            $display("Illegal Jump/Jalr combination: PASS");
        else
            $display("Illegal Jump/Jalr combination: FAIL");


        $finish;
    end
endmodule