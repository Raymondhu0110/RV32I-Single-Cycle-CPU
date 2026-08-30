`timescale 1ns/1ps

module RV32I_final_tb;

    parameter DEPTH = 16384;

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

    // ==========================================
    // Sticky illegal flags
    // ==========================================
    reg decoder_illegal_seen;
    reg BJ_illegal_seen;
    reg imm_gen_illegal_seen;
    reg alu_controller_illegal_seen;
    reg dmem_illegal_seen;
    reg memtoregMUX_illegal_seen;
    reg pcsrcMUX_illegal_seen;


    RV32I_top #(
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),

        .decoder_illegal_ins(decoder_illegal_ins),
        .BJ_illegal_ins(BJ_illegal_ins),
        .imm_gen_illegal_ins(imm_gen_illegal_ins),
        .alu_controller_illegal_alu(alu_controller_illegal_alu),
        .dmem_illegal_control(dmem_illegal_control),
        .memtoregMUX_illegal_control(memtoregMUX_illegal_control),
        .pcsrcMUX_illegal_control(pcsrcMUX_illegal_control)
    );


    // ==========================================
    // Clock
    // ==========================================
    always #5 clk = ~clk;


    // ==========================================
    // Record illegal signals during execution
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
        end
        else if (enable) begin
            if (decoder_illegal_ins)
                decoder_illegal_seen <= 1'b1;

            if (BJ_illegal_ins)
                BJ_illegal_seen <= 1'b1;

            if (imm_gen_illegal_ins)
                imm_gen_illegal_seen <= 1'b1;

            if (alu_controller_illegal_alu)
                alu_controller_illegal_seen <= 1'b1;

            if (dmem_illegal_control)
                dmem_illegal_seen <= 1'b1;

            if (memtoregMUX_illegal_control)
                memtoregMUX_illegal_seen <= 1'b1;

            if (pcsrcMUX_illegal_control)
                pcsrcMUX_illegal_seen <= 1'b1;
        end
    end


    // ==========================================
    // Read a 32-bit little-endian word from DMEM
    // ==========================================
    function [31:0] read_dmem_word;
        input [31:0] addr;
        begin
            read_dmem_word = {
                dut.dmem_unit.mem[addr + 3],
                dut.dmem_unit.mem[addr + 2],
                dut.dmem_unit.mem[addr + 1],
                dut.dmem_unit.mem[addr]
            };
        end
    endfunction


    initial begin
        $dumpfile("RV32I_final_wave.vcd");
        $dumpvars(0, RV32I_final_tb);

        clk         = 1'b0;
        rst_n       = 1'b1;
        enable      = 1'b0;
        cycle_count = 0;
        pass_count  = 0;
        fail_count  = 0;

        decoder_illegal_seen        = 1'b0;
        BJ_illegal_seen             = 1'b0;
        imm_gen_illegal_seen        = 1'b0;
        alu_controller_illegal_seen = 1'b0;
        dmem_illegal_seen           = 1'b0;
        memtoregMUX_illegal_seen    = 1'b0;
        pcsrcMUX_illegal_seen       = 1'b0;


        // ==========================================
        // Reset
        // ==========================================
        #2;
        rst_n = 1'b0;

        #8;
        rst_n  = 1'b1;
        enable = 1'b1;


        // ==========================================
        // Run CPU
        //
        // Final program should reach:
        //
        // PC = 0x6C
        // jal x0, 0
        // ==========================================
        while (
            (dut.pc !== 32'h0000_006C) &&
            (cycle_count < 100)
        ) begin
            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            $display(
                "Cycle=%0d PC=%h INST=%h",
                cycle_count,
                dut.pc,
                dut.instruction
            );
        end


        // Execute final loop for two additional cycles.
        // This also gives sticky flags time to update.
        repeat (2) begin
            @(posedge clk);
            #1;
        end


        $display("");
        $display("========================================");
        $display("      FINAL RV32I CPU TEST");
        $display("========================================");


        // ==========================================
        // Test 1: Final loop / timeout
        // ==========================================
        if (dut.pc === 32'h0000_006C) begin
            $display("Test 1 Program reached final loop:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 1 Program reached final loop: FAIL (PC=%h, cycles=%0d)",
                dut.pc,
                cycle_count
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 2: global_offset initialization
        //
        // global_offset @ 0x1070
        // expected = 50000
        // ==========================================
        if (
            read_dmem_word(32'h0000_1070) === 32'd50000
        ) begin
            $display("Test 2 global_offset = 50000:       PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 2 global_offset = 50000:      FAIL (%0d / %h)",
                read_dmem_word(32'h0000_1070),
                read_dmem_word(32'h0000_1070)
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 3: Final C result
        //
        // final_result @ 0x1074
        // expected = 150
        // ==========================================
        if (
            read_dmem_word(32'h0000_1074) === 32'd150
        ) begin
            $display("Test 3 final_result = 150:          PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 3 final_result = 150:         FAIL (%0d / %h)",
                read_dmem_word(32'h0000_1074),
                read_dmem_word(32'h0000_1074)
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 4: Stack pointer in DMEM range
        //
        // DEPTH = 16384 = 0x4000 bytes
        // x2 must be less than DEPTH.
        // ==========================================
        if (
            dut.regfile_unit.rf_depth[2] < DEPTH
        ) begin
            $display(
                "Test 4 Stack pointer in DMEM range: PASS (x2=%h)",
                dut.regfile_unit.rf_depth[2]
            );
            pass_count = pass_count + 1;
        end
        else begin
            $display(
                "Test 4 Stack pointer in DMEM range: FAIL (x2=%h)",
                dut.regfile_unit.rf_depth[2]
            );
            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 5: Current illegal signals
        // ==========================================
        if (
            decoder_illegal_ins         === 1'b0 &&
            BJ_illegal_ins              === 1'b0 &&
            imm_gen_illegal_ins         === 1'b0 &&
            alu_controller_illegal_alu  === 1'b0 &&
            dmem_illegal_control        === 1'b0 &&
            memtoregMUX_illegal_control === 1'b0 &&
            pcsrcMUX_illegal_control    === 1'b0
        ) begin
            $display("Test 5 Current illegal signals = 0: PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 5 Current illegal signals = 0: FAIL");

            $display(
                "       decoder=%b BJ=%b imm=%b alu_ctrl=%b dmem=%b wb_mux=%b pc_mux=%b",
                decoder_illegal_ins,
                BJ_illegal_ins,
                imm_gen_illegal_ins,
                alu_controller_illegal_alu,
                dmem_illegal_control,
                memtoregMUX_illegal_control,
                pcsrcMUX_illegal_control
            );

            fail_count = fail_count + 1;
        end


        // ==========================================
        // Test 6: Illegal signals over full execution
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
            $display("Test 6 No illegal signal was seen:  PASS");
            pass_count = pass_count + 1;
        end
        else begin
            $display("Test 6 No illegal signal was seen:  FAIL");

            $display(
                "       decoder_seen=%b BJ_seen=%b imm_seen=%b alu_ctrl_seen=%b",
                decoder_illegal_seen,
                BJ_illegal_seen,
                imm_gen_illegal_seen,
                alu_controller_illegal_seen
            );

            $display(
                "       dmem_seen=%b wb_mux_seen=%b pc_mux_seen=%b",
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
            $display("FINAL RESULT:      TEST FAILED");

        $display("========================================");
        $display("");

        $finish;
    end

endmodule
