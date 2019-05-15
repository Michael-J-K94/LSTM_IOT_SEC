// This is a SRAM_(8x14)x256
// Description:
// Author: Michael Kim

module softmax#(		
	
	parameter SCALE_DATA = 10'd128,		
	parameter SCALE_STATE =  10'd128,	
	parameter SCALE_W = 10'd128,
	parameter SCALE_B = 10'd256,

	parameter ZERO_DATA = 8'd128,
	parameter ZERO_STATE = 8'd128,
	parameter ZERO_W = 8'd128,			
	parameter ZERO_B = 8'd0,
	
	parameter SCALE_SIGMOID = 10'd24,
	parameter SCALE_TANH = 10'd48,

	parameter ZERO_SIGMOID = 8'd128,
	parameter ZERO_TANH = 8'd128,

	parameter OUT_SCALE_SIGMOID = 10'd256,
	parameter OUT_SCALE_TANH = 10'd128,

	parameter OUT_ZERO_SIGMOID = 8'd0,
	parameter OUT_ZERO_TANH = 8'd128	
	

)
(
	input clk,
	input resetn,
	
	input iLstm_valid,		
	input iLstm_type,
	input [63:0] iSys_Ht,
	input [511:0] iBr_Ht,

	input iFIFO_valid,
	input [12:0] iFIFO_data,

	output reg oAbnormal
);

	localparam THRESHOLD = 24'b0000_0000_0000_1111_1111_1111;
	localparam IDLE = 2'd0, RUN = 2'd1;
	localparam SYS_type = 1'b1, BR_type = 1'b0; 

	integer i;

	reg [1:0] softmax_state;
	reg [6:0] counter;

	reg [7:0] Sys_Ht_captured [0:7];
	reg [7:0] Br_Ht_captured [0:63];
	reg sys_new;
	reg br_new;
	
	reg [12:0] Fifo_captured;
	reg [23:0] cal_temp_reg;

///////////
// Brams //
///////////
	reg br_weight_bram_EN;
	reg br_weight_bram_WE;
	reg [11:0] br_weight_bram_addr;
	reg [511:0] br_weight_bram_Wdata;
	wire [511:0] br_weight_bram_Rdata;

	reg br_bias_bram_EN;
	reg br_bias_bram_WE;
	reg [11:0] br_bias_bram_addr;
	reg [7:0] br_bias_bram_Wdata;
	reg [7:0] br_bias_bram_Rdata;

	reg sys_weight_bram_EN;
	reg sys_weight_bram_WE;
	reg [8:0] sys_weight_bram_addr;
	reg [63:0] sys_weight_bram_Wdata;
	reg [63:0] sys_weight_bram_Rdata;	

	reg sys_bias_bram_EN;
	reg sys_bias_bram_WE;
	reg [8:0] sys_bias_bram_addr;
	reg [7:0] sys_bias_bram_Wdata;
	reg [7:0] sys_bias_bram_Rdata;


