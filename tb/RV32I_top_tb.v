`timescale 1ns/1ps

module RV32I_top_tb;

    parameter DEPTH      = 16384;
    parameter MAX_CYCLES = 20;

    reg clk;
    reg rst_n;
    reg enable;

    wire decoder_illegal_ins;
    wire BJ_illegal_ins;
    wire imm_gen_illegal_ins;
    wire alu_controller_illegal_alu;
    wire dmem_illegal_control;
    wire memtoregMUX_illegal_control;
    wire pcsrcMUX_illegal_control;

    integer cycle_count;
    integer pass_count;
    integer fail_count;
    integer pc16_count;

    reg reached_final_loop;

    // Sticky verification flags:
    // once an error is observed, it remains recorded.
    reg decoder_illegal_seen;
    reg BJ_illegal_seen;
    reg imm_gen_illegal_seen;
    reg alu_controller_illegal_seen;
    reg dmem_illegal_seen;
    reg memtoregMUX_illegal_seen;
    reg pcsrcMUX_illegal_seen;

    reg x0_read_observed;
    reg x0_read_error;

    reg [31:0] executing_pc;
    reg [31:0] executing_instruction;


    RV32I_top #(
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),

        .decoder_illegal_ins(decoder_illegal_ins),
        .BJ_illegal_ins(BJ_illegal_ins),
        .imm_gen_illegal_ins(imm_gen_illegal_ins),
        .alu_controller_illegal_alu(
            alu_controller_illegal_alu
        ),
        .dmem_illegal_control(dmem_illegal_control),
        .memtoregMUX_illegal_control(
            memtoregMUX_illegal_control
        ),
        .pcsrcMUX_illegal_control(
            pcsrcMUX_illegal_control
        )
    );


    // ==========================================
    // Clock: 10 ns period
    // ==========================================
    always #5 clk = ~clk;


    // ==========================================
    // Monitor illegal signals and x0 reads
    //
    // At the rising edge, dut.pc and related
    // combinational signals still represent the
    // instruction being completed at that edge.
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoder_illegal_seen        <= 1'b0;
            BJ_illegal_seen             <= 1'b0;
            imm_gen_illegal_seen        <= 1'b0;
            alu_controller_illegal_seen <= 1'b0;
            dmem_illegal_seen           <= 1'b0;
            memtoregMUX_illegal_seen    <= 1'b0;
            pcsrcMUX_illegal_seen       <= 1'b0;

            x0_read_observed            <= 1'b0;
            x0_read_error               <= 1'b0;
        end
        else if (enable) begin

            // Record each illegal signal separately.
            // !== catches both logic 1 and X/Z.
            if (decoder_illegal_ins !== 1'b0)
                decoder_illegal_seen <= 1'b1;

            if (BJ_illegal_ins !== 1'b0)
                BJ_illegal_seen <= 1'b1;

            if (imm_gen_illegal_ins !== 1'b0)
                imm_gen_illegal_seen <= 1'b1;

            if (alu_controller_illegal_alu !== 1'b0)
                alu_controller_illegal_seen <= 1'b1;

            if (dmem_illegal_control !== 1'b0)
                dmem_illegal_seen <= 1'b1;

            if (memtoregMUX_illegal_control !== 1'b0)
                memtoregMUX_illegal_seen <= 1'b1;

            if (pcsrcMUX_illegal_control !== 1'b0)
                pcsrcMUX_illegal_seen <= 1'b1;


            // Architectural x0 verification.
            //
            // Whenever the current instruction reads
            // rs1=x0, rdata1 must be exactly zero.
            if (dut.rs1 === 5'd0) begin
                x0_read_observed <= 1'b1;

                if (dut.rdata1 !== 32'b0)
                    x0_read_error <= 1'b1;
            end

            // Whenever the current instruction reads
            // rs2=x0, rdata2 must be exactly zero.
            if (dut.rs2 === 5'd0) begin
                x0_read_observed <= 1'b1;

                if (dut.rdata2 !== 32'b0)
                    x0_read_error <= 1'b1;
            end
        end
    end


    initial begin
        $dumpfile("RV32I_top_wave.vcd");
        $dumpvars(0, RV32I_top_tb);

        clk         = 1'b0;
        rst_n       = 1'b1;
        enable      = 1'b0;

        cycle_count = 0;
        pass_count  = 0;
        fail_count  = 0;
        pc16_count  = 0;

        reached_final_loop = 1'b0;

        decoder_illegal_seen        = 1'b0;
        BJ_illegal_seen             = 1'b0;
        imm_gen_illegal_seen        = 1'b0;
        alu_controller_illegal_seen = 1'b0;
        dmem_illegal_seen           = 1'b0;
        memtoregMUX_illegal_seen    = 1'b0;
        pcsrcMUX_illegal_seen       = 1'b0;

        x0_read_observed = 1'b0;
        x0_read_error    = 1'b0;

        executing_pc          = 32'b0;
        executing_instruction = 32'b0;


        // ==========================================
        // Reset
        // ==========================================
        #2;
        rst_n = 1'b0;

        #8;
        rst_n  = 1'b1;
        enable = 1'b1;


        // ==========================================
        // Expected program
        //
        // PC 0  : ADDI x1, x0, 5
        // PC 4  : ADDI x2, x0, 7
        // PC 8  : ADD  x3, x1, x2
        // PC 12 : SUB  x4, x3, x1
        // PC 16 : JAL  x0, 0
        //
        // The loop terminates after PC=16 has been
        // observed for three consecutive cycles.
        // ==========================================
        while (
            !reached_final_loop &&
            cycle_count < MAX_CYCLES
        ) begin

            // Capture the instruction before its
            // rising-edge state update.
            @(negedge clk);

            executing_pc          = dut.pc;
            executing_instruction = dut.instruction;

            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            $display(
                "Cycle=%0d | executed PC=%0d INST=%h | next PC=%0d | x1=%0d x2=%0d x3=%0d x4=%0d",
                cycle_count,
                executing_pc,
                executing_instruction,
                dut.pc,
                dut.regfile_unit.rf_depth[1],
                dut.regfile_unit.rf_depth[2],
                dut.regfile_unit.rf_depth[3],
                dut.regfile_unit.rf_depth[4]
            );


            // Require PC=16 for three consecutive
            // completed cycles. This checks that the
            // processor remains in the JAL loop.
            if (dut.pc === 32'd16)
                pc16_count = pc16_count + 1;
            else
                pc16_count = 0;

            if (pc16_count >= 3)
                reached_final_loop = 1'b1;
        end


        // Allow nonblocking assignments in the
        // monitoring always block to settle.
        #1;


        $display("");
        $display("========================================");
        $display("       RV32I TOP INTEGRATION TEST");
        $display("========================================");


        // ==========================================
        // Test 1: Program reached final loop
        // ==========================================
        if (reached_final_loop === 1'b1) begin
            $display(
                "Test 1 Final JAL loop:           PASS"
            );
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 1 Final JAL loop:           FAIL (PC=%h, cycles=%0d)",
                dut.pc,
                cycle_count
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 2: Register results
        // ==========================================
        if (
            dut.regfile_unit.rf_depth[1] === 32'd5  &&
            dut.regfile_unit.rf_depth[2] === 32'd7  &&
            dut.regfile_unit.rf_depth[3] === 32'd12 &&
            dut.regfile_unit.rf_depth[4] === 32'd7
        ) begin
            $display(
                "Test 2 Register results:         PASS"
            );
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 2 Register results:         FAIL"
            );

            $display(
                "       x1=%h x2=%h x3=%h x4=%h",
                dut.regfile_unit.rf_depth[1],
                dut.regfile_unit.rf_depth[2],
                dut.regfile_unit.rf_depth[3],
                dut.regfile_unit.rf_depth[4]
            );

            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 3: x0 architectural read behavior
        // ==========================================
        if (
            x0_read_observed === 1'b1 &&
            x0_read_error    === 1'b0
        ) begin
            $display(
                "Test 3 x0 always reads zero:     PASS"
            );
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 3 x0 always reads zero:     FAIL"
            );

            $display(
                "       observed=%b read_error=%b",
                x0_read_observed,
                x0_read_error
            );

            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 4: All illegal signals stayed zero
        // throughout execution
        // ==========================================
        if (
            decoder_illegal_seen         === 1'b0 &&
            BJ_illegal_seen              === 1'b0 &&
            imm_gen_illegal_seen         === 1'b0 &&
            alu_controller_illegal_seen  === 1'b0 &&
            dmem_illegal_seen            === 1'b0 &&
            memtoregMUX_illegal_seen     === 1'b0 &&
            pcsrcMUX_illegal_seen        === 1'b0
        ) begin
            $display(
                "Test 4 No illegal signal seen:   PASS"
            );
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 4 No illegal signal seen:   FAIL"
            );

            $display(
                "       decoder=%b BJ=%b imm=%b alu_ctrl=%b",
                decoder_illegal_seen,
                BJ_illegal_seen,
                imm_gen_illegal_seen,
                alu_controller_illegal_seen
            );

            $display(
                "       dmem=%b wb_mux=%b pc_mux=%b",
                dmem_illegal_seen,
                memtoregMUX_illegal_seen,
                pcsrcMUX_illegal_seen
            );

            fail_count = fail_count + 1;
        end


        // ==========================================
        // Final summary
        // ==========================================
        $display("========================================");
        $display("FINAL TEST SUMMARY");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);

        if (fail_count == 0)
            $display("FINAL RESULT: ALL TESTS PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        $display("========================================");
        $display("");

        $finish;
    end

endmodule