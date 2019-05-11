`timescale 1ns/100ps
`define INIT_DELAY 10
`define INTERVAL 1
`define MEM_SIZE 65536

module context_memory(
	input readM,
	output reg ready,
	output reg [7:0] data
	);

	reg [7:0] memory [`MEM_SIZE - 1:0];
	reg [15:0] address;

	always begin
		#`INIT_DELAY
		forever begin
			wait(readM == 1);
			#`INTERVAL;
			data = memory[address];
			address = address + 1;
			ready = 1;
			wait(readM == 0);
			#`INTERVAL;
			ready = 0;
		end
	end

	initial begin
		address <= 0;
		ready <= 0;
	end

	initial begin
		memory[16'h0] <= 8'h80;
		memory[16'h1] <= 8'h80;
		memory[16'h2] <= 8'h80;
		memory[16'h3] <= 8'h80;
		memory[16'h4] <= 8'h80;
		memory[16'h5] <= 8'h80;
		memory[16'h6] <= 8'h80;
		memory[16'h7] <= 8'h80;
		memory[16'h8] <= 8'h80;
		memory[16'h9] <= 8'h80;
		memory[16'ha] <= 8'h80;
		memory[16'hb] <= 8'h80;
		memory[16'hc] <= 8'h80;
		memory[16'hd] <= 8'h80;
		memory[16'he] <= 8'h80;
		memory[16'hf] <= 8'h80;
	end
endmodule