/*
	SRAM_128x2048 WEIGHT_BRAM1(
		.addra(br_weight_bram_addr),
		.clka(clk),
		.dina(br_weight_bram_Wdata),
		.douta(br_weight_bram_Rdata),
		.ena(br_weight_bram_EN),
		.wea(br_weight_bram_WE)	
	);
	
	SRAM_32x512 BIAS_BRAM(
		.addra(br_bias_bram_addr),
		.clka(clk),
		.dina(br_bias_bram_Wdata),
		.douta(br_bias_bram_Rdata),
		.ena(br_bias_bram_EN),
		.wea(br_bias_bram_WE)	
	);	
	
*/

	SRAM_512x4096 BR_WEIGHT_BRAM(
		.addra(br_weight_bram_addr),
		.clka(clk),
		.dina(br_weight_bram_Wdata),
		.douta(br_weight_bram_Rdata),
		.ena(br_weight_bram_EN),
		.wea(br_weight_bram_WE)	
	);

	SRAM_8x4096 BR_BIAS_BRAM(
		.addra(br_bias_bram_addr),
		.clka(clk),
		.dina(br_bias_bram_Wdata),
		.douta(br_bias_bram_Rdata),
		.ena(br_bias_bram_EN),
		.wea(br_bias_bram_WE)	
	);

	SRAM_64x283 SYS_WEIGHT_BRAM(
		.addra(sys_weight_bram_addr),
		.clka(clk),
		.dina(sys_weight_bram_Wdata),
		.douta(sys_weight_bram_Rdata),
		.ena(sys_weight_bram_EN),
		.wea(sys_weight_bram_WE)	
	);
	
	SRAM_8x283 SYS_BIAS_BRAM(
		.addra(sys_bias_bram_addr),
		.clka(clk),
		.dina(sys_bias_bram_Wdata),
		.douta(sys_bias_bram_Rdata),
		.ena(sys_bias_bram_EN),
		.wea(sys_bias_bram_WE)	
	);	



	// SRAM_512x4096 BR_WEIGHT_BRAM(
		// .CLK(clk),
		// .EN_M(br_weight_bram_EN),
		// .WE(br_weight_bram_WE),
		// .ADDR(br_weight_bram_addr),
		// .ADDR_WRITE(br_weight_bram_addr),
		// .DIN(br_weight_bram_Wdata),
		// .DOUT(br_weight_bram_Rdata)	
	// );
	
	// SRAM_8x4096 BR_BIAS_BRAM(
		// .CLK(clk),
		// .EN_M(br_bias_bram_EN),
		// .WE(br_bias_bram_WE),
		// .ADDR(br_bias_bram_addr),
		// .ADDR_WRITE(br_bias_bram_addr),		
		// .DIN(br_bias_bram_Wdata),
		// .DOUT(br_bias_bram_Rdata)	
	// );	
	
	// SRAM_64x243 SYS_WEIGHT_BRAM(
		// .CLK(clk),
		// .EN_M(sys_weight_bram_EN),
		// .WE(sys_weight_bram_WE),
		// .ADDR(sys_weight_bram_addr),
		// .ADDR_WRITE(sys_weight_bram_addr),
		// .DIN(sys_weight_bram_Wdata),
		// .DOUT(sys_weight_bram_Rdata)	
	// );
	
	// SRAM_8x243 SYS_BIAS_BRAM(
		// .CLK(clk),
		// .EN_M(sys_bias_bram_EN),
		// .WE(sys_bias_bram_WE),
		// .ADDR(sys_bias_bram_addr),
		// .ADDR_WRITE(sys_bias_bram_addr),		
		// .DIN(sys_bias_bram_Wdata),
		// .DOUT(sys_bias_bram_Rdata)	
	// );		
	
	
// *****************************************************************************//
// *****************************************************************************//	
//									FSM / CTRL									//
// *****************************************************************************//	
// *****************************************************************************//

////////////////
// Capture Ht //
////////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			for(i=0; i<8; i=i+1) begin
				Sys_Ht_captured[i] <= 'd0;
			end
			for(i=0; i<64; i=i+1) begin
				Br_Ht_captured[i] <= 'd0;
			end
			
		end
		else begin
			if(iLstm_valid) begin
				if(iLstm_type == SYS_type) begin
					for(i=0; i<8; i=i+1) begin
						Sys_Ht_captured[i] <= iSys_Ht[64-8*(i+1)+:8];
					end
				end
				else begin
					for(i=0; i<64; i=i+1) begin
						Br_Ht_captured[i] <= iBr_Ht[512-8*(i+1)+:8];
					end
				end
			end
		end	
	end


/////////
// FSM //
/////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin
			softmax_state <= IDLE;
			Fifo_captured <= 'd0;
			counter <= 'd0;
			
			sys_new <= 1'b1;
			br_new <= 1'b1;
		end
		else begin
			case(softmax_state) 
			
				IDLE: begin
					if(iFIFO_valid) begin			
					
						if(iFIFO_data[12] == SYS_type) begin		// FIFO SYS

							sys_new <= 1'b0;
							br_new <= 1'b1;		// BR becomes new when SYS comes in. 				
							
							if(sys_new == 1) begin
								softmax_state <= IDLE;
								Fifo_captured <= Fifo_captured;
							end
							else begin							
								softmax_state <= RUN;
								Fifo_captured <= iFIFO_data;
							end				
							
						end
						
						else begin									// FIFO BR

							br_new <= 1'b0;

							if(br_new == 1) begin
								softmax_state <= IDLE;
								Fifo_captured <= Fifo_captured;
							end
							else begin								
								softmax_state <= RUN;
								Fifo_captured <= iFIFO_data;
							end
						
						end
						
					end				
				end
				
				RUN: begin
				
					if(Fifo_captured[12] == SYS_type) begin
						if(counter == 12) begin
							softmax_state <= IDLE;
							
							counter <= 'd0;
						end
						else begin
							counter <= counter + 1;
						end
					end
					else if(Fifo_captured[12] == BR_type) begin
						if(counter == 68) begin
							softmax_state <= IDLE;
							
							counter <= 'd0;
						end
						else begin
							counter <= counter + 1;						
						end					
					end
				end			
				
				default: begin
				
				
				end
				
			endcase		
		end
	end

