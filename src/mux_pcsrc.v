module mux_pcsrc (
    input wire [31:0] alu_result,
    input wire [31:0]       pc_4,
    input wire [31:0]     pc_imm,

    input wire [1:0]       PCSrc,

    output reg [31:0]    next_pc,
    output reg   illegal_control
);

    always @(*) begin

        next_pc        = 32'b0;
        illegal_control = 1'b0;

        case (PCSrc)
            2'b00: next_pc =                     pc_4;
            2'b01: next_pc =                   pc_imm;
            2'b10: next_pc = {alu_result[31:1], 1'b0};

            default: illegal_control = 1'b1;
        endcase
    end
endmodule