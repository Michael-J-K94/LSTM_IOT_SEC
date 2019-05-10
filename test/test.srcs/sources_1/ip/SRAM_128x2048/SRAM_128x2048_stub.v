// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Fri May 10 23:34:19 2019
// Host        : DESKTOP-6F07SNM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/User/Desktop/LSTM_IOT_SEC/test/test.srcs/sources_1/ip/SRAM_128x2048/SRAM_128x2048_stub.v
// Design      : SRAM_128x2048
// Purpose     : Stub declaration of top-level module interface
// Device      : xa7a12tcpg238-2I
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module SRAM_128x2048(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[10:0],dina[127:0],douta[127:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [10:0]addra;
  input [127:0]dina;
  output [127:0]douta;
endmodule