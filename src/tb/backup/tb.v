`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/04 16:05:11
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define DELAY 100

module tb();
    reg signed [31:0] i;
    reg signed [31:0] t;
    initial begin
        t = -10;
        for(i = 0; i < 20; i = i+1) begin
            #`DELAY
            $display("%d/5 = %d",t+i, (t+i)/5);
        end
    end
endmodule
