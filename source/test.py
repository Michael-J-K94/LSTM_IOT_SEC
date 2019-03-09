
d_file = open('first_etb_align.txt')
data_packet = d_file.read()

print(data_packet[0:72])


################################################
CPU_state = 2
Synched = 0

hex_4B = [[0 for x in range(2)] for y in range(4)]
bin_1B = [[0 for x in range(8)] for y in range(4)]

r_cnt = 0
c_cnt = 0

addr = [0 for x in range(32)]


################################################
def addr_to_hex(list):
	addr_temp = [0 for x in range(32)]
	for k in range(32):
		addr_temp[k] = addr[31-k]

	temp = list_to_bin(addr_temp)
	
	print('addr_to_hex DONE')
	print('return:', hex( int(temp,2) ) )
	return hex( int(temp,2) )
def list_to_bin(list):
	print('list_to_bin Function')
	num = 0

	for b in list:
		num = 2*num + b
	print(bin(num))
	print('Funciton DONE')
	return bin(num)
################################################
def newByte():
	global c_cnt
	
	## ROW CHANGE
	if c_cnt == 3:
		c_cnt = 0
		newLine()
	else:
		c_cnt = c_cnt + 1
################################################
def newLine():
	global r_cnt, hex_4B, bin_1B
	dec = [0]*2
	print('New Line Function')
	print('r_cnt:',r_cnt,' , '8byte hex:',data_packet[r_cnt*9:r_cnt*9+8]')
	for i in range(4):
		hex_4B[i][1] = data_packet[r_cnt*9+2*i+1]
		hex_4B[i][0] = data_packet[r_cnt*9+2*i]
		print('hex_4B[',i,']: ',hex_4B[i],end='')
		# print(hex_4B[i][0],hex_4B[i][1])
	
	for i in range(4):
		dec[0] = int(hex_4B[i][0],16)	
		dec[1] = int(hex_4B[i][1],16)

		# print(bin(dec[0]), bin(dec[1]))
		# print('cnt:',len(bin(dec[0])),len(bin(dec[1])))
		cnt0 = len(bin(dec[0]))
		cnt1 = len(bin(dec[1]))

		if cnt0 == 6:
			for j in range(4):
				bin_1B[i][j] = int( str(bin(dec[0]))[2+j] )
		else:
			for j in range(6-cnt0):
				bin_1B[i][j] = 0
			for j in range(cnt0-2):
				bin_1B[i][6-cnt0+j] = int( str(bin(dec[0]))[2+j] )
			
		if cnt1 == 6:
			for j in range(4):
				bin_1B[i][4+j] = int( str(bin(dec[1]))[2+j] )
		else:
			for j in range(6-cnt1):
				bin_1B[i][4+j] = 0
			for j in range(cnt1-2):
				bin_1B[i][6-cnt1+4+j] = int( str(bin(dec[1]))[2+j] )
	
		print(bin_1B[i])


	print('Function END \n')
	r_cnt = r_cnt + 1
################################################
def Async():
	global c_cnt, bin_1B, Synched
	counter = 0
	print('Async Function')
	
	while True:
		##CHECKING FOR LAST ROW
		if bin_1B[c_cnt] == [1,0,0,0,0,0,0,0,0]: 
			break
		newByte()
			
	newByte()
	Synched = 1
	print('Async DONE','\n')
################################################		
def Isync():
	global c_cnt, bin_1B, CPU_state, addr
	counter = 0
	print('Isync Function')
	
	while True:
		##HEADER
		if counter == 0:
			counter = counter + 1
		##ADDRESS
		elif counter < 5:		
			if counter == 1:
				for j in range(7):
					addr[j] = bin_1B[c_cnt][7-j]
				if bin_1B[c_cnt][7] == 0:
					CPU_state = 0 #ARM STATE
				else:
					CPU_state = 1 #THUMB STATE		
				counter = counter + 1	
			else:
				for j in range(8):
					addr[(counter-1)*8+j] = bin_1B[c_cnt][7-j]
				counter = counter + 1
		##INFORMATION BYTE
		elif counter == 5:
			counter = counter + 1
		##CONTEXT
		elif counter < 10:
			for j in range(8):
				addr[(counter-6)*8+j] = bin_1B[c_cnt][7-j]
			counter = counter + 1
			if counter == 9:
				break
		newByte()
			
	newByte()
	print('Isync DONE','\n')
################################################
def	BranchAddr():
	global c_cnt, bin_1B, CPU_state, addr
	counter = 0
	print('BranchAddr Function')
	
	while True:
		##ARM STATE
		if CPU_state == 0:
		
			if counter == 0:
				for j in range(6):
					addr[2+j] = bin_1B[c_cnt][6-j]
				counter = counter + 1
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+8+j] = bin_1B[c_cnt][7-j]
				counter = counter + 1
			elif counter == 4:
				addr[31] = bin_1B[c_cnt][5]
				addr[30] = bin_1B[c_cnt][6]
				addr[29] = bin_1B[c_cnt][7]
				if bin_1B[1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				if bin_1B[0] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 6:
				break
			
			newByte()
			
		##THUMB STATE
		elif CPU_state == 1:
		
			if counter == 0:
				for j in range(6):
					addr[1+j] = bin_1B[c_cnt][6-j]
				counter = counter + 1
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+7+j] = bin_1B[c_cnt][7-j]
				counter = counter + 1
			elif counter == 4:
				addr[31] = bin_1B[c_cnt][4]
				addr[30] = bin_1B[c_cnt][5]
				addr[29] = bin_1B[c_cnt][6]
				addr[28] = bin_1B[c_cnt][7]
				if bin_1B[1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				if bin_1B[0] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 6:
				break

			newByte()
	
		##JAZELLE STATE
		elif CPU_state == 2:
			print('JAZELLE STATE, counter:',counter)
		
			if counter == 0:
				for j in range(6):
					addr[j] = bin_1B[c_cnt][6-j]
				counter = counter + 1
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+6+j] = bin_1B[c_cnt][7-j]
				counter = counter + 1
			elif counter == 4:
				print('counter == 4')
				addr[31] = bin_1B[c_cnt][3]
				addr[30] = bin_1B[c_cnt][4]
				addr[29] = bin_1B[c_cnt][5]
				addr[28] = bin_1B[c_cnt][6]
				addr[27] = bin_1B[c_cnt][7]				
				if bin_1B[1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				if bin_1B[0] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 6:
				break
			
			newByte()
	
	print('addr:',addr_to_hex(addr), '\n')			 
	newByte()
	print('BranchAddr DONE')		

################################################
print('\n\n\n ***** STARTING MAIN FUNCTION ***** \n')

newLine()
c_cnt = 0
for i in range(4):
	print('*** INSIDE MAIN LOOP *** \n\n')
	
	if list_to_bin(bin_1B[c_cnt]) == 0b00000000:
		Async()
		
	elif list_to_bin(bin_1B[c_cnt]) == 0b00001000:
		Isync()
		
	elif bin_1B[c_cnt][7] == 1:
		print('inside branch addr loop \n')
		BranchAddr()
		
	print('\n','**** NO MATCH ****','\n')
		
print('\n\n\n', 'for loop done')
























