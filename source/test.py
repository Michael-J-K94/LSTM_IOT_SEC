
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
wp_addr = [0 for x in range(32)]
context = [0 for x in range(32)]
exception = [0 for x in range(9)]


################################################
def num_to_CPUstate(x):
	if x == 0:
		return 'ARM'
	elif x == 1:
		return 'Thumb'
	elif x == 2:
		return 'Jakelle'
	else:
		return 'wrong input'

def addr_to_hex(list):
	addr_temp = [0 for x in range(32)]
	for k in range(32):
		addr_temp[k] = list[31-k]

	temp = list_to_bin(addr_temp)
	
	# print('addr_to_hex DONE')
	# print('return:', hex( int(temp,2) ) )
	return hex( int(temp,2) )
def list_to_bin(list):
	# print('list_to_bin Function')
	num = 0

	for b in list:
		num = 2*num + b
	# print(bin(num))
	# print('Funciton DONE')
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

	print(list_to_bin(bin_1B[c_cnt]), '(',hex_4B[c_cnt],')')
################################################
def newLine():
	global r_cnt, hex_4B, bin_1B
	dec = [0]*2
	# print('New Line Function')
	# print('r_cnt:',r_cnt,' 8byte hex:',data_packet[r_cnt*9:r_cnt*9+8])
	for i in range(4):
		hex_4B[i][1] = data_packet[r_cnt*9+2*i+1]
		hex_4B[i][0] = data_packet[r_cnt*9+2*i]
	 	# print(hex_4B[i],end='')
		# print(hex_4B[i][0],hex_4B[i][1])

	# print('\n',end='')

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
	
		# print(bin_1B[i],end='')


	# print('\nNEW LINE Function END \n')
	r_cnt = r_cnt + 1
################################################
def Async():
	global c_cnt, bin_1B, Synched
	counter = 0
	
	while True:
		##CHECKING FOR LAST ROW
		if list_to_bin(bin_1B[c_cnt]) == '0b10000000': 
			Synched = 1
			return ## MIND THE FACT THAT THIS IS NOT 'break', BUT 'return'
		newByte()
################################################		
def Isync():
	global c_cnt, bin_1B, CPU_state, addr
	counter = 0
	
	while True:
		##HEADER
		if counter == 0:
			counter = counter + 1
		##ADDRESS
		elif counter < 5:		
			if counter == 1:
				for j in range(7):
					addr[j+1] = bin_1B[c_cnt][6-j]

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
				context[8*(counter-6)+j] = bin_1B[c_cnt][7-j]
			print('(context: ',addr_to_hex(context),')')
			counter = counter + 1

			if counter == 10:
				break


		newByte()
	
	if Synched == 0:
		print('?',end='')
	
	print('Isync  Context:',addr_to_hex(context),'Addr:',addr_to_hex(addr),num_to_CPUstate(CPU_state),'\n')
	newByte()
