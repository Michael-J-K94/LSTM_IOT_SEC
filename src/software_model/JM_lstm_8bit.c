#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdint.h>

#define DEBUG 1
#define WX_T 0
#define MAQ 1
#define FIGO 1
#define TMQ 1


#define DEBUG_OUTPUT 1
/* random number generation */
#define SEED 1

/* lstm cell parameters */
#define DATA_SIZE 2
#define VOCA_SIZE 8
#define HIDDEN_SIZE 8

/* quantization parameters */
/*
IN & OUT, WEIGHT_X & WEIGHT_H have the same range
IN = [-1,1]
STATE = [-1,1]
OUT = [-1,1]
WEIGHT_X = [-1,1]
WEIGHT_H = [-1,1]
BIAS = [0,1]
*/
#define SCALE_DATA 128
#define SCALE_STATE 128
#define SCALE_W 128
#define SCALE_B 256

#define ZERO_DATA 128
#define ZERO_STATE 128
#define ZERO_W 128
#define ZERO_B 0

/* activation function parameters */
#define SCALE_SIGMOID 24
#define SCALE_TANH 48

#define ZERO_SIGMOID 128
#define ZERO_TANH 128

#define OUT_SCALE_SIGMOID 256
#define OUT_SCALE_TANH 128

#define OUT_ZERO_SIGMOID 0
#define OUT_ZERO_TANH 128

struct data{
	uint8_t * x;
	uint8_t * h;
};

struct weight{
	uint8_t * w_ix;
	uint8_t * w_ih;

	uint8_t * w_cx;
	uint8_t * w_ch;

	uint8_t * w_fx;
	uint8_t * w_fh;

	uint8_t * w_ox;
	uint8_t * w_oh;
};

struct bias{
	uint8_t * b_i;
	uint8_t * b_c;
	uint8_t * b_f;
	uint8_t * b_o;
};

/* no batch */
/* weights protocol
	unit 1:	[w_ix(voca_size), w_ih(hidden_size)],[w_cx, w_ch],[w_fx, w_fh], [w_ox, w_oh]
	unit 2: ...

	unit n: ...

   biases protocol
	unit 1: [b_i],[b_c],[b_f],[b_o]
	unit 2: ...

	unit n: ...
*/
//consider all matrices as 1-dim vectors

/*activation functions*/
double sigmoid(double x){

	double exp_value;
	double return_value;

	exp_value = exp(-x);

	return_value = 1/(1 + exp_value);
	return return_value;
}

uint8_t sigmoid_LUT(uint8_t x){

	int addr = x;
	double val = sigmoid((double)(addr - ZERO_SIGMOID)/(double)(SCALE_SIGMOID));
	uint8_t q_val = (uint8_t)round(val*(double)(OUT_SCALE_SIGMOID) + (double)(OUT_ZERO_SIGMOID));
	return q_val;
}

uint8_t tanh_LUT(uint8_t x){
	
	int addr = x;
	double val = tanh((double)(x - ZERO_TANH)/(double)(SCALE_TANH));
	uint8_t q_val = (uint8_t)round(val*(double)(OUT_SCALE_TANH) + (double)(OUT_ZERO_TANH));
	return q_val;
}

int inner_product(uint8_t * x, uint8_t * y, int vector_size){
	int sum = 0;
	for(int i = 0 ; i < vector_size ; i++){
		sum += ((int)x[i] - ZERO_W)*((int)y[i] - ZERO_DATA);
	}
	#if WX_T

	printf("W: [");
	for(int i=0; i<vector_size; i++){
		printf("0x%x, ", (int)x[i]);
	}
	printf("] \n");

	printf("Wtemp: [");
	for(int i=0; i<vector_size; i++){
		printf("0x%x, ", (int)x[i]-ZERO_W);
	}
	printf("] \n");
	/*
	printf("XHtemp: [");
	for(int i=0; i<vector_size; i++) {
		printf("0x%x, ", (int)y[i] - ZERO_DATA);
	}
	printf("] \n");
	*/
	#endif


	return sum;
}

