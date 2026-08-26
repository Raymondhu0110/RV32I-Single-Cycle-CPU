`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  op;

    wire [31:0] result;
    wire        zero;
    wire        less_signed;
    wire        less_unsigned;

    integer pass_count;
    integer fail_count;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .less_signed(less_signed),
        .less_unsigned(less_unsigned)
    );

    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, alu_tb);

        pass_count = 0;
        fail_count = 0;

        // =========================
        // Test 1: ADD
        // 5 + 7 = 12
        // =========================
        op = 4'b0000;
        a  = 32'd5;
        b  = 32'd7;
        #1;

        if (
            result        === 32'd12 &&
            zero          === 1'b0   &&
            less_signed   === 1'b0   &&
            less_unsigned === 1'b0
        ) begin
            $display("Test 1  ADD:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 1  ADD:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 2: ADD result = 0
        // 0 + 0 = 0
        // =========================
        op = 4'b0000;
        a  = 32'd0;
        b  = 32'd0;
        #1;

        if (result === 32'd0 && zero === 1'b1) begin
            $display("Test 2  ADD Zero:   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 2  ADD Zero:   FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 3: SUB
        // 10 - 3 = 7
        // =========================
        op = 4'b1000;
        a  = 32'd10;
        b  = 32'd3;
        #1;

        if (result === 32'd7 && zero === 1'b0) begin
            $display("Test 3  SUB:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 3  SUB:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 4: SUB equal
        // 10 - 10 = 0
        // =========================
        op = 4'b1000;
        a  = 32'd10;
        b  = 32'd10;
        #1;

        if (result === 32'd0 && zero === 1'b1) begin
            $display("Test 4  SUB Zero:   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 4  SUB Zero:   FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 5: SLL
        // 3 << 2 = 12
        // =========================
        op = 4'b0001;
        a  = 32'h0000_0003;
        b  = 32'd2;
        #1;

        if (result === 32'h0000_000C) begin
            $display("Test 5  SLL:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 5  SLL:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 6: SLT signed true
        // -5 < 3
        // =========================
        op = 4'b0010;
        a  = 32'hFFFF_FFFB; // -5
        b  = 32'h0000_0003; // 3
        #1;

        if (
            result        === 32'd1 &&
            less_signed   === 1'b1  &&
            less_unsigned === 1'b0
        ) begin
            $display("Test 6  SLT True:   PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 6  SLT True:   FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 7: SLT signed false
        // 5 < -3 is false
        // =========================
        op = 4'b0010;
        a  = 32'h0000_0005; // 5
        b  = 32'hFFFF_FFFD; // -3
        #1;

        if (
            result        === 32'd0 &&
            zero          === 1'b1 &&
            less_signed   === 1'b0 &&
            less_unsigned === 1'b0
        ) begin
            $display("Test 7  SLT False:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 7  SLT False:  FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 8: SLTU false
        // 0xFFFF_FFFB = 4294967291
        // 4294967291 < 3 is false
        // =========================
        op = 4'b0011;
        a  = 32'hFFFF_FFFB;
        b  = 32'h0000_0003;
        #1;

        if (
            result        === 32'd0 &&
            less_unsigned === 1'b0 &&
            less_signed   === 1'b0
        ) begin
            $display("Test 8  SLTU False: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 8  SLTU False: FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 9: SLTU true
        // 3 < 5
        // =========================
        op = 4'b0011;
        a  = 32'd3;
        b  = 32'd5;
        #1;

        if (
            result        === 32'd1 &&
            less_unsigned === 1'b1 &&
            less_signed   === 1'b0
        ) begin
            $display("Test 9  SLTU True:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 9  SLTU True:  FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 10: XOR
        // =========================
        op = 4'b0100;
        a  = 32'hCA00_00CA;
        b  = 32'hAC00_00AC;
        #1;

        if (result === 32'h6600_0066) begin
            $display("Test 10 XOR:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 10 XOR:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 11: SRL
        // 0x80000000 >> 2
        // Logical shift fills with zero
        // =========================
        op = 4'b0101;
        a  = 32'h8000_0000;
        b  = 32'd2;
        #1;

        if (result === 32'h2000_0000) begin
            $display("Test 11 SRL:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 11 SRL:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 12: SRA
        // 0x80000000 >>> 4
        // Arithmetic shift copies sign bit
        // =========================
        op = 4'b1101;
        a  = 32'h8000_0000;
        b  = 32'd4;
        #1;

        if (result === 32'hF800_0000) begin
            $display("Test 12 SRA:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 12 SRA:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 13: OR
        // =========================
        op = 4'b0110;
        a  = 32'hCA00_00CA;
        b  = 32'hAC00_00AC;
        #1;

        if (result === 32'hEE00_00EE) begin
            $display("Test 13 OR:         PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 13 OR:         FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 14: AND
        // =========================
        op = 4'b0111;
        a  = 32'hCA00_00CA;
        b  = 32'hAC00_00AC;
        #1;

        if (result === 32'h8800_0088) begin
            $display("Test 14 AND:        PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 14 AND:        FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Test 15: Invalid ALU op
        // =========================
        op = 4'b1111;
        a  = 32'd25;
        b  = 32'd10;
        #1;

        if (
            result        === 32'd0 &&
            zero          === 1'b1 &&
            less_signed   === 1'b0 &&
            less_unsigned === 1'b0
        ) begin
            $display("Test 15 Invalid OP: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 15 Invalid OP: FAIL");
            fail_count = fail_count + 1;
        end


        // =========================
        // Final result
        // =========================
        $display("");
        $display("==============================");
        $display("ALU TEST SUMMARY");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);

        if (fail_count == 0)
            $display("FINAL RESULT: ALL TESTS PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        $display("==============================");

        $finish;
    end

endmodule