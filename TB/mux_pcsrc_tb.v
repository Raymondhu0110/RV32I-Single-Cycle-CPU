`timescale 1ns/1ps

module mux_pcsrc_tb;
    reg [31:0] alu_result;
    reg [31:0]       pc_4;
    reg [31:0]     pc_imm;

    reg [1:0]       PCSrc;

    wire [31:0]   next_pc;
    wire  illegal_control;

    mux_pcsrc dut(
        .alu_result(alu_result),
        .pc_4(pc_4),
        .pc_imm(pc_imm),

        .PCSrc(PCSrc),

        .next_pc(next_pc),
        .illegal_control(illegal_control)
    );

    initial begin
        $dumpfile("mux_pcsrc_wave.vcd");
        $dumpvars(0, mux_pcsrc_tb);


        // ==========================================
        // Test 1: Normal PC + 4
        // PCSrc = 00
        // ==========================================

        pc_4       = 32'h0000_1004;
        pc_imm     = 32'h0000_2000;
        alu_result = 32'h0000_3000;

        PCSrc = 2'b00;
        #1;

        if (
            next_pc === 32'h0000_1004 &&
            illegal_control === 1'b0
        )
            $display("PCSrc=00 PC+4:          PASS");
        else
            $display("PCSrc=00 PC+4:          FAIL");


        // ==========================================
        // Test 2: PC + imm
        // Branch taken / JAL
        // PCSrc = 01
        // ==========================================

        PCSrc = 2'b01;
        #1;

        if (
            next_pc === 32'h0000_2000 &&
            illegal_control === 1'b0
        )
            $display("PCSrc=01 PC+imm:        PASS");
        else
            $display("PCSrc=01 PC+imm:        FAIL");


        // ==========================================
        // Test 3: JALR
        // ALU result bit[0] already = 0
        // ==========================================

        alu_result = 32'h0000_3004;

        PCSrc = 2'b10;
        #1;

        if (
            next_pc === 32'h0000_3004 &&
            illegal_control === 1'b0
        )
            $display("JALR even target:        PASS");
        else
            $display("JALR even target:        FAIL");


        // ==========================================
        // Test 4: JALR
        // ALU result bit[0] = 1
        //
        // 0x3005 → clear bit[0] → 0x3004
        // ==========================================

        alu_result = 32'h0000_3005;

        PCSrc = 2'b10;
        #1;

        if (
            next_pc === 32'h0000_3004 &&
            illegal_control === 1'b0
        )
            $display("JALR bit0 clear:         PASS");
        else
            $display("JALR bit0 clear:         FAIL");


        // ==========================================
        // Test 5: Illegal PCSrc
        // PCSrc = 11
        // ==========================================

        PCSrc = 2'b11;
        #1;

        if (
            next_pc === 32'b0 &&
            illegal_control === 1'b1
        )
            $display("Illegal PCSrc=11:        PASS");
        else
            $display("Illegal PCSrc=11:        FAIL");


        // ==========================================
        // Test 6: Illegal recovery
        //
        // 確認從 illegal 回到合法控制後
        // illegal_control 可以回到 0
        // ==========================================

        PCSrc = 2'b00;
        #1;

        if (
            next_pc === 32'h0000_1004 &&
            illegal_control === 1'b0
        )
            $display("Illegal recovery:        PASS");
        else
            $display("Illegal recovery:        FAIL");


        $finish;
    end
endmodule