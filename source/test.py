
d_file = open('first_etb_align.txt')
data_packet = d_file.read()

print(data_packet[0:72])


################################################
CPU_state = 0
Synched = 0

hex_4B = [[0 for x in range(2)] for y in range(4)]
bin_1B = [[0 for x in range(8)] for y in range(4)]

r_cnt = 0
c_cnt = 0

addr = [0 for x in range(8)]


################################################
def newline():
	global r_cnt, hex_4B, bin_1B
	dec = [0]*2
	print('New Line Function')
	
	for i in range(4):
		hex_4B[i][1] = data_packet[r_cnt*9+2*i+1]
		hex_4B[i][0] = data_packet[r_cnt*9+2*i]
		print('hex_4B[',i,']: ',hex_4B[i])
		print(hex_4B[i][0],hex_4B[i][1])
	
	for i in range(4):
		dec[0] = int(hex_4B[i][0],16)	
		dec[1] = int(hex_4B[i][1],16)

		print(bin(dec[0]), bin(dec[1]))
		print('cnt:',len(bin(dec[0])),len(bin(dec[1])))
		cnt0 = len(bin(dec[0]))
		cnt1 = len(bin(dec[1]))

		if cnt0 == 6:
			for j in range(4):
				bin_1B[i][j] = str(bin(dec[0]))[2+j]
		else:
			for j in range(6-cnt0):
				bin_1B[i][j] = 0
			for j in range(cnt0-2):
				bin_1B[i][6-cnt0+j] = str(bin(dec[0]))[2+j]
			
		if cnt1 == 6:
			for j in range(4):
				bin_1B[i][4+j] = str(bin(dec[1]))[2+j]
		else:
			for j in range(6-cnt1):
				bin_1B[i][4+j] = 0
			for j in range(cnt1-2):
				bin_1B[i][6-cnt1+4+j] = str(bin(dec[1]))[2+j]
	
		print(bin_1B[i])


	print('Function END')
	r_cnt = r_cnt + 1

################################################
newline()
newline()
newline()
newline()
newline()









