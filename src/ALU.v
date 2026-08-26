module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op,

    output reg [31:0] result,
    output reg          zero,
    output reg   less_signed,
    output reg less_unsigned
);
    always @(*) begin
        zero          = 1'b0;
        less_signed   = 1'b0;
        less_unsigned = 1'b0;

        case (op)
            4'b0000: begin      //ADD
                result = a + b;
            end
            4'b1000: begin      //SUB
                result = a - b;
            end
            4'b0001: begin      //SLL (shift left logical)
                result = a << b[$clog2(32)-1:0];
            end
            4'b0010: begin      //SLT (set less than)
                result = ($signed(a) < $signed(b)) ? {31'b0, 1'b1} : 32'b0;
                less_signed = ($signed(a) < $signed(b));
            end
            4'b0011: begin      //SLTU (set less than unsigned)
                result = (a < b) ? {31'b0, 1'b1} : 32'b0;
                less_unsigned = (a < b);
            end
            4'b0100: begin      //XOR
                result = a ^ b;
            end
            4'b0101: begin      //SRL (shift right logical)
                result = a >> b[$clog2(32)-1:0];
            end
            4'b1101: begin      //SRA (shift right arithmetic)
                result = $signed(a) >>> b[$clog2(32)-1:0];
            end
            4'b0110: begin      //OR
                result = a | b;
            end
            4'b0111: begin      //AND
                result = a & b;
            end

            default: result = 32'b0;
        endcase

        zero = (result == 32'b0);
        
    end
    
endmodule