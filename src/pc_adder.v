module pc_adder (
    input wire [31:0]     PC,
    input wire [31:0]    imm,

    output wire [31:0] pc_imm,
    output wire [31:0]   pc_4
);
    assign pc_4   = PC + 32'd4;
    assign pc_imm =   PC + imm;
endmodule