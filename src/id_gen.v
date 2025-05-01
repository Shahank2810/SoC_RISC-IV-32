`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2025 07:03:05
// Design Name: 
// Module Name: id_gen
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


module id_gen(
    input arvalid,arready,clk,rst,awvalid,awready,
    input [3:0]arid,awid,
    input [31:0] addr,
    output reg [3:0] id,bid
    );
    always@(posedge clk)begin
    if(!rst)begin
     id     <= 4'b0;
     bid    <=4'b0;
     end
    if (arvalid && arready)
    begin
        id     <= arid;
    end
    if (awvalid && awready) bid     <= awid;
    end
endmodule