uint8_t saturate(int q){

	return q > 255 ? (uint8_t)255 : (q < 0 ? (uint8_t)0 : (uint8_t)q);
}

/* data_set protocol
	data 1 : [x_t(voca_size), h_t-1(hidden_size)], h_t-1 = 0
	data 2 : [x_t+1, h_t]
	
	data n : ...
*/
void init_cell_state(uint8_t * state, int hidden_size){
	for(int i = 0 ; i < hidden_size ; i++){
		state[i] = (uint8_t)ZERO_STATE;
	}
}

void make_data_set(struct data * data_set, uint8_t * input_data, int hidden_size, int data_size){
	
	uint8_t* output_data = (uint8_t*)malloc((data_size + 1)*(sizeof(uint8_t) * hidden_size));

	for(int i = 0 ; i < data_size + 1 ; i++){
		data_set[i].x = input_data + i*hidden_size;
		if(i == 0){
			for(int j = 0 ; j < hidden_size ; j++){
				(output_data + i*hidden_size)[j] = (uint8_t)ZERO_DATA;
			}
		}
		data_set[i].h = output_data + i*hidden_size;
	}
}

void make_weight_set(struct weight * weight_set, uint8_t * input_weight, int voca_size, int hidden_size){
	
	int vector_size = voca_size + hidden_size;
	int step = vector_size * 4;

	for(int i = 0 ; i < hidden_size ; i++){
		weight_set[i].w_ix = input_weight + vector_size*0 + i*step;
		weight_set[i].w_ih = input_weight + vector_size*0 + voca_size + i*step;

                weight_set[i].w_cx = input_weight + vector_size*1 + i*step;
                weight_set[i].w_ch = input_weight + vector_size*1 + voca_size + i*step;

                weight_set[i].w_fx = input_weight + vector_size*2 + i*step;
                weight_set[i].w_fh = input_weight + vector_size*2 + voca_size + i*step;

                weight_set[i].w_ox = input_weight + vector_size*3 + i*step;
                weight_set[i].w_oh = input_weight + vector_size*3 + voca_size + i*step;		
	}
}

void make_bias_set(struct bias * bias_set, uint8_t * input_bias, int hidden_size){
	
	int step = 4;

	for(int i = 0 ; i < hidden_size ; i++){
		bias_set[i].b_i = input_bias + i*step;
		bias_set[i].b_c = input_bias + 1 + i*step;
		bias_set[i].b_f = input_bias + 2 + i*step;
		bias_set[i].b_o = input_bias + 3 + i*step;
	}
}

