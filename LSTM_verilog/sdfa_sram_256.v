// This is a SRAM_(256x14)x256
// Description:
// Author: Michael Kim

module sdfa_sram_256#(

parameter integer DATA_IN_MAX_SIZE = 8,
parameter integer DATA_KEEP_SIZE = 3,

parameter integer W_SIZE_BIT = 14,

parameter integer CAL_BIT = 10,


parameter integer NUMBER_OF_NEURONS = 256,
parameter integer NEURON_SIZE_BIT = 8 
 
)
(
input CLK,

input EN_M,
input [31:0] WE,	// SRAM DIVIDED INTO 32 BLOCKS
input [NEURON_SIZE_BIT-1:0] ADDR,
input [NEURON_SIZE_BIT-1:0] ADDR_WRITE,
input [256*14-1:0] DIN,						
output [256*14-1:0] DOUT				// ????????????????????????????????????????? ENDIAN CORRECT ??? *****************************************
);

genvar i;

wire we [31:0];
wire [8*14-1:0] din [31:0];
wire [8*14-1:0] dout [31:0];

wire [256*14-1:0] dout_temp;

//////////////////////////////////////////
// "we", "din", "dout_temp" GENERATION  // 
//////////////////////////////////////////
generate
for(i=0; i<32; i=i+1) begin	: assign_wire
	assign we[i] = WE[i];
	assign din[i] = DIN[(32-i)*8*14-1:(32-i-1)*8*14];
	assign dout_temp[(32-i)*8*14-1:(32-i-1)*8*14] = dout[i];
end
endgenerate


/////////////////////////////////
// SRAM (8x14)x256 GENERATION  // 
/////////////////////////////////
generate
for(i=0; i<32; i=i+1) begin	: gen_sram_8
	sdfa_sram_8 bank(
	.CLK(CLK),
	.EN_M(EN_M),     
	.WE(we[i]),      
	.ADDR(ADDR),  
	.DIN(din[i]),    
	.DOUT(dout[i]),  	
	.ADDR_WRITE(ADDR_WRITE)
	);
end
endgenerate

assign DOUT = dout_temp;
	
	
endmodule