################################################
def	BranchAddr():
	global c_cnt, bin_1B, CPU_state, addr
	counter = 0
	exceptioned = 0
	# print('BranchAddr Function')
	
	while True:
		##ARM STATE
		if CPU_state == 0:
		
			if counter == 0:
				for j in range(6):
					addr[2+j] = bin_1B[c_cnt][6-j]
				print('addr:',addr_to_hex(addr))		
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
					break
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+8+j] = bin_1B[c_cnt][7-j]
				print('addr:',addr_to_hex(addr))
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 4:
				addr[31] = bin_1B[c_cnt][5]
				addr[30] = bin_1B[c_cnt][6]
				addr[29] = bin_1B[c_cnt][7]
				print('addr',addr_to_hex(addr))
				if bin_1B[c_cnt][1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				exceptioned = 1
				if bin_1B[c_cnt][0] == 1:
					for j in range(4):
						exception[j] = bin_1B[c_cnt][6-j]
					counter = counter + 1
				else:
					break
			elif counter == 6:
				for j in range(5):
					exception[4+j] = bin_1B[c_cnt][7-j]
				break
			
			newByte()
			
		##THUMB STATE
		elif CPU_state == 1:
		
			if counter == 0:
				for j in range(6):
					addr[1+j] = bin_1B[c_cnt][6-j]
				print('addr',addr_to_hex(addr))
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
				 	break
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+7+j] = bin_1B[c_cnt][7-j]
				print('addr',addr_to_hex(addr))
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
				 	break
			elif counter == 4:
				addr[31] = bin_1B[c_cnt][4]
				addr[30] = bin_1B[c_cnt][5]
				addr[29] = bin_1B[c_cnt][6]
				addr[28] = bin_1B[c_cnt][7]
				print('addr',addr_to_hex(addr))
				if bin_1B[1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				exceptioned = 1
				if bin_1B[0] == 1:
					for j in range(4):
						exception[j] = bin_1B[c_cnt][6-j]
					counter = counter + 1
				else:
					break
			elif counter == 6:
				for j in range(5):
					exception[4+j] = bin_1B[c_cnt][7-j]
				break

			newByte()
	
		##JAZELLE STATE
		elif CPU_state == 2:
			# print('JAZELLE STATE, counter:',counter)
		
			if counter == 0:
				for j in range(6):
					addr[j] = bin_1B[c_cnt][6-j]
					
				print('addr:',addr_to_hex(addr))		
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
					break
			elif counter < 4:
				for j in range(7):
					addr[7*(counter-1)+6+j] = bin_1B[c_cnt][7-j]
				print('addr:',addr_to_hex(addr))
				if bin_1B[c_cnt][0] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 4:
				# print('counter == 4')
				addr[31] = bin_1B[c_cnt][3]
				addr[30] = bin_1B[c_cnt][4]
				addr[29] = bin_1B[c_cnt][5]
				addr[28] = bin_1B[c_cnt][6]
				addr[27] = bin_1B[c_cnt][7]
				print('addr:',addr_to_hex(addr))			 
				if bin_1B[1] == 1:
					counter = counter + 1
				else:
					break
			elif counter == 5:
				exceptioned = 1
				if bin_1B[0] == 1:
					for j in range(4):
						exception[j] = bin_1B[c_cnt][6-j]
					counter = counter + 1
				else:
					break
			elif counter == 6:
				for j in range(5):
					exception[j] = bin_1B[c_cnt][7-j]
				break
			
			newByte()
	
	if Synched == 0:
		print('?',end='')

	print('Branch',addr_to_hex(addr),end='')
	if exceptioned == 1:
		print('Exception data',addr_to_hex(exception),end='')
	print('CPU_state:',CPU_state,'\n')	
	# print('BranchAddr DONE')

	newByte()
################################################
def Atom():
	global c_cnt, bin_1B, CPU_state, addr
	counter = 0
	
	if Synched == 0:
		print('?',end='')
	print('Atom\n')
	
	newByte()
################################################
def Waypoint():
	global c_cnt,bin_1B,CPU_state,addr
	counter = 0
	
	while True:
		## ARM STATE
		if CPU_state == 0:
			if counter == 0:
				counter = counter + 1
			elif counter == 1:
				for j in range(6):
					wp_addr[2+j] = bin_1B[c_cnt][6-j]
				if bin_1B[c_cnt][0] == 0:
					break
				else:
					counter = counter + 1
			elif counter < 5:
				for j in range(7):
					wp_addr[7*(counter-2)+8+j] = bin_1B[c_cnt][7-j]
				if bin_1B[c_cnt][0] == 0:
					break
				else:
					counter = counter + 1
			elif counter == 5:
				for j in range(3):
					wp_addr[29+j] = bin_1B[c_cnt][7-j]
				if bin_1B[c_cnt][1] == 0:
					break
				else:
					counter = counter + 1
			elif counter == 6:
				break
		## Thumb State	
		elif CPU_state == 1:
			if counter == 0:
				counter = counter + 1
			elif counter == 1:
				for j in range(6):
					wp_addr[j] = bin_1B[c_cnt][6-j]
				if bin_1B[c_cnt][0] == 0:
					break
				else:
					counter = counter + 1
			elif counter < 5:
				for j in range(7):
					wp_addr[7*(counter-1) + j] = bin_1B[c_cnt][7-j]
				if bin_1B[c_cnt][0] == 0:
					break
				else:
					counter = counter + 1
			elif counter == 5:
				for j in range(4):
					wp_addr[28+j] = bin_1B[c_cnt][7-j]
				if bin_1B[c_cnt][1] == 0:
					break
				else:
					counter = counter + 1
			elif counter == 6:
				break
			  
		newByte()
	print('Waypoint',addr_to_hex(wp_addr),num_to_CPUstate(CPU_state))
	newByte()
################################################
print('\n\n\n ***** STARTING MAIN FUNCTION ***** \n')

newLine()
c_cnt = 0
print(list_to_bin(bin_1B[c_cnt]), '(',hex_4B[c_cnt],')')

waypoint_number = [[0,0] for x in range(30)]
wp_idx = 0
async_number = [0,0]

for i in range(1200):
	# print('*** INSIDE MAIN LOOP *** \n\n')

	if list_to_bin(bin_1B[c_cnt]) == '0b0':
		async_number = [r_cnt,c_cnt]
		print('\n\n\n\n\n\n\n\n\n\n\n\n\n *************** ASYNC FOUND ****************** \n\n\n\n\n\n\n\n\n')
		print('** ASYNC')
		Async()
		
	elif list_to_bin(bin_1B[c_cnt]) == '0b1000':
		print('** ISYNC')
		Isync()
		
	elif bin_1B[c_cnt][7] == 1:
		print('** BRANCH ADDRESS')
		BranchAddr()
	
	elif (bin_1B[c_cnt][0] == 1 and bin_1B[c_cnt][7] == 0):
		print('** ATOM')
		Atom()
	elif list_to_bin(bin_1B[c_cnt]) == '0b1110010':
		waypoint_number[wp_idx][0] = r_cnt
		waypoint_number[wp_idx][1] = c_cnt
		wp_idx = wp_idx+1
		print('** WAYPOINT UPDATE')
		Waypoint()
	else:
		print('WTF ?????')

if Synched == 1:
	print('Async Happened')
else:
	print('Async NOT Happened')
print('async_number:',async_number)
print('\n\n\n', 'for loop done')
print('waypoin_number:',waypoint_number)
