/////////////////////
// Clock base CTRL //
/////////////////////
	always@(posedge clk or negedge resetn) begin
		if(!resetn) begin

			br_weight_bram_EN <= 'd0;
			br_weight_bram_WE <= 'd0;
			br_weight_bram_addr <= 'd0;
			br_weight_bram_Wdata <= 'd0;

			br_bias_bram_EN <= 'd0;
			br_bias_bram_WE <= 'd0;
			br_bias_bram_addr <= 'd0;
			br_bias_bram_Wdata <= 'd0;

			sys_weight_bram_EN <= 'd0;
			sys_weight_bram_WE <= 'd0;
			sys_weight_bram_addr <= 'd0;
			sys_weight_bram_Wdata <= 'd0;

			sys_bias_bram_EN <= 'd0;
			sys_bias_bram_WE <= 'd0;
			sys_bias_bram_addr <= 'd0;
			sys_bias_bram_Wdata <= 'd0;
			
			cal_temp_reg <= 'd0;
			oAbnormal <= 'd0;
		end
		else begin
		
			if(softmax_state == RUN) begin
				
				//**** SYS_type ****//
				if(Fifo_captured[12] == SYS_type) begin

					if(counter == 0) begin
						sys_weight_bram_EN <= 1'b1;
						sys_weight_bram_addr <= Fifo_captured[8:0];
						
						sys_bias_bram_EN <= 1'b1;
						sys_bias_bram_addr <= Fifo_captured[8:0];						
					end
					else if( (2<=counter) && (counter<=9) ) begin
						cal_temp_reg <= $signed(cal_temp_reg) + 128*( $signed({1'b0, Sys_Ht_captured[counter-2]}) - $signed({1'b0,ZERO_DATA}) )		// ?????????????????????? QUANTIZATION ??????
						*( $signed({1'b0, sys_weight_bram_Rdata[64-8*(counter-1)+:8]}) - $signed({1'b0, ZERO_W}) )/($signed(SCALE_DATA)*$signed(SCALE_W));
					end
					else if(counter == 10) begin
						cal_temp_reg <= $signed(cal_temp_reg) + 128*( $signed({1'b0,sys_bias_bram_Rdata}) - $signed({1'b0,ZERO_B}) )/($signed(SCALE_B));
					end
					else if(counter == 11) begin
						if(cal_temp_reg <= THRESHOLD) begin
							oAbnormal <= 1'b1;
						end
						else begin
							oAbnormal <= 1'b0;
						end
					end
					else if(counter == 12) begin
						cal_temp_reg <= 'd0;
						oAbnormal <= 1'b0;
						
						sys_weight_bram_EN <= 1'b0;						
						sys_bias_bram_EN <= 1'b0;
					end
				end				
				
				//**** BR_type ****//
				else if(Fifo_captured[12] == BR_type) begin

					if(counter == 0) begin
						br_weight_bram_EN <= 1'b1;
						br_weight_bram_addr <= Fifo_captured[11:0];
						
						br_bias_bram_EN <= 1'b1;
						br_bias_bram_addr <= Fifo_captured[11:0];
					end
					else if( (2<=counter) && (counter<=65) ) begin
						cal_temp_reg <= $signed(cal_temp_reg) + 128*( $signed({1'b0, Br_Ht_captured[counter-2]}) - $signed({1'b0,ZERO_DATA}) )		// ?????????????????????? QUANTIZATION ??????
						*( $signed({1'b0, br_weight_bram_Rdata[64-8*(counter-1)+:8]}) - $signed({1'b0, ZERO_W}) )/($signed(SCALE_DATA)*$signed(SCALE_W));
					end
					else if(counter == 66) begin
						cal_temp_reg <= $signed(cal_temp_reg) + 128*( $signed({1'b0,br_bias_bram_Rdata}) - $signed({1'b0,ZERO_B}) )/($signed(SCALE_DATA)*$signed(SCALE_W));
					end
					else if(counter == 67) begin
						if(cal_temp_reg <= THRESHOLD) begin				// ?????????????????????????????????? THRESHOLD Sys Branch different????
							oAbnormal <= 1'b1;
						end
						else begin
							oAbnormal <= 1'b0;
						end
					end	
					else if(counter == 68) begin
						cal_temp_reg <= 'd0;
						oAbnormal <= 1'b0;
						
						br_weight_bram_EN <= 1'b0;
						br_bias_bram_EN <= 1'b0;
					end				
				end
			end
			else begin
				sys_weight_bram_EN <= 1'b0;
				sys_bias_bram_EN <= 1'b0;
				br_weight_bram_EN <= 1'b0;
				br_bias_bram_EN <= 1'b0;
				
				cal_temp_reg <= 'd0;				
				oAbnormal <= 1'b0;
			end
		end
	end




endmodule
