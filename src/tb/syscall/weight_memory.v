`timescale 1ns/100ps
`define INIT_DELAY 10
`define INTERVAL 1
`define MEM_SIZE 65536

module weight_memory(
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
		memory[16'h0] <= 8'h67;
		memory[16'h1] <= 8'hc6;
		memory[16'h2] <= 8'h69;
		memory[16'h3] <= 8'h73;
		memory[16'h4] <= 8'h51;
		memory[16'h5] <= 8'hff;
		memory[16'h6] <= 8'h4a;
		memory[16'h7] <= 8'hec;
		memory[16'h8] <= 8'h29;
		memory[16'h9] <= 8'hcd;
		memory[16'ha] <= 8'hba;
		memory[16'hb] <= 8'hab;
		memory[16'hc] <= 8'hf2;
		memory[16'hd] <= 8'hfb;
		memory[16'he] <= 8'he3;
		memory[16'hf] <= 8'h46;
		memory[16'h10] <= 8'h7c;
		memory[16'h11] <= 8'hc2;
		memory[16'h12] <= 8'h54;
		memory[16'h13] <= 8'hf8;
		memory[16'h14] <= 8'h1b;
		memory[16'h15] <= 8'he8;
		memory[16'h16] <= 8'he7;
		memory[16'h17] <= 8'h8d;
		memory[16'h18] <= 8'h76;
		memory[16'h19] <= 8'h5a;
		memory[16'h1a] <= 8'h2e;
		memory[16'h1b] <= 8'h63;
		memory[16'h1c] <= 8'h33;
		memory[16'h1d] <= 8'h9f;
		memory[16'h1e] <= 8'hc9;
		memory[16'h1f] <= 8'h9a;
		memory[16'h20] <= 8'h66;
		memory[16'h21] <= 8'h32;
		memory[16'h22] <= 8'hd;
		memory[16'h23] <= 8'hb7;
		memory[16'h24] <= 8'h31;
		memory[16'h25] <= 8'h58;
		memory[16'h26] <= 8'ha3;
		memory[16'h27] <= 8'h5a;
		memory[16'h28] <= 8'h25;
		memory[16'h29] <= 8'h5d;
		memory[16'h2a] <= 8'h5;
		memory[16'h2b] <= 8'h17;
		memory[16'h2c] <= 8'h58;
		memory[16'h2d] <= 8'he9;
		memory[16'h2e] <= 8'h5e;
		memory[16'h2f] <= 8'hd4;
		memory[16'h30] <= 8'hab;
		memory[16'h31] <= 8'hb2;
		memory[16'h32] <= 8'hcd;
		memory[16'h33] <= 8'hc6;
		memory[16'h34] <= 8'h9b;
		memory[16'h35] <= 8'hb4;
		memory[16'h36] <= 8'h54;
		memory[16'h37] <= 8'h11;
		memory[16'h38] <= 8'he;
		memory[16'h39] <= 8'h82;
		memory[16'h3a] <= 8'h74;
		memory[16'h3b] <= 8'h41;
		memory[16'h3c] <= 8'h21;
		memory[16'h3d] <= 8'h3d;
		memory[16'h3e] <= 8'hdc;
		memory[16'h3f] <= 8'h87;
		memory[16'h40] <= 8'h70;
		memory[16'h41] <= 8'he9;
		memory[16'h42] <= 8'h3e;
		memory[16'h43] <= 8'ha1;
		memory[16'h44] <= 8'h41;
		memory[16'h45] <= 8'he1;
		memory[16'h46] <= 8'hfc;
		memory[16'h47] <= 8'h67;
		memory[16'h48] <= 8'h3e;
		memory[16'h49] <= 8'h1;
		memory[16'h4a] <= 8'h7e;
		memory[16'h4b] <= 8'h97;
		memory[16'h4c] <= 8'hea;
		memory[16'h4d] <= 8'hdc;
		memory[16'h4e] <= 8'h6b;
		memory[16'h4f] <= 8'h96;
		memory[16'h50] <= 8'h8f;
		memory[16'h51] <= 8'h38;
		memory[16'h52] <= 8'h5c;
		memory[16'h53] <= 8'h2a;
		memory[16'h54] <= 8'hec;
		memory[16'h55] <= 8'hb0;
		memory[16'h56] <= 8'h3b;
		memory[16'h57] <= 8'hfb;
		memory[16'h58] <= 8'h32;
		memory[16'h59] <= 8'haf;
		memory[16'h5a] <= 8'h3c;
		memory[16'h5b] <= 8'h54;
		memory[16'h5c] <= 8'hec;
		memory[16'h5d] <= 8'h18;
		memory[16'h5e] <= 8'hdb;
		memory[16'h5f] <= 8'h5c;
		memory[16'h60] <= 8'h2;
		memory[16'h61] <= 8'h1a;
		memory[16'h62] <= 8'hfe;
		memory[16'h63] <= 8'h43;
		memory[16'h64] <= 8'hfb;
		memory[16'h65] <= 8'hfa;
		memory[16'h66] <= 8'haa;
		memory[16'h67] <= 8'h3a;
		memory[16'h68] <= 8'hfb;
		memory[16'h69] <= 8'h29;
		memory[16'h6a] <= 8'hd1;
		memory[16'h6b] <= 8'he6;
		memory[16'h6c] <= 8'h5;
		memory[16'h6d] <= 8'h3c;
		memory[16'h6e] <= 8'h7c;
		memory[16'h6f] <= 8'h94;
		memory[16'h70] <= 8'h75;
		memory[16'h71] <= 8'hd8;
		memory[16'h72] <= 8'hbe;
		memory[16'h73] <= 8'h61;
		memory[16'h74] <= 8'h89;
		memory[16'h75] <= 8'hf9;
		memory[16'h76] <= 8'h5c;
		memory[16'h77] <= 8'hbb;
		memory[16'h78] <= 8'ha8;
		memory[16'h79] <= 8'h99;
		memory[16'h7a] <= 8'hf;
		memory[16'h7b] <= 8'h95;
		memory[16'h7c] <= 8'hb1;
		memory[16'h7d] <= 8'heb;
		memory[16'h7e] <= 8'hf1;
		memory[16'h7f] <= 8'hb3;
		memory[16'h80] <= 8'h5;
		memory[16'h81] <= 8'hef;
		memory[16'h82] <= 8'hf7;
		memory[16'h83] <= 8'h0;
		memory[16'h84] <= 8'he9;
		memory[16'h85] <= 8'ha1;
		memory[16'h86] <= 8'h3a;
		memory[16'h87] <= 8'he5;
		memory[16'h88] <= 8'hca;
		memory[16'h89] <= 8'hb;
		memory[16'h8a] <= 8'hcb;
		memory[16'h8b] <= 8'hd0;
		memory[16'h8c] <= 8'h48;
		memory[16'h8d] <= 8'h47;
		memory[16'h8e] <= 8'h64;
		memory[16'h8f] <= 8'hbd;
		memory[16'h90] <= 8'h1f;
		memory[16'h91] <= 8'h23;
		memory[16'h92] <= 8'h1e;
		memory[16'h93] <= 8'ha8;
		memory[16'h94] <= 8'h1c;
		memory[16'h95] <= 8'h7b;
		memory[16'h96] <= 8'h64;
		memory[16'h97] <= 8'hc5;
		memory[16'h98] <= 8'h14;
		memory[16'h99] <= 8'h73;
		memory[16'h9a] <= 8'h5a;
		memory[16'h9b] <= 8'hc5;
		memory[16'h9c] <= 8'h5e;
		memory[16'h9d] <= 8'h4b;
		memory[16'h9e] <= 8'h79;
		memory[16'h9f] <= 8'h63;
		memory[16'ha0] <= 8'h3b;
		memory[16'ha1] <= 8'h70;
		memory[16'ha2] <= 8'h64;
		memory[16'ha3] <= 8'h24;
		memory[16'ha4] <= 8'h11;
		memory[16'ha5] <= 8'h9e;
		memory[16'ha6] <= 8'h9;
		memory[16'ha7] <= 8'hdc;
		memory[16'ha8] <= 8'haa;
		memory[16'ha9] <= 8'hd4;
		memory[16'haa] <= 8'hac;
		memory[16'hab] <= 8'hf2;
		memory[16'hac] <= 8'h1b;
		memory[16'had] <= 8'h10;
		memory[16'hae] <= 8'haf;
		memory[16'haf] <= 8'h3b;
		memory[16'hb0] <= 8'h33;
		memory[16'hb1] <= 8'hcd;
		memory[16'hb2] <= 8'he3;
		memory[16'hb3] <= 8'h50;
		memory[16'hb4] <= 8'h48;
		memory[16'hb5] <= 8'h47;
		memory[16'hb6] <= 8'h15;
		memory[16'hb7] <= 8'h5c;
		memory[16'hb8] <= 8'hbb;
		memory[16'hb9] <= 8'h6f;
		memory[16'hba] <= 8'h22;
		memory[16'hbb] <= 8'h19;
		memory[16'hbc] <= 8'hba;
		memory[16'hbd] <= 8'h9b;
		memory[16'hbe] <= 8'h7d;
		memory[16'hbf] <= 8'hf5;
		memory[16'hc0] <= 8'hb;
		memory[16'hc1] <= 8'he1;
		memory[16'hc2] <= 8'h1a;
		memory[16'hc3] <= 8'h1c;
		memory[16'hc4] <= 8'h7f;
		memory[16'hc5] <= 8'h23;
		memory[16'hc6] <= 8'hf8;
		memory[16'hc7] <= 8'h29;
		memory[16'hc8] <= 8'hf8;
		memory[16'hc9] <= 8'ha4;
		memory[16'hca] <= 8'h1b;
		memory[16'hcb] <= 8'h13;
		memory[16'hcc] <= 8'hb5;
		memory[16'hcd] <= 8'hca;
		memory[16'hce] <= 8'h4e;
		memory[16'hcf] <= 8'he8;
		memory[16'hd0] <= 8'h98;
		memory[16'hd1] <= 8'h32;
		memory[16'hd2] <= 8'h38;
		memory[16'hd3] <= 8'he0;
		memory[16'hd4] <= 8'h79;
		memory[16'hd5] <= 8'h4d;
		memory[16'hd6] <= 8'h3d;
		memory[16'hd7] <= 8'h34;
		memory[16'hd8] <= 8'hbc;
		memory[16'hd9] <= 8'h5f;
		memory[16'hda] <= 8'h4e;
		memory[16'hdb] <= 8'h77;
		memory[16'hdc] <= 8'hfa;
		memory[16'hdd] <= 8'hcb;
		memory[16'hde] <= 8'h6c;
		memory[16'hdf] <= 8'h5;
		memory[16'he0] <= 8'hac;
		memory[16'he1] <= 8'h86;
		memory[16'he2] <= 8'h21;
		memory[16'he3] <= 8'h2b;
		memory[16'he4] <= 8'haa;
		memory[16'he5] <= 8'h1a;
		memory[16'he6] <= 8'h55;
		memory[16'he7] <= 8'ha2;
		memory[16'he8] <= 8'hbe;
		memory[16'he9] <= 8'h70;
		memory[16'hea] <= 8'hb5;
		memory[16'heb] <= 8'h73;
		memory[16'hec] <= 8'h3b;
		memory[16'hed] <= 8'h4;
		memory[16'hee] <= 8'h5c;
		memory[16'hef] <= 8'hd3;
		memory[16'hf0] <= 8'h36;
		memory[16'hf1] <= 8'h94;
		memory[16'hf2] <= 8'hb3;
		memory[16'hf3] <= 8'haf;
		memory[16'hf4] <= 8'he2;
		memory[16'hf5] <= 8'hf0;
		memory[16'hf6] <= 8'he4;
		memory[16'hf7] <= 8'h9e;
		memory[16'hf8] <= 8'h4f;
		memory[16'hf9] <= 8'h32;
		memory[16'hfa] <= 8'h15;
		memory[16'hfb] <= 8'h49;
		memory[16'hfc] <= 8'hfd;
		memory[16'hfd] <= 8'h82;
		memory[16'hfe] <= 8'h4e;
		memory[16'hff] <= 8'ha9;
		memory[16'h100] <= 8'h8;
		memory[16'h101] <= 8'h70;
		memory[16'h102] <= 8'hd4;
		memory[16'h103] <= 8'hb2;
		memory[16'h104] <= 8'h8a;
		memory[16'h105] <= 8'h29;
		memory[16'h106] <= 8'h54;
		memory[16'h107] <= 8'h48;
		memory[16'h108] <= 8'h9a;
		memory[16'h109] <= 8'ha;
		memory[16'h10a] <= 8'hbc;
		memory[16'h10b] <= 8'hd5;
		memory[16'h10c] <= 8'he;
		memory[16'h10d] <= 8'h18;
		memory[16'h10e] <= 8'ha8;
		memory[16'h10f] <= 8'h44;
		memory[16'h110] <= 8'hac;
		memory[16'h111] <= 8'h5b;
		memory[16'h112] <= 8'hf3;
		memory[16'h113] <= 8'h8e;
		memory[16'h114] <= 8'h4c;
		memory[16'h115] <= 8'hd7;
		memory[16'h116] <= 8'h2d;
		memory[16'h117] <= 8'h9b;
		memory[16'h118] <= 8'h9;
		memory[16'h119] <= 8'h42;
		memory[16'h11a] <= 8'he5;
		memory[16'h11b] <= 8'h6;
		memory[16'h11c] <= 8'hc4;
		memory[16'h11d] <= 8'h33;
		memory[16'h11e] <= 8'haf;
		memory[16'h11f] <= 8'hcd;
		memory[16'h120] <= 8'ha3;
		memory[16'h121] <= 8'h84;
		memory[16'h122] <= 8'h7f;
		memory[16'h123] <= 8'h2d;
		memory[16'h124] <= 8'had;
		memory[16'h125] <= 8'hd4;
		memory[16'h126] <= 8'h76;
		memory[16'h127] <= 8'h47;
		memory[16'h128] <= 8'hde;
		memory[16'h129] <= 8'h32;
		memory[16'h12a] <= 8'h1c;
		memory[16'h12b] <= 8'hec;
		memory[16'h12c] <= 8'h4a;
		memory[16'h12d] <= 8'hc4;
		memory[16'h12e] <= 8'h30;
		memory[16'h12f] <= 8'hf6;
		memory[16'h130] <= 8'h20;
		memory[16'h131] <= 8'h23;
		memory[16'h132] <= 8'h85;
		memory[16'h133] <= 8'h6c;
		memory[16'h134] <= 8'hfb;
		memory[16'h135] <= 8'hb2;
		memory[16'h136] <= 8'h7;
		memory[16'h137] <= 8'h4;
		memory[16'h138] <= 8'hf4;
		memory[16'h139] <= 8'hec;
		memory[16'h13a] <= 8'hb;
		memory[16'h13b] <= 8'hb9;
		memory[16'h13c] <= 8'h20;
		memory[16'h13d] <= 8'hba;
		memory[16'h13e] <= 8'h86;
		memory[16'h13f] <= 8'hc3;
		memory[16'h140] <= 8'h3e;
		memory[16'h141] <= 8'h5;
		memory[16'h142] <= 8'hf1;
		memory[16'h143] <= 8'hec;
		memory[16'h144] <= 8'hd9;
		memory[16'h145] <= 8'h67;
		memory[16'h146] <= 8'h33;
		memory[16'h147] <= 8'hb7;
		memory[16'h148] <= 8'h99;
		memory[16'h149] <= 8'h50;
		memory[16'h14a] <= 8'ha3;
		memory[16'h14b] <= 8'he3;
		memory[16'h14c] <= 8'h14;
		memory[16'h14d] <= 8'hd3;
		memory[16'h14e] <= 8'hd9;
		memory[16'h14f] <= 8'h34;
		memory[16'h150] <= 8'hf7;
		memory[16'h151] <= 8'h5e;
		memory[16'h152] <= 8'ha0;
		memory[16'h153] <= 8'hf2;
		memory[16'h154] <= 8'h10;
		memory[16'h155] <= 8'ha8;
		memory[16'h156] <= 8'hf6;
		memory[16'h157] <= 8'h5;
		memory[16'h158] <= 8'h94;
		memory[16'h159] <= 8'h1;
		memory[16'h15a] <= 8'hbe;
		memory[16'h15b] <= 8'hb4;
		memory[16'h15c] <= 8'hbc;
		memory[16'h15d] <= 8'h44;
		memory[16'h15e] <= 8'h78;
		memory[16'h15f] <= 8'hfa;
		memory[16'h160] <= 8'h49;
		memory[16'h161] <= 8'h69;
		memory[16'h162] <= 8'he6;
		memory[16'h163] <= 8'h23;
		memory[16'h164] <= 8'hd0;
		memory[16'h165] <= 8'h1a;
		memory[16'h166] <= 8'hda;
		memory[16'h167] <= 8'h69;
		memory[16'h168] <= 8'h6a;
		memory[16'h169] <= 8'h7e;
		memory[16'h16a] <= 8'h4c;
		memory[16'h16b] <= 8'h7e;
		memory[16'h16c] <= 8'h51;
		memory[16'h16d] <= 8'h25;
		memory[16'h16e] <= 8'hb3;
		memory[16'h16f] <= 8'h48;
		memory[16'h170] <= 8'h84;
		memory[16'h171] <= 8'h53;
		memory[16'h172] <= 8'h3a;
		memory[16'h173] <= 8'h94;
		memory[16'h174] <= 8'hfb;
		memory[16'h175] <= 8'h31;
		memory[16'h176] <= 8'h99;
		memory[16'h177] <= 8'h90;
		memory[16'h178] <= 8'h32;
		memory[16'h179] <= 8'h57;
		memory[16'h17a] <= 8'h44;
		memory[16'h17b] <= 8'hee;
		memory[16'h17c] <= 8'h9b;
		memory[16'h17d] <= 8'hbc;
		memory[16'h17e] <= 8'he9;
		memory[16'h17f] <= 8'he5;
		memory[16'h180] <= 8'h25;
		memory[16'h181] <= 8'hcf;
		memory[16'h182] <= 8'h8;
		memory[16'h183] <= 8'hf5;
		memory[16'h184] <= 8'he9;
		memory[16'h185] <= 8'he2;
		memory[16'h186] <= 8'h5e;
		memory[16'h187] <= 8'h53;
		memory[16'h188] <= 8'h60;
		memory[16'h189] <= 8'haa;
		memory[16'h18a] <= 8'hd2;
		memory[16'h18b] <= 8'hb2;
		memory[16'h18c] <= 8'hd0;
		memory[16'h18d] <= 8'h85;
		memory[16'h18e] <= 8'hfa;
		memory[16'h18f] <= 8'h54;
		memory[16'h190] <= 8'hd8;
		memory[16'h191] <= 8'h35;
		memory[16'h192] <= 8'he8;
		memory[16'h193] <= 8'hd4;
		memory[16'h194] <= 8'h66;
		memory[16'h195] <= 8'h82;
		memory[16'h196] <= 8'h64;
		memory[16'h197] <= 8'h98;
		memory[16'h198] <= 8'hd9;
		memory[16'h199] <= 8'ha8;
		memory[16'h19a] <= 8'h87;
		memory[16'h19b] <= 8'h75;
		memory[16'h19c] <= 8'h65;
		memory[16'h19d] <= 8'h70;
		memory[16'h19e] <= 8'h5a;
		memory[16'h19f] <= 8'h8a;
		memory[16'h1a0] <= 8'h3f;
		memory[16'h1a1] <= 8'h62;
		memory[16'h1a2] <= 8'h80;
		memory[16'h1a3] <= 8'h29;
		memory[16'h1a4] <= 8'h44;
		memory[16'h1a5] <= 8'hde;
		memory[16'h1a6] <= 8'h7c;
		memory[16'h1a7] <= 8'ha5;
		memory[16'h1a8] <= 8'h89;
		memory[16'h1a9] <= 8'h4e;
		memory[16'h1aa] <= 8'h57;
		memory[16'h1ab] <= 8'h59;
		memory[16'h1ac] <= 8'hd3;
		memory[16'h1ad] <= 8'h51;
		memory[16'h1ae] <= 8'had;
		memory[16'h1af] <= 8'hac;
		memory[16'h1b0] <= 8'h86;
		memory[16'h1b1] <= 8'h95;
		memory[16'h1b2] <= 8'h80;
		memory[16'h1b3] <= 8'hec;
		memory[16'h1b4] <= 8'h17;
		memory[16'h1b5] <= 8'he4;
		memory[16'h1b6] <= 8'h85;
		memory[16'h1b7] <= 8'hf1;
		memory[16'h1b8] <= 8'h8c;
		memory[16'h1b9] <= 8'hc;
		memory[16'h1ba] <= 8'h66;
		memory[16'h1bb] <= 8'hf1;
		memory[16'h1bc] <= 8'h7c;
		memory[16'h1bd] <= 8'hc0;
		memory[16'h1be] <= 8'h7c;
		memory[16'h1bf] <= 8'hbb;
		memory[16'h1c0] <= 8'h22;
		memory[16'h1c1] <= 8'hfc;
		memory[16'h1c2] <= 8'he4;
		memory[16'h1c3] <= 8'h66;
		memory[16'h1c4] <= 8'hda;
		memory[16'h1c5] <= 8'h61;
		memory[16'h1c6] <= 8'hb;
		memory[16'h1c7] <= 8'h63;
		memory[16'h1c8] <= 8'haf;
		memory[16'h1c9] <= 8'h62;
		memory[16'h1ca] <= 8'hbc;
		memory[16'h1cb] <= 8'h83;
		memory[16'h1cc] <= 8'hb4;
		memory[16'h1cd] <= 8'h69;
		memory[16'h1ce] <= 8'h2f;
		memory[16'h1cf] <= 8'h3a;
		memory[16'h1d0] <= 8'hff;
		memory[16'h1d1] <= 8'haf;
		memory[16'h1d2] <= 8'h27;
		memory[16'h1d3] <= 8'h16;
		memory[16'h1d4] <= 8'h93;
		memory[16'h1d5] <= 8'hac;
		memory[16'h1d6] <= 8'h7;
		memory[16'h1d7] <= 8'h1f;
		memory[16'h1d8] <= 8'hb8;
		memory[16'h1d9] <= 8'h6d;
		memory[16'h1da] <= 8'h11;
		memory[16'h1db] <= 8'h34;
		memory[16'h1dc] <= 8'h2d;
		memory[16'h1dd] <= 8'h8d;
		memory[16'h1de] <= 8'hef;
		memory[16'h1df] <= 8'h4f;
		memory[16'h1e0] <= 8'h89;
		memory[16'h1e1] <= 8'hd4;
		memory[16'h1e2] <= 8'hb6;
		memory[16'h1e3] <= 8'h63;
		memory[16'h1e4] <= 8'h35;
		memory[16'h1e5] <= 8'hc1;
		memory[16'h1e6] <= 8'hc7;
		memory[16'h1e7] <= 8'he4;
		memory[16'h1e8] <= 8'h24;
		memory[16'h1e9] <= 8'h83;
		memory[16'h1ea] <= 8'h67;
		memory[16'h1eb] <= 8'hd8;
		memory[16'h1ec] <= 8'hed;
		memory[16'h1ed] <= 8'h96;
		memory[16'h1ee] <= 8'h12;
		memory[16'h1ef] <= 8'hec;
		memory[16'h1f0] <= 8'h45;
		memory[16'h1f1] <= 8'h39;
		memory[16'h1f2] <= 8'h2;
		memory[16'h1f3] <= 8'hd8;
		memory[16'h1f4] <= 8'he5;
		memory[16'h1f5] <= 8'ha;
		memory[16'h1f6] <= 8'hf8;
		memory[16'h1f7] <= 8'h9d;
		memory[16'h1f8] <= 8'h77;
		memory[16'h1f9] <= 8'h9;
		memory[16'h1fa] <= 8'hd1;
		memory[16'h1fb] <= 8'ha5;
		memory[16'h1fc] <= 8'h96;
		memory[16'h1fd] <= 8'hc1;
		memory[16'h1fe] <= 8'hf4;
		memory[16'h1ff] <= 8'h1f;
	end
endmodule
