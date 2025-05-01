`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.02.2025 13:00:35
// Design Name: 
// Module Name: riscv_alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module riscv_alu (
    input [3:0] alu_op_i,
    input [31:0] alu_a_i,
    input [31:0] alu_b_i,
    output reg [31:0] alu_p_o
);

    always @(*) begin
        case (alu_op_i)
            4'b0000: alu_p_o = alu_a_i + alu_b_i; // ADD
            4'b0001: alu_p_o = alu_a_i - alu_b_i; // SUB
            4'b0010: alu_p_o = alu_a_i & alu_b_i; // AND
            4'b0011: alu_p_o = alu_a_i | alu_b_i; // OR
            4'b0100: alu_p_o = alu_a_i ^ alu_b_i; // XOR
            4'b0101: alu_p_o = alu_a_i << alu_b_i[4:0]; // SLL (Shift Left Logical)
            4'b0110: alu_p_o = alu_a_i >> alu_b_i[4:0]; // SRL (Shift Right Logical)
            4'b0111: alu_p_o = $signed(alu_a_i) >>> alu_b_i[4:0]; // SRA (Shift Right Arithmetic)
            4'b1000: alu_p_o = ($signed(alu_a_i) < $signed(alu_b_i)) ? 32'd1 : 32'd0; // SLT (Set Less Than)
            4'b1001: alu_p_o = (alu_a_i < alu_b_i) ? 32'd1 : 32'd0; // SLTU (Set Less Than Unsigned)
            4'b1010: alu_p_o = (alu_a_i * alu_b_i); // MUL
            default: alu_p_o = 32'b0; // Default case
        endcase
    end

endmodule

