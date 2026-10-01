module dmem #(
    parameter DEPTH = 16384
    parameter MEM_FILE = "memory/final_dmem_code.txt"
)(
    input clk,
    
    input wire [31:0] alu_result,
    input wire [31:0]      wdata,

    input wire [2:0]      funct3,
    input wire          MemWrite,
    input wire           MemRead,

    output reg [31:0]   mem_data,
    output reg   illegal_control
);

    reg [7:0] mem [0:DEPTH-1];


    // ==========================================
    // Combinational Read
    // ==========================================

    always @(*) begin
        mem_data       = 32'b0;
        illegal_control = 1'b0;

        if (MemRead==1'b1 && MemWrite==1'b0) begin
            case (funct3)
                3'b000: mem_data = {{24{mem[alu_result][7]}}, mem[alu_result]}; //LB
                3'b001: mem_data = {{16{mem[alu_result+1][7]}}, mem[alu_result+1], mem[alu_result]}; //LH
                3'b010: mem_data = {
                    mem[alu_result+3],
                    mem[alu_result+2],
                    mem[alu_result+1],
                    mem[alu_result]
                }; //LW
                3'b100: mem_data = {24'b0, mem[alu_result]}; //LBU
                3'b101: mem_data = {16'b0, mem[alu_result+1], mem[alu_result]}; //LHU
                default: illegal_control = 1'b1;
            endcase
        end

        else if (MemRead == 1'b0 && MemWrite == 1'b1) begin
            case (funct3)
                3'b000: illegal_control = 1'b0; // SB
                3'b001: illegal_control = 1'b0; // SH
                3'b010: illegal_control = 1'b0; // SW

                default: illegal_control = 1'b1;
            endcase
        end

        else if (MemRead==1'b0 && MemWrite==1'b0) begin  
            mem_data = 32'b0;
        end

        else  //MemRead=1,
            illegal_control = 1'b1;
    end

    // ==========================================
    // Synchronous Write
    // ==========================================

    always @(posedge clk) begin
        if (MemRead==1'b0 && MemWrite==1'b1) begin
            case (funct3)
                3'b000: mem[alu_result] <= wdata[7:0]; //SB
                3'b001: begin
                    mem[alu_result+1] <= wdata[15:8];
                    mem[alu_result]    <= wdata[7:0];
                end  //SH
                3'b010: begin
                    mem[alu_result+3] <= wdata[31:24];
                    mem[alu_result+2] <= wdata[23:16];
                    mem[alu_result+1]  <= wdata[15:8];
                    mem[alu_result]     <= wdata[7:0];
                end //SW
            endcase
        end
    end   

    initial begin
    $readmemb(MEM_FILE, mem);
    end
endmodule
