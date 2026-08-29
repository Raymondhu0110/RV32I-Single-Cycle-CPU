`timescale 1ns/1ps

module mux_memtoreg_tb;
    reg [31:0] alu_result;
    reg [31:0]   mem_data;
    reg [31:0]       pc_4;
    reg [31:0]        imm;
    reg [31:0]     pc_imm;

    reg [2:0]    MemtoReg;

    wire [31:0]     wdata;
    wire  illegal_control;

    mux_memtoreg dut(
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_4(pc_4),
        .imm(imm),
        .pc_imm(pc_imm),
        .MemtoReg(MemtoReg),
        .wdata(wdata),
        .illegal_control(illegal_control)
    );

    initial begin
        $dumpfile("mux_memtoreg_wave.vcd");
        $dumpvars(0, mux_memtoreg_tb);

        
        alu_result = 32'hAAAA_AAAA;
        mem_data   = 32'hBBBB_BBBB;
        pc_4       = 32'hCCCC_CCCC;
        imm        = 32'hDDDD_DDDD;
        pc_imm     = 32'hEEEE_EEEE;


        // ==========================================
        // Test 1: ALU Result
        // MemtoReg = 000
        // ==========================================
        MemtoReg = 3'b000;
        #1;

        if (
            wdata === 32'hAAAA_AAAA &&
            illegal_control === 1'b0
        )
            $display("ALU Result:       PASS");
        else
            $display("ALU Result:       FAIL");


        // ==========================================
        // Test 2: Memory Data
        // MemtoReg = 001
        // ==========================================
        MemtoReg = 3'b001;
        #1;

        if (
            wdata === 32'hBBBB_BBBB &&
            illegal_control === 1'b0
        )
            $display("Memory Data:      PASS");
        else
            $display("Memory Data:      FAIL");


        // ==========================================
        // Test 3: PC + 4
        // MemtoReg = 010
        // ==========================================
        MemtoReg = 3'b010;
        #1;

        if (
            wdata === 32'hCCCC_CCCC &&
            illegal_control === 1'b0
        )
            $display("PC + 4:           PASS");
        else
            $display("PC + 4:           FAIL");


        // ==========================================
        // Test 4: Immediate
        // MemtoReg = 011
        // ==========================================
        MemtoReg = 3'b011;
        #1;

        if (
            wdata === 32'hDDDD_DDDD &&
            illegal_control === 1'b0
        )
            $display("Immediate:        PASS");
        else
            $display("Immediate:        FAIL");


        // ==========================================
        // Test 5: PC + immediate
        // MemtoReg = 100
        // ==========================================
        MemtoReg = 3'b100;
        #1;

        if (
            wdata === 32'hEEEE_EEEE &&
            illegal_control === 1'b0
        )
            $display("PC + imm:         PASS");
        else
            $display("PC + imm:         FAIL");


        // ==========================================
        // Test 6: Illegal MemtoReg = 101
        // ==========================================
        MemtoReg = 3'b101;
        #1;

        if (
            wdata === 32'b0 &&
            illegal_control === 1'b1
        )
            $display("Illegal 101:      PASS");
        else
            $display("Illegal 101:      FAIL");


        // ==========================================
        // Test 7: Illegal MemtoReg = 110
        // ==========================================
        MemtoReg = 3'b110;
        #1;

        if (
            wdata === 32'b0 &&
            illegal_control === 1'b1
        )
            $display("Illegal 110:      PASS");
        else
            $display("Illegal 110:      FAIL");


        // ==========================================
        // Test 8: Illegal MemtoReg = 111
        // ==========================================
        MemtoReg = 3'b111;
        #1;

        if (
            wdata === 32'b0 &&
            illegal_control === 1'b1
        )
            $display("Illegal 111:      PASS");
        else
            $display("Illegal 111:      FAIL");


        // ==========================================
        // Test 9:
        // 從 illegal control 回到合法控制
        //
        // 確認 illegal_control 不會卡在 1
        // ==========================================
        MemtoReg = 3'b000;
        #1;

        if (
            wdata === 32'hAAAA_AAAA &&
            illegal_control === 1'b0
        )
            $display("Illegal recovery: PASS");
        else
            $display("Illegal recovery: FAIL");


        $finish;
    end
endmodule
