`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.01.2025 11:19:49
// Design Name: 
// Module Name: bk32_add_sub
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


module BK_Adder_32(Y, Cout, A, B, Cin);

    output [31:0] Y;
    //output reg Cout_reg;
    output Cout;
    input [31:0] A;
    input [31:0] B;
    input Cin;
    //input clk;
    //input rst;
    
    //reg [31:0] A_reg,B_reg;
	//reg Cin_reg;
	
	wire Cout_first;
	//wire [31:0]Y;
    wire [15:0]Y_temp1;
    wire [15:0]Y_temp2;
    wire Cout_temp1;
    wire Cout_temp2;
    
    wire [31:0] p,g;
    wire [31:0] c;
    wire [31:0] B_in; //The output of B xor Cin, to implement subtractor    // does this need to be a wire???
    
    
    assign B_in[31:0] = B ^ {32{Cin}};
      
    bk16 i1 (Y[15:0], Cout_first, A[15:0],B_in[15:0],Cin);
    bk16 i2(Y_temp1, Cout_temp1, A[31:16], B_in[31:16], 1'b0);
    bk16 i3(Y_temp2, Cout_temp2, A[31:16], B_in[31:16], 1'b1);
    
    assign Y[31:16] = Cout_first ? Y_temp2 : Y_temp1;
    assign Cout = Cout_first ? Cout_temp2 : Cout_temp1;
/*
    always@ (posedge clk or posedge rst) begin
        if (rst) begin
            A_reg <= 32'b0;		//reset register A
			B_reg <= 32'b0;		//reset register B
			Cin_reg <= 1'b0;		//reset register cin
			Y_reg <= 32'b0;				//reset Sum 
			Cout_reg <= 1'b0;			//reset Carry out
        end
        else begin
			//capturing inputs
			A_reg <= A;
			B_reg <= B;
			Cin_reg <= Cin;
			
			//update Sum and Carry out
			Y_reg <= Y;
			Cout_reg <= Cout;	
		end 
    end
*/
endmodule

module bk16(Y,cout,A,B,cin);

	//output reg [15:0] Y_reg;	//16 bit sum
	//output reg cout_reg;		//final carry out
	output [15:0] Y;
	output cout;
	input[15:0] A;		//input A
	input[15:0] B;		//input B
	input cin;			//Carry in
	//input CLK;			//Clock signal
	//input RST_N;
	
	
	//reg [15:0] A_reg,B_reg;
	//reg cin_reg;
	
	//wire [15:0]Y;
	//wire cout;
	wire [15:0] p,g; 	//initial propagate and generate signals
	wire [15:0] c;		//intermediate carry
	
	//Declaring intermediate wires for the carry tree
	wire p10,g10,p32,g32,p54,g54,p76,g76,p98,g98,p1110,g1110,p1312,g1312,p1514,g1514;
	wire p30,g30,p74,g74,p118,g118,p1512,g1512;
	wire p70,g70,p158,g158;
	wire p20,g20,p40,g40,p50,g50,p60,g60,p80,g80,p90,g90,p100,g100,p110,g110,p120,g120,p130,g130,p140,g140,p150,g150;
	
	//Generating initial level propagate and generate signals using vectorized XOR and AND
	//assign p = A_reg ^ B_reg;
	//assign g = A_reg & B_reg;
	assign p = A ^ B;
	assign g = A & B;
	
	
	//Carry propagation tree
	//Note: p10 corresponds to (P 1 down to 0), p110 corresponds (P 11 down to 0), etc.
	pg_gen i1 (p[1],p[0],g[1],g[0],p10,g10);
	pg_gen i2 (p[3],p[2],g[3],g[2],p32,g32);
	pg_gen i3 (p[5],p[4],g[5],g[4],p54,g54);
	pg_gen i4 (p[7],p[6],g[7],g[6],p76,g76);
	pg_gen i5 (p[9],p[8],g[9],g[8],p98,g98);
	pg_gen i6 (p[11],p[10],g[11],g[10],p1110,g1110);
	pg_gen i7 (p[13],p[12],g[13],g[12],p1312,g1312);
	pg_gen i8 (p[15],p[14],g[15],g[14],p1514,g1514);
	
	pg_gen i9 (p32,p10,g32,g10,p30,g30);
	pg_gen i10 (p76,p54,g76,g54,p74,g74);
	pg_gen i11 (p1110,p98,g1110,g98,p118,g118);
	pg_gen i12 (p1514,p1312,g1514,g1312,p1512,g1512);
	
	pg_gen i13 (p74,p30,g74,g30,p70,g70);
	pg_gen i14 (p1512,p118,g1512,g118,p158,g158);
	
	pg_gen i15 (p[2],p10,g[2],g10,p20,g20);
	pg_gen i16 (p[4],p30,g[4],g30,p40,g40);
	pg_gen i17 (p54,p30,g54,g30,p50,g50);
	pg_gen i18 (p[6],p50,g[6],g50,p60,g60);
	pg_gen i19 (p[8],p70,g[8],g70,p80,g80);
	pg_gen i20 (p98,p70,g98,g70,p90,g90);
	pg_gen i21 (p[10],p90,g[10],g90,p100,g100);
	pg_gen i22 (p118,p70,g118,g70,p110,g110);
	pg_gen i23 (p[12],p110,g[12],g110,p120,g120);
	pg_gen i24 (p1312,p110,g1312,g110,p130,g130);
	pg_gen i25 (p[14],p130,g[14],g130,p140,g140);
	pg_gen i26 (p158,p70,g158,g70,p150,g150);
	
	//Assigning Carry outs at each stage
	assign c[0] = g[0]| (cin & p[0]);
	assign c[1] = g10 | (cin & p10);
	assign c[2] = g20 | (cin & p20);
	assign c[3] = g30 | (cin & p30);
	assign c[4] = g40 | (cin & p40);
	assign c[5] = g50 | (cin & p50);
	assign c[6] = g60 | (cin & p60);
	assign c[7] = g70 | (cin & p70);
	assign c[8] = g80 | (cin & p80);
	assign c[9] = g90 | (cin & p90);
	assign c[10] = g100 | (cin & p100);
	assign c[11] = g110 | (cin & p110);
	assign c[12] = g120 | (cin & p120);
	assign c[13] = g130 | (cin & p130);
	assign c[14] = g140 | (cin & p140);
	assign c[15] = g150 | (cin & p150);

	assign cout = c[15];
	
	//Assigning Sum out at each stage
	assign Y[0] = p[0] ^ cin;
	assign Y[1] = p[1] ^ c[0];
	assign Y[2] = p[2] ^ c[1];
	assign Y[3] = p[3] ^ c[2];
	assign Y[4] = p[4] ^ c[3];
	assign Y[5] = p[5] ^ c[4];
	assign Y[6] = p[6] ^ c[5];
	assign Y[7] = p[7] ^ c[6];
	assign Y[8] = p[8] ^ c[7];
	assign Y[9] = p[9] ^ c[8];
	assign Y[10] = p[10] ^ c[9];
	assign Y[11] = p[11] ^ c[10];
	assign Y[12] = p[12] ^ c[11];
	assign Y[13] = p[13] ^ c[12];
	assign Y[14] = p[14] ^ c[13];
	assign Y[15] = p[15] ^ c[14];
	
endmodule
	

//Module to make p and g signals
module pg_gen(w,x,y,z,o1,o2);

	input w,x,y,z;
	output o1,o2;
	
	assign o1 = w & x;
	assign o2 = y | (w&z);
		
endmodule
