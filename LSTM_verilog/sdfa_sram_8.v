// This is a SRAM_(8x14)x256
// Description:
// Author: Michael Kim

module sdfa_sram_8#(

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
input WE,
input [7:0] ADDR,
input [7:0] ADDR_WRITE,
input [8*14-1:0] DIN,

output [8*14-1:0] DOUT
);

reg [7:0] ADDR_WRITE_captured;
reg [8*14-1:0] DIN_captured;
reg WE_captured;
reg [7:0] ADDR_captured;
reg [8*14-1:0] mem [0:255];
    
	
	
    always @(posedge CLK) begin
        ADDR_WRITE_captured <= ADDR_WRITE;
        DIN_captured <= DIN;
        WE_captured <= WE;

        if (!WE_captured) begin
            mem[ADDR_WRITE_captured] <= DIN_captured;
        end
        
        if (!EN_M) begin
            ADDR_captured <= ADDR;
        end
        
    end
    
    assign DOUT = mem[ADDR_captured];
   
   
endmodule