void lstm_cell_inference(uint8_t* cell_state, struct data * data_set, 
		const struct weight * weight_set, const struct bias * bias_set, const int voca_size, const int hidden_size, const int num_step){
	
	int vector_size = voca_size + hidden_size;

	uint8_t * i = (uint8_t*)malloc(sizeof(uint8_t) * hidden_size);
	uint8_t * c = (uint8_t*)malloc(sizeof(uint8_t) * hidden_size);
	uint8_t * f = (uint8_t*)malloc(sizeof(uint8_t) * hidden_size);
	uint8_t * o = (uint8_t*)malloc(sizeof(uint8_t) * hidden_size);

	for(int step = 0; step < num_step; step++){
		for(int unit = 0 ; unit < hidden_size ; unit++){

			int sum, real_sum, bias, real_bias;
			/* i calc */
			sum = inner_product(weight_set[unit].w_ix, data_set[step].x, voca_size) + 
				inner_product(weight_set[unit].w_ih, data_set[step].h, hidden_size);
			real_sum = (sum * SCALE_SIGMOID)/(SCALE_W*SCALE_DATA);
			
			bias = (int)(*bias_set[unit].b_i);
			real_bias = ((bias - ZERO_B)*SCALE_SIGMOID)/SCALE_B;
			#if FIGO
			printf("i: ");
			printf("inpdt_R_reg = (0x%x) , real_inpdt_sumBQS = (0x%x) , real_biasBQS = (0x%x) ", sum, real_sum, real_bias);
			printf("unsat_BQS = (0x%x) ", (real_sum + real_bias + ZERO_SIGMOID));
			printf("sat_BQS = (0x%x) " , (saturate(real_sum + real_bias + ZERO_SIGMOID)));
			printf("oSigmoid_LUT = (0x%x) \n", sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID)));
			#endif
			i[unit] = sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID));
			#if DEBUG
			printf("i[%d] = %f(0x%x)\n", step, ((float)i[unit] - OUT_ZERO_SIGMOID)/OUT_SCALE_SIGMOID,i[unit]);
			#endif
			/* c calc */

			sum = inner_product(weight_set[unit].w_cx, data_set[step].x, voca_size) +
                                inner_product(weight_set[unit].w_ch, data_set[step].h, hidden_size);
                        real_sum = (sum * SCALE_TANH)/(SCALE_W*SCALE_DATA);
			
                        bias = (int)(*bias_set[unit].b_c);
                        real_bias = ((bias - ZERO_B)*SCALE_TANH)/SCALE_B;
			#if FIGO
			printf("g: ");
			printf("inpdt_R_reg = (0x%x) , real_inpdt_sumBQT = (0x%x) , real_biasBQT = (0x%x) ", sum, real_sum, real_bias);
			printf("unsat_BQT = (0x%x) ", (real_sum + real_bias + ZERO_TANH));
			printf("sat_BQS = (0x%x) " , (saturate(real_sum + real_bias + ZERO_TANH)));
			printf("oTanh_LUT = (0x%x) \n", tanh_LUT(saturate(real_sum + real_bias + ZERO_TANH)));
			#endif
                        c[unit] = tanh_LUT(saturate(real_sum + real_bias + ZERO_TANH));

			#if DEBUG	
			printf("g[%d] = %f(0x%x)\n", step, ((float)c[unit] - OUT_ZERO_TANH)/OUT_SCALE_TANH, c[unit]);
			#endif

			/* f calc */
			sum = inner_product(weight_set[unit].w_fx, data_set[step].x, voca_size) +
                                inner_product(weight_set[unit].w_fh, data_set[step].h, hidden_size);
                        real_sum = (sum * SCALE_SIGMOID)/(SCALE_W*SCALE_DATA);

                        bias = (int)(*bias_set[unit].b_f);
                        real_bias = ((bias - ZERO_B) * SCALE_SIGMOID)/SCALE_B;
			#if FIGO
			printf("f: ");
			printf("inpdt_R_reg = (0x%x) , real_inpdt_sumBQS = (0x%x) , real_biasBQS = (0x%x) ", sum, real_sum, real_bias);
			printf("unsat_BQS = (0x%x) ", (real_sum + real_bias + ZERO_SIGMOID));
			printf("sat_BQS = (0x%x) " , (saturate(real_sum + real_bias + ZERO_SIGMOID)));
			printf("oSigmoid_LUT = (0x%x) \n", sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID)));
			#endif
                        f[unit] = sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID));
		
			#if DEBUG
			printf("f[%d] = %f(0x%x)\n", step, ((float)f[unit] - OUT_ZERO_SIGMOID)/OUT_SCALE_SIGMOID, f[unit]);
			#endif
			/* o calc */
			sum = inner_product(weight_set[unit].w_ox, data_set[step].x, voca_size) +
                                inner_product(weight_set[unit].w_oh, data_set[step].h, hidden_size);
                        real_sum = (sum * SCALE_SIGMOID)/(SCALE_W*SCALE_DATA);

                        bias = (int)(*bias_set[unit].b_o);
                        real_bias = ((bias - ZERO_B)*SCALE_SIGMOID)/SCALE_B;
			#if FIGO
			printf("o: ");
			printf("inpdt_R_reg = (0x%x) , real_inpdt_sumBQS = (0x%x) , real_biasBQS = (0x%x) ", sum, real_sum, real_bias);
			printf("unsat_BQS = (0x%x) ", (real_sum + real_bias + ZERO_SIGMOID));
			printf("sat_BQS = (0x%x) " , (saturate(real_sum + real_bias + ZERO_SIGMOID)));
			printf("oSigmoid_LUT = (0x%x) \n", sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID)));
			#endif
                        o[unit] = sigmoid_LUT(saturate(real_sum + real_bias + ZERO_SIGMOID));

			#if DEBUG
			printf("o[%d] = %f(0x%x)\n", step, ((float)o[unit] - OUT_ZERO_SIGMOID)/OUT_SCALE_SIGMOID, o[unit]);
			#endif
			/* elementwise product */
			real_sum  = ((int)f[unit] - OUT_ZERO_SIGMOID)*((int)cell_state[unit] - ZERO_STATE)/OUT_SCALE_SIGMOID
					+ ((int)i[unit] - OUT_ZERO_SIGMOID)*((int)c[unit] - OUT_ZERO_TANH)*(SCALE_STATE)/(OUT_SCALE_SIGMOID * OUT_SCALE_TANH);
			#if MAQ		
			printf("ct = (ox%x) ", (int)cell_state[unit]);
			printf("real_ctf_MAQ = (0x%x) ", ((int)f[unit] - OUT_ZERO_SIGMOID)*((int)cell_state[unit] - ZERO_STATE)/OUT_SCALE_SIGMOID);
			printf("real_ig_MAQ = (0x%x) ", ((int)i[unit] - OUT_ZERO_SIGMOID)*((int)c[unit] - OUT_ZERO_TANH)*(SCALE_STATE)/(OUT_SCALE_SIGMOID * OUT_SCALE_TANH));
			printf("real_sum_MAQ = (0x%x) unsat_MAQ = (0x%x) \n", real_sum, real_sum+ZERO_STATE);
			#endif

			cell_state[unit] = saturate(real_sum + ZERO_STATE);

			#if DEBUG
			printf("cell_state[%d](sat_MAQ) = %f(0x%x)\n\n", step, ((float)cell_state[unit] - ZERO_STATE)/SCALE_STATE, cell_state[unit]);
			#endif

			real_sum = ((int)o[unit] - OUT_ZERO_SIGMOID)*((int)tanh_LUT(saturate(((cell_state[unit] - ZERO_STATE)*SCALE_TANH)/SCALE_STATE + ZERO_TANH)) - OUT_ZERO_TANH);
			int real_sum1 = real_sum;
			real_sum = (real_sum * SCALE_DATA)/(OUT_SCALE_TANH * OUT_SCALE_SIGMOID);

			data_set[step + 1].h[unit] = saturate(real_sum + ZERO_DATA);
			#if TMQ
			printf("unsat_ct_TMQ = (0x%x) ", ((cell_state[unit]-ZERO_STATE)*SCALE_TANH)/SCALE_STATE + ZERO_TANH);
			printf("sat_ct_TMQ = (0x%x) ", saturate(((cell_state[unit] - ZERO_STATE)*SCALE_TANH)/SCALE_STATE + ZERO_TANH));
			printf("oTanh_LUT = (0x%x) \n", tanh_LUT(saturate(((cell_state[unit] - ZERO_STATE)*SCALE_TANH)/SCALE_STATE + ZERO_TANH)) );
			printf("unscale_ht_TMQ = (0x%x) ", real_sum1);
			printf("unsat_ht_TMQ = (0x%x) unsat_Z_ht_TMQ = (0x%x)", real_sum, real_sum + ZERO_DATA);
			printf("sat_ht_TMQ = (0x%x) \n\n", saturate(real_sum+ZERO_DATA));
			#endif


		}
		/* debug */
		#if DEBUG_OUTPUT
		printf("[");
		for(int i = 0; i < HIDDEN_SIZE; i++){
			printf("%f", ((float)(data_set[step + 1].h[i]) - ZERO_DATA)/SCALE_DATA);
			if(i != HIDDEN_SIZE - 1)
				printf(",");
		}
		printf("]\n");

		printf("Ht: [");
		for(int i = 0; i < HIDDEN_SIZE; i++){
			printf("%x", (data_set[step + 1].h[i]));
			if(i != HIDDEN_SIZE - 1)
				printf(",");
		}
		printf("]\n");

		printf("Ct: [");
		for(int i = 0; i < HIDDEN_SIZE; i++){
			printf("%x", (cell_state[i]));
			if(i != HIDDEN_SIZE - 1)
				printf(",");
		}
		printf("]\n\n\n");

		#endif
	}
	free(i);
	free(c);
	free(f);
	free(o);
}

