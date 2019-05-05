`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/04 20:06:32
// Design Name: 
// Module Name: top_lstm
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


module top_lstm(
    input clk,
    input rstn,
    input lstm_enable,
    input lstm_init,
    input [2:0] param_type,
    input [7:0] lstm_param,
    input [63:0] syscall_X_data,
    
    output reg lstm_done,
    output [63:0] syscall_H_out
    );
    reg [63:0] counter;
    reg [63:0] test;
    assign syscall_H_out = test;
    /* test_logic*/
    always @(posedge clk) begin
        if(!rstn) begin
            lstm_done <= 1;
            counter <= 0;
            test <= 10;
        end
    end
    
    always @(posedge clk) begin
        if(lstm_enable || counter != 0) begin
               counter <= counter + 1;
               if(counter[2:0] == 7) begin
                    lstm_done <= 1;
                    counter <= 0;
                    test <= test + 1;
               end
               else begin
                    lstm_done <= 0;
               end
        end
    end
    
endmodule
