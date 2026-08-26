module imem #(parameter DEPTH = 16384) (
    input wire  [31:0]       raddr,
    output wire [31:0] instruction
);

    reg [7:0] mem [0:DEPTH-1];

    assign instruction = {
        mem[raddr+3],
        mem[raddr+2],
        mem[raddr+1],
        mem[raddr]
    };

    initial begin
    $readmemb("imem_code.txt", mem);
    end
    
endmodule