/* print function */
void set_memory(FILE * f, uint8_t data, int address){

	fprintf(f, "\t\t");
	fprintf(f, "memory[16'h%x] <= 8'h%x;\n", address, data);
}
void init_memory(FILE * f, char * module_name){
	/* read_only memory */
	/* streaming */
	fprintf(f, "`timescale 1ns/100ps\n");
	fprintf(f, "`define INIT_DELAY 100\n");
	fprintf(f, "`define INTERVAL 10\n");
	fprintf(f, "`define MEM_SIZE 65536\n\n");

	fprintf(f, "module %s(\n", module_name);
	fprintf(f, "\tinput readM,\n");
	fprintf(f, "\toutput reg ready,\n");
	fprintf(f, "\toutput reg [7:0] data\n");
	fprintf(f, "\t);\n");
	fprintf(f, "\n");
	
	fprintf(f, "\treg [7:0] memory [`MEM_SIZE - 1:0];\n");
	fprintf(f, "\treg [15:0] address;\n");
	fprintf(f, "\n");

	fprintf(f, "\talways begin\n");
	fprintf(f, "\t\t#`INIT_DELAY\n");
	fprintf(f, "\t\tforever begin\n");
	fprintf(f, "\t\t\twait(readM == 1);\n");
	fprintf(f, "\t\t\t#`INTERVAL;\n");
	fprintf(f, "\t\t\tdata = memory[address];\n");
	fprintf(f, "\t\t\taddress = address + 1;\n");
	fprintf(f, "\t\t\tready = 1;\n");
	fprintf(f, "\t\t\twait(readM == 0);\n");
	fprintf(f, "\t\t\tready = 0;\n");
	fprintf(f, "\t\tend\n");
	fprintf(f, "\tend\n\n");
	
	fprintf(f, "\tinitial begin\n");
	fprintf(f, "\t\taddress <= 0;\n");
	fprintf(f, "\t\tready <= 0;\n");
	fprintf(f, "\tend\n\n");

	/* memory setup */
	fprintf(f, "\tinitial begin\n");
}

