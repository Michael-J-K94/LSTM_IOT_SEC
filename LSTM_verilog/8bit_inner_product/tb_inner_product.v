`timescale 1ns / 1ps
// Testbench file for inner_product
// Author : Jaemin
// To Do :  Make more cases

module tb_inner_product();
    parameter CLK_CYCLE = 2.5;
    parameter CLK_PERIOD = 2*CLK_CYCLE;
	
	reg clk;
	reg resetn;
	reg [7:0] W [15:0];
	reg [7:0] X [15:0];
	wire [7:0] Result;
	
	integer i;
	
///////////
// CLOCK //	
///////////
	initial begin
		clk = 1'b1;
		resetn = 'd0;
	end
	always #CLK_CYCLE clk = ~clk;
	
	
//////////
// MAIN //	
//////////	
	initial begin
		
		repeat(10)
			@(posedge clk);
		
		resetn = 1'b1;
	
	#(10*CLK_PERIOD + 0.01)
	
	W[0] = 8'sd127;  
	W[1] = 8'sd30;
	W[2] = 8'sd0;
	W[3] = 8'sd17;
	W[4] = -8'sd120;
	W[5] = -8'sd30;
	W[6] = -8'sd12;
	W[7] = 8'sd87;
	W[8] = 8'sd65;
	W[9] = 8'sd13;
	W[10] = 8'sd127;
	W[11] = 8'sd127;
	W[12] = -8'sd127;
	W[13] = -8'sd127;
	W[14] = -8'sd1;
	W[15] = -8'sd1;
	
	X[0] = 8'sd127;  
	X[1] = 8'sd127;
	X[2] = 8'sd127;
	X[3] = 8'sd127;
	X[4] = 8'sd120;
	X[5] = 8'sd1;
	X[6] = 8'sd14;
	X[7] = -8'sd56;
	X[8] = -8'sd43;
	X[9] = 8'sd87;
	X[10] = 8'sd127;
	X[11] = 8'sd127;
	X[12] = -8'sd127;
	X[13] = -8'sd127;
	X[14] = -8'sd1;
	X[15] = -8'sd1;	

	
	end
	
	
	inner_product u_inner_product(
	.clk(clk),
	.resetn(resetn),
	
	.iW1(W[0]),
	.iW2(W[1]),
	.iW3(W[2]),
	.iW4(W[3]),
	.iW5(W[4]),
	.iW6(W[5]),
	.iW7(W[6]),
	.iW8(W[7]),
	.iW9(W[8]),
	.iW10(W[9]),
	.iW11(W[10]),
	.iW12(W[11]),
	.iW13(W[12]),
	.iW14(W[13]),
	.iW15(W[14]),
	.iW16(W[15]),

	.iX1(X[0]),
	.iX2(X[1]),
	.iX3(X[2]),
	.iX4(X[3]),
	.iX5(X[4]),
	.iX6(X[5]),
	.iX7(X[6]),
	.iX8(X[7]),
	.iX9(X[8]),
	.iX10(X[9]),
	.iX11(X[10]),
	.iX12(X[11]),
	.iX13(X[12]),
	.iX14(X[13]),
	.iX15(X[14]),
	.iX16(X[15]),	
	
	.oInnerout(Result)
	);
	
endmodule