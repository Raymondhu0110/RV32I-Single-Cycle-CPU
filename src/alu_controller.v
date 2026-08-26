module alu_controller (
    input [1:0] ALUop,
    input [2:0] funct3,
    input [6:0] funct7,

    output reg [3:0] op,
    output reg illegal_alu
);
    
    always @(*) begin
        op       = 4'b0000;
        illegal_alu = 1'b0;

        case (ALUop)
            2'b00:begin
                op = 4'b0000;
            end

            2'b01:begin  //Branch compare
                case (funct3)
                    3'b000: op = 4'b1000; //SUB->BEQ
                    3'b001: op = 4'b1000; //SUB->BNE

                    3'b100: op = 4'b0010; //SLT->BLT
                    3'b101: op = 4'b0010; //SLT->BGE
                   
                    3'b110: op = 4'b0011; //SLTU->BLTU
                    3'b111: op = 4'b0011; //SLTU->BGEU
                    
                    default: illegal_alu = 1'b1;
                endcase
            end

            2'b10:begin
                case (funct3)
                    3'b000: op = 4'b0000; //ADDI
                    3'b001: begin
                        if (funct7 == 7'b0000000)
                            op = 4'b0001; //SLLI
                        else
                            illegal_alu = 1'b1;
                    end 
                    3'b010: op = 4'b0010; //SLTI
                    3'b011: op = 4'b0011; //SLTIU
                    3'b100: op = 4'b0100; //XORI
                    3'b101: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0101; //SRLI
                        else if (funct7 == 7'b0100000)
                            op = 4'b1101; //SRAI
                        else
                            illegal_alu = 1'b1;
                    end 
                    3'b110: op = 4'b0110; //ORI
                    3'b111: op = 4'b0111; //ANDI
                    
                    default: illegal_alu = 1'b1;
                endcase
            end

            2'b11:begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0000; //ADD
                        else if (funct7 == 7'b0100000)
                            op = 4'b1000; //SUB
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b001: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0001; //SLL
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b010: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0010; //SLT
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b011: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0011; //SLTU
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b100: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0100; //XOR
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0101; //SRL
                        else if (funct7 == 7'b0100000)
                            op = 4'b1101; //SRA
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b110: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0110; //OR
                        else
                            illegal_alu = 1'b1;
                    end
                    3'b111: begin
                        if (funct7 == 7'b0000000) 
                            op = 4'b0111; //AND
                        else
                            illegal_alu = 1'b1;
                    end
                    default: illegal_alu = 1'b1;
                endcase
            end

            default: illegal_alu = 1'b1;
        endcase
    end
endmodule