void end_memory(FILE * f){

	fprintf(f, "\tend\n");
	fprintf(f, "endmodule\n");
}

void print_input(FILE * f, uint8_t * input_data, int data_size, char * module_name){
	init_memory(f, module_name);
	for(int i = 0; i < data_size; i++){
		set_memory(f, input_data[i], i);
	}
	end_memory(f);
}

void print_output(FILE * f, struct data * data_set, int hidden_size ,int data_size, char * module_name){
	init_memory(f, module_name);
	for(int i = 0; i < data_size; i++){
		for(int j = 0; j < hidden_size; j++){
			set_memory(f, data_set[i+1].h[j], hidden_size*i + j);
		}
	}
	end_memory(f);
}

void print_context(FILE * f, struct data * data_set, uint8_t * cell_state, int hidden_size, char * module_name){
	/*c_0 first, h_-1 last*/
	init_memory(f, module_name);
	for(int i = 0; i < hidden_size; i++){
		set_memory(f, ZERO_STATE, i);
	}
	for(int i = 0; i < hidden_size; i++){
		set_memory(f, data_set[0].h[i], i+hidden_size);

	}
	end_memory(f);
}

int main(int argc, char ** argv){

	struct data data_set[DATA_SIZE + 1];

	/* BRAM */
	uint8_t cell_state[HIDDEN_SIZE];
        struct weight weight_set[HIDDEN_SIZE];
        struct bias bias_set[HIDDEN_SIZE];

	/* from OS */
	uint8_t input_data[DATA_SIZE*VOCA_SIZE];
	uint8_t input_weight[(VOCA_SIZE + HIDDEN_SIZE) * HIDDEN_SIZE * 4];
	uint8_t input_bias[HIDDEN_SIZE * 4];

	srand(SEED);

	for(int i = 0; i < (VOCA_SIZE + HIDDEN_SIZE) * HIDDEN_SIZE * 4 ; i++){
		//input_weight[i] = saturate((int)round((float)(i+1)/10*SCALE_W + ZERO_W));
		//printf("input_weight = %u\n",input_weight[i]);
		input_weight[i] = rand()%256;
	}
	for(int i = 0; i < HIDDEN_SIZE * 4; i++){
		input_bias[i] = saturate((int)round((float)(5)/10*SCALE_B + ZERO_B));
		//printf("input_bias = %u\n", input_bias[i]);
		//input_bias[i] = rand()%256;;
	}
	for(int i = 0; i < DATA_SIZE*VOCA_SIZE; i++){
		//input_data[i] = saturate((int)round((float)i/10*SCALE_DATA + ZERO_DATA));
		//printf("input_data = %u\n", input_data[i]);
		if(i < VOCA_SIZE){
			input_data[i] = (uint8_t)ZERO_DATA;
		}
		else 
			input_data[i] = rand()%256;
	}

	init_cell_state(cell_state, HIDDEN_SIZE);
	/*convert float array to structrue */
	make_data_set(data_set, input_data, HIDDEN_SIZE, DATA_SIZE);
	make_weight_set(weight_set, input_weight, VOCA_SIZE, HIDDEN_SIZE);
	make_bias_set(bias_set, input_bias, HIDDEN_SIZE);

	lstm_cell_inference(cell_state, data_set, weight_set, bias_set, VOCA_SIZE, HIDDEN_SIZE, DATA_SIZE);
	
	/* memory.v */
	FILE * input_f, *output_f, *weight_f, *bias_f, *init_context_f; 
	if(input_f = fopen("input_data_memory.v", "w")){
		print_input(input_f, input_data, DATA_SIZE*VOCA_SIZE,"input_data_memory");
	}
	else
		printf("input_data_memory.v open failed\n");
	fclose(input_f);

	if(weight_f = fopen("weight_memory.v", "w")){
		print_input(weight_f, input_weight, (VOCA_SIZE + HIDDEN_SIZE) * HIDDEN_SIZE * 4, "weight_memory");
	}
	else
		printf("weight_memory.v open failed\n");
	fclose(weight_f);

	if(bias_f = fopen("bias_memory.v", "w")){
		print_input(weight_f, input_bias, HIDDEN_SIZE * 4, "bias_memory");
	}
	else
		printf("bias_memory.v open failed\n");
	fclose(bias_f);

	if(output_f = fopen("output_memory.v", "w")){
		print_output(output_f, data_set, HIDDEN_SIZE, DATA_SIZE, "output_memory");
	}
	else
		printf("output_memory.v open failed\n");
	fclose(output_f);

	if(init_context_f = fopen("context_memory.v", "w")){
		print_context(init_context_f, data_set, cell_state, HIDDEN_SIZE, "context_memory");
	}
	fclose(init_context_f);

	return 0;
}
