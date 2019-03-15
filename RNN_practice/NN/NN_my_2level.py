import numpy as np

def nonlin(x,deriv=False):
	if(deriv == True):
		return x*(1-x)
	else:
		return 1/(1+np.exp(-x) )

X = np.array([ [0,0,1],
		[0,1,1],
		[1,0,1],
		[1,1,1] ])
y = np.array([ [0],[1],[1],[0] ])
np.random.seed(1)

weight0 = 2*np.random.random( (3,4) ) -1
weight1 = 2*np.random.random( (4,1) ) -1

for  j in range(60000):

	l0 = X
	l1 = nonlin(np.dot(l0,weight0))
	l2 = nonlin(np.dot(l1,weight1))

	l2_error = y-l2

	if(j%10000)==0:
		print( 'Error:', np.mean(np.abs(l2_error))  )
	l2_delta = l2_error*nonlin(l2,deriv=True)
	l1_error = l2_delta.dot(weight1.T)
	l1_delta = l1_error*nonlin(l1,deriv=True)	
	weight1 += l1.T.dot(l2_delta)
	weight0 += l0.T.dot(l1_delta)

	
