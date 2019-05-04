#include <stdio.h>
#include <math.h>
#include <stdint.h>

#define SCALE_SIGMOID 24
#define SCALE_TANH 48

#define ZERO_SIGMOID 128
#define ZERO_TANH 128

#define OUT_SCALE_SIGMOID 256
#define OUT_SCALE_TANH 128

#define OUT_ZERO_SIGMOID 0
#define OUT_ZERO_TANH 128

double sigmoid(double x){
        double exp_value;
        double return_value;

        exp_value = exp(-x);

        return_value = 1/(1 + exp_value);
        return return_value;
}
void init_module(FILE* f, char* module_name){

	fprintf(f, "module %s (\n\n", module_name);
	fprintf(f, "\tinput [7:0] addr,\n");
	fprintf(f, "\toutput reg [7:0] dout\n");
	fprintf(f, "\t);\n\n");

	fprintf(f, "\talways @(*) begin\n");
	fprintf(f, "\t\tcase(addr)\n");

	return;
}

void write_module(FILE * f, uint8_t addr, uint8_t val){

	fprintf(f, "\t\t\t8'h%x : dout = 8'h%x;\n", addr, val);
}

void end_module(FILE * f){

	fprintf(f, "\t\tendcase\n");
	fprintf(f, "\tend\n\n");
	fprintf(f, "endmodule\n");
}

int main(){

	FILE * tanh_f;
	FILE * sigmoid_f;

	/*tanh verilog LUT*/
	if(tanh_f = fopen("tanh_LUT.v", "w")){
		
		init_module(tanh_f, "tanh_LUT");
		for(int i = 0; i < 256; i++){

			double val = tanh((double)(i - ZERO_TANH)/(double)(SCALE_TANH));
			uint8_t q_val = (uint8_t)round(val*(double)(OUT_SCALE_TANH) + (double)(OUT_ZERO_TANH));
			write_module(tanh_f, i, q_val);
		}
		end_module(tanh_f);
	}
	else
		printf("tanh_LUT.v open fails\n");

	fclose(tanh_f);

	/*sigmoid verilog LUT*/
	if(sigmoid_f = fopen("sigmoid_LUT.v", "w")){
		
		init_module(sigmoid_f, "sigmoid_LUT");
		for(int i = 0; i < 256; i++){

			double val = sigmoid((double)(i - ZERO_SIGMOID)/(double)(SCALE_SIGMOID));
			uint8_t q_val = (uint8_t)round(val*(double)(OUT_SCALE_SIGMOID) + (double)(OUT_ZERO_SIGMOID));
			write_module(sigmoid_f, i, q_val);
		}

		end_module(sigmoid_f);
	}
	else
		printf("sigmoid_LUT.v open fails\n");

	fclose(sigmoid_f);

	return 0;
}
