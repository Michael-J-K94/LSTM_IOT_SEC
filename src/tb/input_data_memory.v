`timescale 1ns/100ps
`define MEM_SIZE 65536

module input_data_memory(
	input [15:0] address,
	output [7:0] data
	);

	reg [7:0] memory [`MEM_SIZE - 1:0];
	
	assign data = memory[address];

	initial begin
		memory[16'h0] <= 8'h80;
		memory[16'h1] <= 8'h80;
		memory[16'h2] <= 8'h80;
		memory[16'h3] <= 8'h80;
		memory[16'h4] <= 8'h80;
		memory[16'h5] <= 8'h80;
		memory[16'h6] <= 8'h80;
		memory[16'h7] <= 8'h80;
		memory[16'h8] <= 8'h95;
		memory[16'h9] <= 8'haa;
		memory[16'ha] <= 8'h82;
		memory[16'hb] <= 8'hca;
		memory[16'hc] <= 8'h6c;
		memory[16'hd] <= 8'h49;
		memory[16'he] <= 8'hae;
		memory[16'hf] <= 8'h90;
		memory[16'h10] <= 8'hcd;
		memory[16'h11] <= 8'h16;
		memory[16'h12] <= 8'h68;
		memory[16'h13] <= 8'hba;
		memory[16'h14] <= 8'hac;
		memory[16'h15] <= 8'h7a;
		memory[16'h16] <= 8'ha6;
		memory[16'h17] <= 8'hf2;
		memory[16'h18] <= 8'hb4;
		memory[16'h19] <= 8'ha8;
		memory[16'h1a] <= 8'hca;
		memory[16'h1b] <= 8'h99;
		memory[16'h1c] <= 8'hb2;
		memory[16'h1d] <= 8'hc2;
		memory[16'h1e] <= 8'h37;
		memory[16'h1f] <= 8'h2a;
		memory[16'h20] <= 8'hcb;
		memory[16'h21] <= 8'h8;
		memory[16'h22] <= 8'hcf;
		memory[16'h23] <= 8'h61;
		memory[16'h24] <= 8'hc9;
		memory[16'h25] <= 8'hc3;
		memory[16'h26] <= 8'h80;
		memory[16'h27] <= 8'h5e;
		memory[16'h28] <= 8'h6e;
		memory[16'h29] <= 8'h3;
		memory[16'h2a] <= 8'h28;
		memory[16'h2b] <= 8'hda;
		memory[16'h2c] <= 8'h4c;
		memory[16'h2d] <= 8'hd7;
		memory[16'h2e] <= 8'h6a;
		memory[16'h2f] <= 8'h19;
		memory[16'h30] <= 8'hed;
		memory[16'h31] <= 8'hd2;
		memory[16'h32] <= 8'hd3;
		memory[16'h33] <= 8'h99;
		memory[16'h34] <= 8'h4c;
		memory[16'h35] <= 8'h79;
		memory[16'h36] <= 8'h8b;
		memory[16'h37] <= 8'h0;
		memory[16'h38] <= 8'h22;
		memory[16'h39] <= 8'h56;
		memory[16'h3a] <= 8'h9a;
		memory[16'h3b] <= 8'hd4;
		memory[16'h3c] <= 8'h18;
		memory[16'h3d] <= 8'hd1;
		memory[16'h3e] <= 8'hfe;
		memory[16'h3f] <= 8'he4;
		memory[16'h40] <= 8'hd9;
		memory[16'h41] <= 8'hcd;
		memory[16'h42] <= 8'h45;
		memory[16'h43] <= 8'ha3;
		memory[16'h44] <= 8'h91;
		memory[16'h45] <= 8'hc6;
		memory[16'h46] <= 8'h1;
		memory[16'h47] <= 8'hff;
		memory[16'h48] <= 8'hc9;
		memory[16'h49] <= 8'h2a;
		memory[16'h4a] <= 8'hd9;
		memory[16'h4b] <= 8'h15;
		memory[16'h4c] <= 8'h1;
		memory[16'h4d] <= 8'h43;
		memory[16'h4e] <= 8'h2f;
		memory[16'h4f] <= 8'hee;
	end
endmodule
