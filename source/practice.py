d_file = open('first_etb_align.txt')

data_packet = d_file.read()
print(data_packet[0:36])
print(data_packet[0:9])

d_file = open('first_etb_align.txt')	

line = 0

row_count = 0
col_count = 0
Synchronized= 0
row_hexdec = [0,0,0,0]
row_bin = [0,0,0,0]

address = 0

for line in d_file:

	row_count = row_count + 1

	line = line.rstrip()

	hexdec = line
	dec = int(hexdec,16)
	line_bin_packet = bin(dec)

	if row_count < 5:
		print(row_count,hexdec,line_bin_packet)
	for i in range(0,4):
		row_hexdec[i] = hexdec[2*i:2*i+2]
		if row_count <5:
			print(row_hexdec[i])
			if i == 3:
				print('\n')


################################################
def newline():
	global row_count, hexdec, row_hexdec, row_bin

	hexdec = data_packet[row_count*9:row_count*9+9]
	print('New Line Function')
	print(row_count,hexdec)

	for i in range(0,4):
		row_hexdec[i] = hexdec[2*i:2*i+2]
		dec = int(row_hexdec[i],16)
		row_bin[i] = bin(dec)
		print(row_hexdec[i],row_bin[i])
	row_count = row_count + 1
		
def Async():
	global row_count, col_count, row_bin, row_hexdec, address
	header = 1
	counter = 0
	print('Async Function')
	while True:
		if header == 1: #Header
			if col_count == 3:
				col_count = 0
				newline()
				header = 0
			else:
				col_count = col_count + 1
				header = 0

			counter = counter + 1

		else:
			if counter < 5: #Address
				address[8-2*counter+1] = row_hexdec[1]
				address[8-2*counter] = row_hexdec[0]
			elif counter == 5:
				print('happy')
				

def BranchAddr():
	global row_count, col_count, row_bin, row_hexdec, address, CPU_state
	header = 1
	counter = 0
	print('Branch Address Funciton')

	while True:
		if CPU_state == 0: #Jazelle
			address
		elif CPU_state == 1: #ARM
		elif CPU_state == 2: #Thumb

#################################################
CPU_state = 0
Synchronized= 0
row_hexdec = [0,0,0,0]
row_bin = [0,0,0,0]

row_count = 0
col_count = 0
address = [0]*8

newline()

if row_bin[col_count] == 0b00000000:
	Async()
elif row_bin[col_count] == 0b00001000:
	Isync()
else:
	print('done')



