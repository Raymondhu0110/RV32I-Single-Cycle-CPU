module regfile (
    input wire   clk,
    input wire rst_n,

    input wire  [4:0]  raddr1,
    output wire [31:0] rdata1,

    input wire  [4:0]  raddr2,
    output wire [31:0] rdata2,

    input wire             we,
    input wire  [4:0]   waddr,
    input wire  [31:0]  wdata
);

    reg [31:0] rf_depth [0:31];
    localparam [31:0] ZERO = 32'b0;
    localparam [4:0]  ADDR_ZERO = 5'b0;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i = 1; i < 32; i=i+1)begin
                rf_depth[i] <= ZERO;
            end 
        end else if(we && (waddr != ADDR_ZERO))begin
            rf_depth[waddr] <= wdata;
        end
    end

            
    assign rdata1 = (raddr1 == ADDR_ZERO)? ZERO : rf_depth[raddr1];
    assign rdata2 = (raddr2 == ADDR_ZERO)? ZERO : rf_depth[raddr2];

endmodule