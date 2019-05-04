// This is a Top
// Description:
// Author: Michael Kim

module inpdt_16
(
	input [127:0] iData_XH,	// 16*8b
	input [127:0] iData_W,	// 16*8b
	
	input iEn,				// for input blocking
		
	output [20:0] oResult	// for output
);

	reg [7:0] data_XHtemp [0:15];
	reg [7:0] data_Wtemp [0:15];

	reg [16:0] mul_temp [0:15];
	
	reg [17:0] add_temp1 [0:7];
	reg [18:0] add_temp2 [0:3];
	reg [19:0] add_temp3 [0:1];
	reg [20:0] add_temp4;
	
	
	integer i;
	
	always@(*) begin
	
		if(iEn) begin
			for(i=0; i<16; i=i+1) begin
				data_XHtemp[i] = iData_XH[128-8*(i+1)+:8];
				data_Wtemp[i] = iData_W[128-8*(i+1)+:8];
			end
		end
		else begin
			for(i=0; i<16; i=i+1) begin
				data_XHtemp[i] = 'd0;
				data_Wtemp[i] = 'd0;
			end		
		end
	
		for(i=0; i<16; i=i+1) begin
			mul_temp[i] = $signed({1'b0,data_XHtemp[i]})*$signed({1'b0,data_Wtemp[i]});
		end
		
		for(i=0; i<8; i=i+1) begin
			add_temp1[i] = $signed(mul_temp[2*i]) + $signed(mul_temp[2*i+1]);
		end
		
		for(i=0; i<4; i=i+1) begin
			add_temp2[i] = $signed(add_temp1[2*i]) + $signed(add_temp1[2*i+1]);
		end

		for(i=0; i<2; i=i+1) begin
			add_temp3[i] = $signed(add_temp2[2*i]) + $signed(add_temp2[2*i+1]);
		end	
		
		add_temp4 = $signed(add_temp3[0]) + $signed(add_temp3[1]);
		
	end

assign oResult = add_temp4;



endmodule
