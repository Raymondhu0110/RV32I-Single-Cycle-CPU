module imm_gen (
    input wire [31:0] instruction,
    output reg [31:0]         imm,
    output reg        illegal_ins
);

    always @(*) begin

        imm        = 32'b0;
        illegal_ins = 1'b0;


        case (instruction[6:0]) //opcode
            7'b0010011, 7'b0000011, 7'b1100111: begin  //I-Type-ALU, Load, JALR
                imm = {{20{instruction[31]}}, instruction[31:20]};
            end
            7'b0100011: begin  //S-Type
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            7'b1100011: begin  //B-Type
                imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            7'b0110111, 7'b0010111: begin  //U-Type
                imm = {instruction[31:12], 12'b0};
            end
            7'b1101111: begin  //J-Type
                imm = {{12{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            7'b0110011: begin //R-Type-ALU
                imm = 32'b0;
            end

            default: illegal_ins = 1'b1;
        endcase
    end
    
endmodule