`timescale 1ns/1ps

module softmax_tb();
    parameter CLK_CYCLE = 2.5;
    parameter CLK_PERIOD = 2*CLK_CYCLE;
	
	parameter SYS_type = 1'b1, BR_type = 1'b0; 	
	
	reg clk;
	reg [31:0] clk_counter;
	reg resetn;
	
	reg lstm_valid;
	reg lstm_type;
	reg [63:0] sys_ht;
	reg [511:0] br_ht;
	
	reg fifo_valid;
	reg [12:0] fifo_data;
	reg interrupt;

	integer i;


	// ADDR data_set //
	reg [12:0] fifo_data_set [0:9];
	reg [63:0] sys_ht_set [0:9];
	reg [511:0] br_ht_set [0:9];

	initial begin
		fifo_data_set[0] = 13'b0_1010_0010_1111;
		fifo_data_set[1] = 13'b0_0001_0001_1010;
		fifo_data_set[2] = 13'b0_1101_1100_0000;
		fifo_data_set[3] = 13'b0_0010_1110_1001;
		fifo_data_set[4] = 13'b0_1001_1100_0011;
		fifo_data_set[5] = 13'b0_1000_0100_1100;	

		fifo_data_set[6] = 13'b1_0001_0000_1100;
		fifo_data_set[7] = 13'b1_0000_1001_1010;
		fifo_data_set[8] = 13'b1_0001_0001_1010;
		fifo_data_set[9] = 13'b1_0000_0010_1001;		
		
		for(i=0; i<16; i=i+1) begin
			sys_ht_set[0][64-8*(i+1)+:8] = 8'h80;
		end
		for(i=0; i<64; i=i+1) begin
			br_ht_set[0][512-8*(i+1)+:8] = 8'h80;
		end		
		sys_ht_set[1] = 64'h20ac_fd8e_104c_8b9a;
		sys_ht_set[2] = 64'hd8b0_a0c8_1407_d6af;
	
	
	end



	///////////////////////
	////**** START ****////
	///////////////////////	
    initial begin
        clk = 1'b1;
        rstn = 'd0;
		clk_counter = 'd0;
    end	
    always begin 
		#CLK_CYCLE clk = ~clk;	
		if(clk) clk_counter <= clk_counter + 1;
	end
	
	////**** START ****////	
	initial begin
		lstm_valid = 1'b0;
		lstm_type = SYS_type;
		for(i=0; i<8; i=i+1) begin
			sys_ht[64-8*(i+1)+:8] = 8'h80;
		end
		for(i=0; i<64; i=i+1) begin
			br_ht[512-8*(i+1)+:8] = 8'h80;
		end
		fifo_valid = 1'b0;
		fifo_data = 'd0;
		interrupt = 'd0;
		
		#(5*CLK_PERIOD)
		resetn = 1'b1;
		#(5*CLK_PERIOD + 0.01)

	///////////////////////
		// lstm sys done.
		lstm_valid = 1'b1;
		lstm_type = SYS_type;
		sys_ht = sys_ht_set[1];
		#(CLK_PERIOD)
		lstm_valid = 1'b0;

	///////////////////////
		#(CLK_PERIOD)
		fifo_valid = 1'b1;
		fifo_data = fifo_data_set[0];
		#(CLK_PERIOD)
		fifo_valid = 1'b0;

	///////////////////////
		#(128*CLK_PERIOD)
		lstm_valid = 1'b1;
		lstm_type = BR_type;
		br_ht = 
		
		
		#(100*CLK_PERIOD)		
		fifo_valid = 1'b1;
		ffo_data = fifo_data_set[1];
		#(CLK_PERIOD)
		fifo_valid = 1'b0;
		
		
	
	
	
	
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	softmax u_softmax(
	.clk(clk),
	.resetn(resetn),
	
	.iLstm_valid(lstm_valid),		
	.iLstm_type(lstm_type),
	.iSys_Ht(sys_ht),
	.iBr_Ht(br_ht),

	.iFIFO_valid(fifo_valid),
	.iFIFO_data(fifo_data),

	.oAbnormal(interrupt)
	);