`timescale 1ns/1ps

module pc_tb;

    reg         clk;
    reg         rst_n;
    reg         enable;
    reg  [31:0] next_pc;

    wire [31:0] pc;

    integer pass_count;
    integer fail_count;

    pc dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .next_pc(next_pc),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pc_wave.vcd");
        $dumpvars(0, pc_tb);

        clk        = 1'b0;
        rst_n      = 1'b1;
        enable     = 1'b0;
        next_pc    = 32'b0;
        pass_count = 0;
        fail_count = 0;


        // ==========================================
        // Test 1: Asynchronous reset
        // 不需要等待 clock edge
        // ==========================================
        #2;
        rst_n = 1'b0;
        #1;

        if (pc === 32'b0) begin
            $display("Test 1  Initial asynchronous reset:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 1  Initial asynchronous reset: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end

        rst_n = 1'b1;


        // ==========================================
        // Test 2: enable=1 updates PC
        // ==========================================
        enable  = 1'b1;
        next_pc = 32'h0000_0019; // 25

        @(posedge clk);
        #1;

        if (pc === 32'h0000_0019) begin
            $display("Test 2  PC update when enable=1:     PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 2  PC update when enable=1: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 3: enable=0 holds previous PC
        // ==========================================
        enable  = 1'b0;
        next_pc = 32'h1234_5678;

        @(posedge clk);
        #1;

        if (pc === 32'h0000_0019) begin
            $display("Test 3  PC hold when enable=0:       PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 3  PC hold when enable=0: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 4: Re-enable and update PC
        // ==========================================
        enable  = 1'b1;
        next_pc = 32'h1234_5678;

        @(posedge clk);
        #1;

        if (pc === 32'h1234_5678) begin
            $display("Test 4  PC update after re-enable:   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 4  PC update after re-enable: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 5: Change next_pc without clock edge
        // PC must not change immediately
        // ==========================================
        next_pc = 32'hAAAA_AAAA;
        #2;

        if (pc === 32'h1234_5678) begin
            $display("Test 5  No update before clock edge: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 5  No update before clock edge: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 6: Asynchronous reset during operation
        // enable=1，但 reset 必須立即清除 PC
        // ==========================================
        rst_n = 1'b0;
        #1;

        if (pc === 32'b0) begin
            $display("Test 6  Runtime asynchronous reset:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 6  Runtime asynchronous reset: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 7: Reset has priority over enable
        // ==========================================
        enable  = 1'b1;
        next_pc = 32'hFFFF_FFFC;

        @(posedge clk);
        #1;

        if (pc === 32'b0) begin
            $display("Test 7  Reset priority over enable:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 7  Reset priority over enable: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 8: Recovery after reset
        // ==========================================
        rst_n   = 1'b1;
        enable  = 1'b1;
        next_pc = 32'hFFFF_FFFC;

        @(posedge clk);
        #1;

        if (pc === 32'hFFFF_FFFC) begin
            $display("Test 8  Recovery after reset:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 8  Recovery after reset: FAIL, pc=%h",
                pc
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Final summary
        // ==========================================
        $display("");
        $display("================================");
        $display("PC TEST SUMMARY");
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