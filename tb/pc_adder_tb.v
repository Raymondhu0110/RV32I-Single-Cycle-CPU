`timescale 1ns/1ps

module pc_adder_tb;
    reg [31:0]     PC;
    reg [31:0]    imm;

    wire [31:0] pc_imm;
    wire [31:0]   pc_4;

    pc_adder dut(
        .PC(PC),
        .imm(imm),
        .pc_imm(pc_imm),
        .pc_4(pc_4)
    );

    initial begin
        $dumpfile("pc_adder_wave.vcd");
        $dumpvars(0, pc_adder_tb);


        // ==========================================
        // Test 1: Normal PC + 4
        //
        // PC = 0x1000
        // pc_4 = 0x1004
        // ==========================================

        PC  = 32'h0000_1000;
        imm = 32'd0;

        #1;

        if (
            pc_4   === 32'h0000_1004 &&
            pc_imm === 32'h0000_1000
        )
            $display("PC+4 normal:       PASS");
        else
            $display("PC+4 normal:       FAIL");


        // ==========================================
        // Test 2: Positive immediate
        //
        // PC  = 0x1000
        // imm = +16
        //
        // pc_imm = 0x1010
        // ==========================================

        PC  = 32'h0000_1000;
        imm = 32'd16;

        #1;

        if (
            pc_4   === 32'h0000_1004 &&
            pc_imm === 32'h0000_1010
        )
            $display("PC+imm positive:   PASS");
        else
            $display("PC+imm positive:   FAIL");


        // ==========================================
        // Test 3: Negative immediate
        //
        // PC  = 0x1000
        // imm = -16
        //
        // -16 in 32-bit two's complement:
        // 0xFFFF_FFF0
        //
        // pc_imm = 0x0FF0
        // ==========================================

        PC  = 32'h0000_1000;
        imm = 32'hFFFF_FFF0;

        #1;

        if (
            pc_4   === 32'h0000_1004 &&
            pc_imm === 32'h0000_0FF0
        )
            $display("PC+imm negative:   PASS");
        else
            $display("PC+imm negative:   FAIL");


        // ==========================================
        // Test 4: 32-bit wrap-around
        //
        // PC = 0xFFFF_FFFC
        //
        // PC + 4 = 0x0000_0000
        // ==========================================

        PC  = 32'hFFFF_FFFC;
        imm = 32'd8;

        #1;

        if (
            pc_4   === 32'h0000_0000 &&
            pc_imm === 32'h0000_0004
        )
            $display("32-bit wraparound: PASS");
        else
            $display("32-bit wraparound: FAIL");


        $finish;
    end
endmodule