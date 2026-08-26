`timescale 1ns/1ps

module mux_alusrc_tb;
    reg [31:0]    imm;
    reg [31:0] rdata2;

    reg        ALUSrc;

    wire [31:0]     b;

    mux_alusrc dut(
        .imm(imm),
        .rdata2(rdata2),
        .ALUSrc(ALUSrc),
        .b(b)
    );

    initial begin
        $dumpfile("mux_alusrc_wave.vcd");
        $dumpvars(0, mux_alusrc_tb);

        imm    = 32'hAAAA_AAAA;
        rdata2 = 32'hBBBB_BBBB;

        // ==========================================
        // Test 1: rdata2
        // ALUSrc = 0
        // ==========================================

        ALUSrc = 1'b0;
        #1;

        if (b === 32'hBBBB_BBBB)
            $display("ALUSrc=0 rdata2 Result: PASS");
        else
            $display("ALUSrc=0 rdata2 Result: FAIL");
        
        // ==========================================
        // Test 2: imm
        // ALUSrc = 1
        // ==========================================

        ALUSrc = 1'b1;
        #1;

        if (b === 32'hAAAA_AAAA)
            $display("ALUSrc=1 imm Result:    PASS");
        else
            $display("ALUSrc=1 imm Result:    FAIL");

        $finish;
    end
endmodule