module mux_alusrc (

    input wire [31:0]        imm,
    input wire [31:0]     rdata2,

    input wire            ALUSrc,

    output reg [31:0]          b
);

    assign b = (ALUSrc) ? imm : rdata2;

endmodule