// This is a SRAM_(8x14)x256
// Description:
// Author: Michael Kim

module SRAM_16x512
(
input CLK,
input EN_M,
input WE,
input [8:0] ADDR,
input [8:0] ADDR_WRITE,
input [15:0] DIN,

output [15:0] DOUT
);

reg [8:0] ADDR_WRITE_captured;
reg [15:0] DIN_captured;
reg WE_captured;
reg [8:0] ADDR_captured;
reg [15:0] mem [0:511];
    
	
	
    always @(posedge CLK) begin
        ADDR_WRITE_captured <= ADDR_WRITE;
        DIN_captured <= DIN;
        WE_captured <= WE;

        if (WE_captured) begin
            mem[ADDR_WRITE_captured] <= DIN_captured;
        end
        
        if (EN_M) begin
            ADDR_captured <= ADDR;
        end
        
    end
    
    assign DOUT = mem[ADDR_captured];
   
   
endmodule