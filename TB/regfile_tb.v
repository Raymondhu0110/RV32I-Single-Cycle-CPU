`timescale 1ns/1ps

module regfile_tb;

    reg clk;
    reg rst_n;

    reg  [4:0]  raddr1;
    wire [31:0] rdata1;

    reg  [4:0]  raddr2;
    wire [31:0] rdata2;

    reg         we;
    reg  [4:0]  waddr;
    reg  [31:0] wdata;

    integer pass_count;
    integer fail_count;
    integer i;
    reg     reset_correct;

    regfile dut (
        .clk(clk),
        .rst_n(rst_n),

        .raddr1(raddr1),
        .rdata1(rdata1),

        .raddr2(raddr2),
        .rdata2(rdata2),

        .we(we),
        .waddr(waddr),
        .wdata(wdata)
    );

    always #5 clk = ~clk;


    initial begin
        $dumpfile("regfile_wave.vcd");
        $dumpvars(0, regfile_tb);

        clk        = 1'b0;
        rst_n      = 1'b1;
        we         = 1'b0;
        waddr      = 5'b0;
        wdata      = 32'b0;
        raddr1     = 5'b0;
        raddr2     = 5'b0;
        pass_count = 0;
        fail_count = 0;


        // ==========================================
        // Test 1: Asynchronous reset
        // 檢查 x1～x31 是否全部清零
        // ==========================================
        #2;
        rst_n = 1'b0;
        #1;

        rst_n = 1'b1;

        reset_correct = 1'b1;

        for (i = 1; i < 32; i = i + 1) begin
            raddr1 = i;
            #1;

            if (rdata1 !== 32'b0)
                reset_correct = 1'b0;
        end

        if (reset_correct === 1'b1) begin
            $display("Test 1  Reset x1-x31:                PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 1  Reset x1-x31:                FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 2: x0 always reads zero
        // ==========================================
        raddr1 = 5'd0;
        raddr2 = 5'd0;
        #1;

        if (
            rdata1 === 32'b0 &&
            rdata2 === 32'b0
        ) begin
            $display("Test 2  x0 reads zero:               PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 2  x0 reads zero:               FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 3: Write 32-bit value into x3
        // ==========================================
        we    = 1'b1;
        waddr = 5'd3;
        wdata = 32'h1234_5678;

        @(posedge clk);
        #1;

        we     = 1'b0;
        raddr1 = 5'd3;
        #1;

        if (rdata1 === 32'h1234_5678) begin
            $display("Test 3  Write and read x3:           PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 3  Write and read x3: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 4: Write another value into x2
        // ==========================================
        we    = 1'b1;
        waddr = 5'd2;
        wdata = 32'hCAFE_BABE;

        @(posedge clk);
        #1;

        we     = 1'b0;
        raddr1 = 5'd2;
        #1;

        if (rdata1 === 32'hCAFE_BABE) begin
            $display("Test 4  Write and read x2:           PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 4  Write and read x2: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 5: Two simultaneous read ports
        // Port 1 reads x2
        // Port 2 reads x3
        // ==========================================
        raddr1 = 5'd2;
        raddr2 = 5'd3;
        #1;

        if (
            rdata1 === 32'hCAFE_BABE &&
            rdata2 === 32'h1234_5678
        ) begin
            $display("Test 5  Dual-port read:              PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 5  Dual-port read: FAIL, rdata1=%h rdata2=%h",
                rdata1,
                rdata2
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 6: we=0 must prevent write
        // Attempt to overwrite x2
        // ==========================================
        we    = 1'b0;
        waddr = 5'd2;
        wdata = 32'hDEAD_BEEF;

        @(posedge clk);
        #1;

        raddr1 = 5'd2;
        #1;

        if (rdata1 === 32'hCAFE_BABE) begin
            $display("Test 6  Write disabled:              PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 6  Write disabled: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 7: Attempt to write x0
        // x0 must remain zero
        // ==========================================
        we    = 1'b1;
        waddr = 5'd0;
        wdata = 32'hFFFF_FFFF;

        @(posedge clk);
        #1;

        we     = 1'b0;
        raddr1 = 5'd0;
        raddr2 = 5'd0;
        #1;

        if (
            rdata1 === 32'b0 &&
            rdata2 === 32'b0
        ) begin
            $display("Test 7  x0 write protection:         PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 7  x0 write protection: FAIL, rdata1=%h rdata2=%h",
                rdata1,
                rdata2
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 8: Highest register x31
        // 驗證完整 5-bit address
        // ==========================================
        we    = 1'b1;
        waddr = 5'd31;
        wdata = 32'hABCD_EF01;

        @(posedge clk);
        #1;

        we     = 1'b0;
        raddr1 = 5'd31;
        #1;

        if (rdata1 === 32'hABCD_EF01) begin
            $display("Test 8  Write and read x31:          PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 8  Write and read x31: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 9: Write occurs only at rising edge
        // Before clock edge, x4 must remain zero
        // ==========================================
        we    = 1'b1;
        waddr = 5'd4;
        wdata = 32'h8765_4321;

        raddr1 = 5'd4;
        #1;

        if (rdata1 === 32'b0) begin
            $display("Test 9a No write before rising edge: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 9a No write before rising edge: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        #1;

        we = 1'b0;

        if (rdata1 === 32'h8765_4321) begin
            $display("Test 9b Write at rising edge:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 9b Write at rising edge: FAIL, rdata1=%h",
                rdata1
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 10: Asynchronous reset during operation
        // 不等待 clock edge
        // ==========================================
        #2;
        rst_n = 1'b0;
        #1;

        raddr1 = 5'd2;
        raddr2 = 5'd31;
        #1;

        if (
            rdata1 === 32'b0 &&
            rdata2 === 32'b0
        ) begin
            $display("Test 10 Runtime asynchronous reset:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 10 Runtime asynchronous reset: FAIL, rdata1=%h rdata2=%h",
                rdata1,
                rdata2
            );
            fail_count = fail_count + 1;
        end

        rst_n = 1'b1;


        // ==========================================
        // Test 11: x0 after reset
        // ==========================================
        raddr1 = 5'd0;
        raddr2 = 5'd0;
        #1;

        if (
            rdata1 === 32'b0 &&
            rdata2 === 32'b0
        ) begin
            $display("Test 11 x0 after reset:              PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 11 x0 after reset:              FAIL");
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Final summary
        // ==========================================
        $display("");
        $display("================================");
        $display("REGISTER FILE TEST SUMMARY");
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