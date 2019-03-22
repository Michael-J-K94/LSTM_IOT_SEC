import copy, numpy as np
np.random.seed(0)

def sigmoid(x):
	output = 1/(1+np.exp(-x))
	return output
def sigout_to_deriv(output):
	return output*(1-output)

# int_to_binary LUT creation.
int2binary = {}
binary_dim = 8

largest_num = pow(2,binary_dim)
binary = np.unpackbits( np.array( [range(largest_num)],dtype=np.uint8 ).T,axis=1 )

for i in range(largest_num):
	int2binary[i] = binary[i]


alpha = 0.1
input_dim = 2
hidden_dim = 16
output_dim = 1

Wxh = 2*np.random.random( (input_dim,hidden_dim) ) -1
Why = 2*np.random.random( (hidden_dim,output_dim) ) -1
Whh = 2*np.random.random( (hidden_dim,hidden_dim) ) -1

Wxh_update = np.zeros_like( Wxh )
Why_update = np.zeros_like( Why )
Whh_update = np.zeros_like( Whh )

for j in range(100000):

	#generating random data
	a_int = np.random.randint( largest_num/2 )
	a = int2binary[a_int]

	b_int = np.random.randint( largest_num/2 )
	b = int2binary[b_int]

	c_int = a_int + b_int
	c = int2binary[c_int]

	d=np.zeros_like(c)
	overallError = 0

	dyt = list()
	ht_prev = list()
	ht_prev.append(np.zeros(hidden_dim))

	for position in range(binary_dim):
		Xt = np.array([ [a[binary_dim-position-1],b[binary_dim-position-1]] ])
		output_label = np.array([ [c[binary_dim-position-1]] ]).T

		ht = sigmoid( np.dot(Xt,Wxh) ) + np.dot(ht_prev[-1],Whh)
		yt = sigmoid( np.dot(ht,Why) )
		
		yt_error = output_label - yt
		dyt.append( (yt_error)*sigout_to_deriv(yt) )
		overallError += np.abs( (yt_error)[0] )

		d[binary_dim - position - 1] = np.round(yt[0][0])

		ht_prev.append(copy.deepcopy(ht))

	future_dht = np.zeros(hidden_dim)
	for position in range(binary_dim):
		X = np.array([ [a[position],b[position]] ])
		ht = ht_prev[-position-1]
		ht_prev_capt = ht_prev[-position-2]

		dyt_capt = dyt[-position-1]
		dht = ( future_dht.dot(Whh.T) + dyt_capt.dot(Why.T ))*sigout_to_deriv(ht)

		Why_update += np.atleast_2d(ht).T.dot(dyt_capt)
		Whh_update += np.atleast_2d(ht_prev_capt).T.dot(dht)
		Wxh_update += Xt.T.dot(dht)

		future_dht = dht

	Wxh += Wxh_update*alpha
	Why += Why_update*alpha
	Whh += Whh_update*alpha

	Wxh_update *= 0
	Why_update *= 0
	Whh_update *= 0

	if (j%10000 == 0):
		print( 'Error:', str(overallError) )
		print( 'Pred:', str(d) )
		print( 'True:', str(c) )
		out = 0
		for index,x in enumerate(reversed(d)):
			out +=x*pow(2,index)
		print(a_int,'+',b_int,'=',out)
		print('-----------------------\n\n')












