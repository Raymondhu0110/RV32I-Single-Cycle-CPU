module decoder (
    input wire [31:0] instruction,

    output wire [4:0]     rd,
    output wire [2:0] funct3,
    output wire [4:0]    rs1,
    output wire [4:0]    rs2,
    output wire [6:0] funct7,

    output reg          ALUSrc,
    output reg  [1:0]    ALUop,
    output reg  [2:0] MemtoReg,
    output reg        RegWrite,
    output reg        MemWrite,
    output reg         MemRead,
    output reg          Branch,
    output reg            Jump,
    output reg            Jalr,
    output reg     illegal_ins
);

    wire [6:0] opcode;

    assign opcode =   instruction[6:0];
    assign rd =      instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 =    instruction[19:15];
    assign rs2 =    instruction[24:20];
    assign funct7 = instruction[31:25];

    always @(*) begin

        ALUSrc =      1'b0;
        ALUop =      2'b00;
        MemtoReg =  3'b000;
        RegWrite =    1'b0; 
        MemWrite =    1'b0;
        MemRead =     1'b0;
        Branch =      1'b0;
        Jump =        1'b0;
        Jalr =        1'b0;
        illegal_ins = 1'b0;

        case (opcode)
            7'b0110011:begin   //R-type ALU
                ALUSrc =     1'b0;
                ALUop =     2'b11;  //ALU control
                MemtoReg = 3'b000;
                RegWrite =   1'b1;  //we=1
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;
                Jump =       1'b0;
                Jalr =       1'b0;
            end 
            7'b0010011:begin   //I-type ALU
                ALUSrc =     1'b1;
                ALUop =     2'b10;  //ALU control
                MemtoReg = 3'b000;
                RegWrite =   1'b1;  //we=1
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;
                Jump =       1'b0;
                Jalr =       1'b0;
            end 
            7'b0000011:begin   //Load
                ALUSrc =     1'b1;
                ALUop =     2'b00;  //Add, ALU result = memory raddr
                MemtoReg = 3'b001;  //write data into regfile
                RegWrite =   1'b1;  //we=1
                MemWrite =   1'b0;
                MemRead =    1'b1;  //read data from memory
                Branch =     1'b0;
                Jump =       1'b0;
                Jalr =       1'b0;
            end 
            7'b0100011:begin   //Store
                ALUSrc =     1'b1;
                ALUop =     2'b00;  //Add, ALU result = memory waddr
                MemtoReg = 3'b000;  //Don't bother
                RegWrite =   1'b0;  
                MemWrite =   1'b1;  //write data into memory
                MemRead =    1'b0;
                Branch =     1'b0;
                Jump =       1'b0;
                Jalr =       1'b0;
            end 
            7'b1100011:begin   //Branch
                ALUSrc =     1'b0;
                ALUop =     2'b01;  //Branch compare
                MemtoReg = 3'b000;  //Don't bother
                RegWrite =   1'b0;
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b1;  //conditional branch instruction
                Jump =       1'b0;
                Jalr =       1'b0;
            end
            7'b0110111:begin   //LUI
                ALUSrc =     1'b0;
                ALUop =     2'b00;  
                MemtoReg = 3'b011;  
                RegWrite =   1'b1;
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;  
                Jump =       1'b0;
                Jalr =       1'b0;
            end 
            7'b0010111:begin   //AUIPC
                ALUSrc =     1'b0;
                ALUop =     2'b00;  
                MemtoReg = 3'b100;  
                RegWrite =   1'b1;
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;  
                Jump =       1'b0;
                Jalr =       1'b0;
            end
            7'b1101111:begin   //JAL
                ALUSrc =     1'b0;
                ALUop =     2'b00;  
                MemtoReg = 3'b010;  
                RegWrite =   1'b1;
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;  
                Jump =       1'b1;
                Jalr =       1'b0;
            end
            7'b1100111:begin   //JALR
                ALUSrc =     1'b1;
                ALUop =     2'b00;  
                MemtoReg = 3'b010;  
                RegWrite =   1'b1;
                MemWrite =   1'b0;
                MemRead =    1'b0;
                Branch =     1'b0;  
                Jump =       1'b0;
                Jalr =       1'b1;
            end
            default:begin
                illegal_ins = 1'b1;
            end
        endcase
    end
endmodule