// This is a SRAM_(8x14)x256
// Description:
// Author: Michael Kim

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

	reg [7:0] w_addr_capt;
	reg [7:0] r_addr_capt;
	reg [128-1:0] d_in_capt;
	reg w_en_capt;
	reg [128-1:0] mem [255:0];

always@(posedge clk) begin
	w_addr_capt <= iW_addr;
	d_in_capt <= iD_in;
	w_en_capt <= iW_en;
	
	if(!w_en_capt) begin
		mem[w_addr_capt] <= d_in_capt;
	end
	
	if(!iR_addr) begin
		r_addr_capt <= iR_addr;
	end
	
end

assign oD_out = mem[r_addr_capt];
   
endmodule
