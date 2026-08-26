module bj_unit (
    input wire          Branch,
    input wire            Jump,
    input wire            Jalr, 
    input wire    [2:0] funct3,

    input wire            zero,
    input wire     less_signed,
    input wire   less_unsigned,

    output reg    [1:0]  PCSrc,
    output reg     illegal_ins
);

    always @(*) begin
        PCSrc      = 2'b00;
        illegal_ins = 1'b0;

        if (Branch==1'b0 && Jump==1'b0 && Jalr==1'b0) begin
            PCSrc = 2'b00;
        end
        else if (Branch==1'b0 && Jump==1'b1 && Jalr==1'b0) begin
            PCSrc = 2'b01;
        end
        else if (Branch==1'b0 && Jump==1'b0 && Jalr==1'b1) begin
            PCSrc = 2'b10;
        end
        else if (Branch==1'b1 && Jump==1'b0 && Jalr==1'b0) begin
            case (funct3)
                3'b000: PCSrc = (zero)           ? 2'b01 : 2'b00;  //BEQ    
                3'b001: PCSrc = (!zero)          ? 2'b01 : 2'b00; //BNE
                3'b100: PCSrc = (less_signed)    ? 2'b01 : 2'b00; //BLT
                3'b101: PCSrc = (!less_signed)   ? 2'b01 : 2'b00; //BGE
                3'b110: PCSrc = (less_unsigned)  ? 2'b01 : 2'b00; //BLTU
                3'b111: PCSrc = (!less_unsigned) ? 2'b01 : 2'b00; //BGEU
                default: illegal_ins = 1'b1;
            endcase
        end
        else begin
            illegal_ins = 1'b1;
        end         
    end 
endmodule