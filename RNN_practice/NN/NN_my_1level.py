import numpy as np

# sigmoid function
def nonlin(x,deriv=False):
	if(deriv == True):
		return x*(1-x)
	return 1/(1+np.exp(-x))

#input
X = np.array([ [0,0,1],[0,1,1],[1,0,1],[1,1,1] ])
#output
y = np.array([[0,0,1,1]]).T
print('X:\n',X)
print('y:\n',y)

#seed rand numbers to make calc
np.random.seed(1)

#initialize weights randomly with mean 0
syn0 = 2*np.random.random((3,1))-1
#syn1 = 2*np.random.random((4,1))-1
print('syn0:\n',syn0)
#print('syn1:\n',syn1)

for j in range(60000):
	#forward
	l0 = X
	l1 = nonlin(np.dot(l0,syn0))

	#error
	l1_error = y-l1
	if j%10000 == 0:
		print( 'Error:', np.mean(np.abs(l1_error)) )
	#multiply error with the slope of the sigmoid. at values in l1
	l1_delta = l1_error*nonlin(l1,True)

#update wiehgts
	syn0 +=np.dot(l0.T,l1_delta)
print('Output after train:\n',l1)


