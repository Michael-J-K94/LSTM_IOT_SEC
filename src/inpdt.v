// This is a Top
// Description:
// Author: Michael Kim

module inpdt_16#(
)
(
	input [127:0] iData_X,	// 16*8b
	input [127:0] iData_W,	// 16*8b
	
	input iEn,				// for input blocking
		
	output [20:0] oResult	// for output
);

	reg [7:0] data_Xtemp [15:0];
	reg [7:0] data_Wtemp [15:0];

	reg [16:0] mul_temp [15:0];
	
	reg [17:0] add_temp1 [7:0];
	reg [18:0] add_temp2 [3:0];
	reg [19:0] add_temp3 [1:0];
	reg [20:0] add_temp4;
	
	
	integer i;
	
	always@(*) begin
	
		if(iEn) begin
			for(i=0; i<16; i++) begin
				data_Xtemp[i] = iData_X;
				data_Wtemp[i] = iData_W;
			end
		end
		else begin
			for(i=0; i<16; i++) begin
				data_Xtemp[i] = 'd0;
				data_Wtemp[i] = 'd0;
			end		
		end
	
		for(i=0; i<16; i++) begin
			mult_temp[i] = data_Xtemp[i]*data_Wtemp[i];
		end
		
		for(i=0; i<8; i++) begin
			add_temp1[i] = mult_temp[2*i] + mult_temp[2*i+1];
		end
		
		for(i=0; i<4; i++) begin
			add_temp2[i] = add_temp1[2*i] + add_temp1[2*i+1];
		end

		for(i=0; i<2; i++) begin
			add_temp3[i] = add_temp2[2*i] + add_temp2[2*i+1];
		end	
		
		add_temp4 = add_temp3[0] + add_temp[1];
		
	end

assign oResult = add_temp4;



endmodule
