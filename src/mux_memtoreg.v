module mux_memtoreg (
    input wire [31:0] alu_result,
    input wire [31:0]   mem_data,
    input wire [31:0]       pc_4,
    input wire [31:0]        imm,
    input wire [31:0]     pc_imm,

    input wire [2:0]    MemtoReg,

    output reg [31:0]      wdata,
    output reg   illegal_control
);

    always @(*) begin

        wdata =          32'b0;
        illegal_control = 1'b0;

        case (MemtoReg)
            3'b000: wdata = alu_result;
            3'b001: wdata =   mem_data;
            3'b010: wdata =       pc_4;
            3'b011: wdata =        imm;
            3'b100: wdata =     pc_imm;
            default: illegal_control = 1'b1;
        endcase
    end
endmodule