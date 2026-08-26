`timescale 1ns/1ps

module dmem_tb;

    parameter DEPTH = 16384;

    reg         clk;
    reg  [31:0] alu_result;
    reg  [31:0] wdata;
    reg  [2:0]  funct3;
    reg         MemWrite;
    reg         MemRead;

    wire [31:0] mem_data;
    wire        illegal_control;

    integer pass_count;
    integer fail_count;

    dmem #(
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .alu_result(alu_result),
        .wdata(wdata),
        .funct3(funct3),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .mem_data(mem_data),
        .illegal_control(illegal_control)
    );

    always #5 clk = ~clk;


    initial begin
        $dumpfile("dmem_wave.vcd");
        $dumpvars(0, dmem_tb);

        clk        = 1'b0;
        alu_result = 32'b0;
        wdata      = 32'b0;
        funct3     = 3'b000;
        MemWrite   = 1'b0;
        MemRead    = 1'b0;

        pass_count = 0;
        fail_count = 0;


        // ==========================================
        // Test 1: Idle
        // ==========================================
        #1;

        if (
            mem_data        === 32'b0 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 1  Idle:                       PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 1  Idle:                       FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 2: SW control legality
        // Valid SW must not be illegal
        // ==========================================
        alu_result = 32'h0000_1000;
        wdata      = 32'h1234_5678;
        funct3     = 3'b010;
        MemRead    = 1'b0;
        MemWrite   = 1'b1;

        #1;

        if (illegal_control === 1'b0) begin
            $display("Test 2  SW control:                 PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 2  SW control:                 FAIL");
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        #1;

        MemWrite = 1'b0;
        MemRead  = 1'b1;
        funct3   = 3'b010;

        #1;

        if (
            mem_data        === 32'h1234_5678 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 3  SW -> LW:                   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 3  SW -> LW: FAIL, mem_data=%h illegal=%b",
                mem_data,
                illegal_control
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 4: LB positive
        // ==========================================
        alu_result = 32'h0000_1000;
        funct3     = 3'b000;

        #1;

        if (
            mem_data        === 32'h0000_0078 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 4  LB positive:                PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 4  LB positive:                FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 5: LBU positive
        // ==========================================
        funct3 = 3'b100;

        #1;

        if (
            mem_data        === 32'h0000_0078 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 5  LBU positive:               PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 5  LBU positive:               FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 6: SB control legality
        // ==========================================
        MemRead    = 1'b0;
        MemWrite   = 1'b1;
        funct3     = 3'b000;
        alu_result = 32'h0000_1010;
        wdata      = 32'h0000_00F8;

        #1;

        if (illegal_control === 1'b0) begin
            $display("Test 6  SB control:                 PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 6  SB control:                 FAIL");
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        #1;

        MemWrite = 1'b0;
        MemRead  = 1'b1;
        funct3   = 3'b000;

        #1;

        if (
            mem_data        === 32'hFFFF_FFF8 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 7  LB negative sign extension: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 7  LB negative sign extension: FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 8: LBU zero extension
        // ==========================================
        funct3 = 3'b100;

        #1;

        if (
            mem_data        === 32'h0000_00F8 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 8  LBU zero extension:         PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 8  LBU zero extension:         FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 9: SH control legality
        // ==========================================
        MemRead    = 1'b0;
        MemWrite   = 1'b1;
        funct3     = 3'b001;
        alu_result = 32'h0000_1020;
        wdata      = 32'hABCD_F234;

        #1;

        if (illegal_control === 1'b0) begin
            $display("Test 9  SH control:                 PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 9  SH control:                 FAIL");
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        #1;

        MemWrite = 1'b0;
        MemRead  = 1'b1;
        funct3   = 3'b001;

        #1;

        if (
            mem_data        === 32'hFFFF_F234 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 10 SH -> LH sign extension:    PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 10 SH -> LH sign extension:    FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 11: LHU zero extension
        // ==========================================
        funct3 = 3'b101;

        #1;

        if (
            mem_data        === 32'h0000_F234 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 11 LHU zero extension:         PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 11 LHU zero extension:         FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 12: SB overwrites only one byte
        // ==========================================

        // First store 0x11223344
        MemRead    = 1'b0;
        MemWrite   = 1'b1;
        alu_result = 32'h0000_1030;
        funct3     = 3'b010;
        wdata      = 32'h1122_3344;

        #1;

        if (illegal_control !== 1'b0) begin
            $display("Test 12a Initial SW control:        FAIL");
            fail_count = fail_count + 1;
        end
        else begin
            $display("Test 12a Initial SW control:        PASS");
            pass_count = pass_count + 1;
        end

        @(posedge clk);
        #1;

        // Overwrite second byte with 0xAA
        alu_result = 32'h0000_1031;
        funct3     = 3'b000;
        wdata      = 32'h0000_00AA;

        #1;

        if (illegal_control !== 1'b0) begin
            $display("Test 12b SB control:                FAIL");
            fail_count = fail_count + 1;
        end
        else begin
            $display("Test 12b SB control:                PASS");
            pass_count = pass_count + 1;
        end

        @(posedge clk);
        #1;

        MemWrite   = 1'b0;
        MemRead    = 1'b1;
        alu_result = 32'h0000_1030;
        funct3     = 3'b010;

        #1;

        if (mem_data === 32'h1122_AA44) begin
            $display("Test 12c SB byte overwrite:         PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 12c SB byte overwrite: FAIL, mem_data=%h",
                mem_data
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 13: SH overwrites only two bytes
        // ==========================================
        MemRead    = 1'b0;
        MemWrite   = 1'b1;
        alu_result = 32'h0000_1030;
        funct3     = 3'b001;
        wdata      = 32'h0000_BEEF;

        #1;

        if (illegal_control === 1'b0) begin
            $display("Test 13a SH control:                PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 13a SH control:                FAIL");
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        #1;

        MemWrite = 1'b0;
        MemRead  = 1'b1;
        funct3   = 3'b010;

        #1;

        if (mem_data === 32'h1122_BEEF) begin
            $display("Test 13b SH halfword overwrite:     PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 13b SH halfword overwrite: FAIL, mem_data=%h",
                mem_data
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 14: Illegal Load funct3 = 011
        // ==========================================
        MemRead    = 1'b1;
        MemWrite   = 1'b0;
        funct3     = 3'b011;

        #1;

        if (
            illegal_control === 1'b1 &&
            mem_data        === 32'b0
        ) begin
            $display("Test 14 Illegal Load funct3:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 14 Illegal Load funct3:        FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 15: Illegal Store funct3 = 111
        // ==========================================
        MemRead    = 1'b0;
        MemWrite   = 1'b1;
        funct3     = 3'b111;
        alu_result = 32'h0000_1040;
        wdata      = 32'hDEAD_BEEF;

        #1;

        if (illegal_control === 1'b1) begin
            $display("Test 15 Illegal Store funct3:       PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 15 Illegal Store funct3:       FAIL");
            fail_count = fail_count + 1;
        end

        // Allow clock edge to verify that an illegal store
        // does not accidentally match a write case.
        @(posedge clk);
        #1;

        MemWrite = 1'b0;


        // ==========================================
        // Test 16: Read and Write both enabled
        // ==========================================
        MemRead  = 1'b1;
        MemWrite = 1'b1;
        funct3   = 3'b010;

        #1;

        if (
            illegal_control === 1'b1 &&
            mem_data        === 32'b0
        ) begin
            $display("Test 16 Read/Write conflict:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 16 Read/Write conflict:        FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 17: Recovery to idle
        // ==========================================
        MemRead  = 1'b0;
        MemWrite = 1'b0;

        #1;

        if (
            mem_data        === 32'b0 &&
            illegal_control === 1'b0
        ) begin
            $display("Test 17 Recovery:                   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 17 Recovery:                   FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Final summary
        // ==========================================
        $display("");
        $display("================================");
        $display("DMEM TEST SUMMARY");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);

        if (fail_count == 0)
            $display("FINAL RESULT: ALL TESTS PASSED");
        else
            $display("FINAL RESULT:      TEST FAILED");

        $display("================================");

        $finish;
    end

endmodule