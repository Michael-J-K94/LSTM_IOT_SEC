// This is a SRAM_(8x14)x256
// Description:
// Author: Michael Kim

module LSTM_Sys#(

)
(
	input clk,
	input resetn,

	input [63:0] iXt,
	input [63:0] iCt_pre,
	input [63:0] iHt_pre

	output [63:0] oYt,
	output [63:0] oCt,
	output [63:0] oHt
);





genvar i;

generate
for(i=0; i<32; i=i+1) begin : inner_product_generate
	inner_product u_inner_product(
	 clk,
	 resetn,

	  iW1,
	  iW2,
	  iW3,
	  iW4,
	  iW5,
	  iW6,
	  iW7,
	  iW8,
	  iW9,
	  iW10,
	  iW11,
	  iW12,
	  iW13,
	  iW14,
	  iW15,
	  iW16,

	  iX1,
	  iX2,
	  iX3,
	  iX4,
	  iX5,
	  iX6,
	  iX7,
	  iX8,
	  iX9,
	  iX10,
	  iX11,
	  iX12,
	  iX13,
	iX14,
	iX15,
	iX16,

	oInnerout
	
	
	
	)


end
endgenerate





endmodule

module sram_128b#(

)
(
input clk,
input iR_en,
input iW_en,
input [7:0] iR_addr,
input [7:0] iW_addr,
input [8*14-1:0] iD_in,

output [8*14-1:0] oD_out
);
