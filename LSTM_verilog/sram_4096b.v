// This is a SRAM_(256x14)x256
// Description:
// Author: Michael Kim

module sram_4096b#(
 
)
(
	input clk,

	input iR_en,
	input iW_en,
	input [7:0] iR_addr,
	input [7:0] iW_addr,
	input [4096-1:0] iD_in,

	output [4096-1:0] oD_out 
);

	genvar i;

	wire [128-1:0] d_in [31:0];
	wire [128-1:0] d_out [31:0];

	wire [4096-1:0] d_out_tmp; 

generate
for(i=0; i<32; i=i+1) begin : wiring
	assign din[i] = iD_in[ (32-i)*128-1 : (32-i-1)*128 ];
	assign dout_temp[ (32-i)*128-1 : (32-i-1)*128] = dout[i];
end
endgenerate

generate 
for (i=0; i<32; i=i+1) begin : bank_generation
	sram_128b bank(
	.clk(clk),
	.iR_en(iR_en),
	.iW_en(iW_en),
	iR_addr(iR_addr),
	iW_addr(iW_addr),
	iD_in(din[i]),
	oD_out(dout[i])
	)
end
endgenerate

assign oD_out = dout_temp;

endmodule