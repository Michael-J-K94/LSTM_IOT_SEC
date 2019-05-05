`timescale 1ns/100ps
`define MEM_SIZE 65536

module output_memory(
	input [15:0] address,
	output [7:0] data
	);

	reg [7:0] memory [`MEM_SIZE - 1:0];
	
	assign data = memory[address];
	
	initial begin
		memory[16'h0] <= 8'h95;
		memory[16'h1] <= 8'h95;
		memory[16'h2] <= 8'h95;
		memory[16'h3] <= 8'h95;
		memory[16'h4] <= 8'h95;
		memory[16'h5] <= 8'h95;
		memory[16'h6] <= 8'h95;
		memory[16'h7] <= 8'h95;
		memory[16'h8] <= 8'haa;
		memory[16'h9] <= 8'h6d;
		memory[16'ha] <= 8'h8e;
		memory[16'hb] <= 8'ha5;
		memory[16'hc] <= 8'h86;
		memory[16'hd] <= 8'hb6;
		memory[16'he] <= 8'hb1;
		memory[16'hf] <= 8'h7d;
		memory[16'h10] <= 8'h9d;
		memory[16'h11] <= 8'h9a;
		memory[16'h12] <= 8'h89;
		memory[16'h13] <= 8'ha6;
		memory[16'h14] <= 8'h88;
		memory[16'h15] <= 8'hd5;
		memory[16'h16] <= 8'hcd;
		memory[16'h17] <= 8'h7e;
		memory[16'h18] <= 8'hc1;
		memory[16'h19] <= 8'h9c;
		memory[16'h1a] <= 8'h5d;
		memory[16'h1b] <= 8'h9b;
		memory[16'h1c] <= 8'hb6;
		memory[16'h1d] <= 8'hc0;
		memory[16'h1e] <= 8'hbd;
		memory[16'h1f] <= 8'ha2;
		memory[16'h20] <= 8'h89;
		memory[16'h21] <= 8'hbd;
		memory[16'h22] <= 8'h5b;
		memory[16'h23] <= 8'had;
		memory[16'h24] <= 8'hc6;
		memory[16'h25] <= 8'hce;
		memory[16'h26] <= 8'hb7;
		memory[16'h27] <= 8'hab;
		memory[16'h28] <= 8'hb6;
		memory[16'h29] <= 8'hb2;
		memory[16'h2a] <= 8'h73;
		memory[16'h2b] <= 8'hb4;
		memory[16'h2c] <= 8'hbb;
		memory[16'h2d] <= 8'hc8;
		memory[16'h2e] <= 8'hcd;
		memory[16'h2f] <= 8'ha9;
		memory[16'h30] <= 8'hce;
		memory[16'h31] <= 8'h4f;
		memory[16'h32] <= 8'h5e;
		memory[16'h33] <= 8'ha5;
		memory[16'h34] <= 8'hae;
		memory[16'h35] <= 8'hba;
		memory[16'h36] <= 8'hbf;
		memory[16'h37] <= 8'h9b;
		memory[16'h38] <= 8'h97;
		memory[16'h39] <= 8'h3b;
		memory[16'h3a] <= 8'h99;
		memory[16'h3b] <= 8'hb4;
		memory[16'h3c] <= 8'h98;
		memory[16'h3d] <= 8'hbf;
		memory[16'h3e] <= 8'hde;
		memory[16'h3f] <= 8'hb8;
		memory[16'h40] <= 8'hb9;
		memory[16'h41] <= 8'hb9;
		memory[16'h42] <= 8'ha4;
		memory[16'h43] <= 8'h99;
		memory[16'h44] <= 8'ha5;
		memory[16'h45] <= 8'ha7;
		memory[16'h46] <= 8'hdc;
		memory[16'h47] <= 8'hc0;
		memory[16'h48] <= 8'h79;
		memory[16'h49] <= 8'ha5;
		memory[16'h4a] <= 8'hc5;
		memory[16'h4b] <= 8'h84;
		memory[16'h4c] <= 8'haf;
		memory[16'h4d] <= 8'h9b;
		memory[16'h4e] <= 8'hc1;
		memory[16'h4f] <= 8'h97;
	end
endmodule
