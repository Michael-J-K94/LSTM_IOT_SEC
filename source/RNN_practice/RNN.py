import copy, numpy as np
np.random.seed(0)

# compute sigmoid nonlinearity
def sigmoid(x):
	output = 1/(1+np.exp(-x))
	return output

#convert output of sigmoid funciton to its derivative
def sigmoid_output_to_derivative(output):
	return output*(1-output)

#training dataset generation
int2binary = {}
binary_dim = 8

largest_number = pow(2,binary_dim)
binary = np.unpackbits( 
