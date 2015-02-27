import struct
import datetime


def tool_add_finalize(env):
	finalize_bld = Builder(action = finalize_ROM, \
		suffix = '$BINSUFFIX', src_suffix = '$PROGSUFFIX', \
		single_source=True) 
	#env['ROMSIZE'] = 16
	#env['JUMP_FARPTR'] = '0xF000E05B'
	#env['BINSUFFIX'] = '.bin'
	#env['ADD_LAST_16B'] = True #Eventually turn into string.
	env.Append(BUILDERS = {'Finalize' : finalize_bld})

def finalize_ROM(target, source, env):
	with open(str(source[0]), 'rb') as fp:
		progdata = fp.read()
	progdata_len = len(progdata)
	
	final_data = progdata
	#if env['ADD_LAST_16B']:
	#	missing_bits = 16
	#else:
	#	missing_bits = 0
	#
	#if progdata_len > (env['ROMSIZE']*1024 - missing_bits):
	#	return 1	
	#	
	#pad_byte_len = env['ROMSIZE']*1024 - missing_bits - progdata_len
	#
	##'\xEA\x5B\x00\x00\xFE, Date, Sig, Checksum'
	#final_data = ''.join([progdata, pad_byte_len * chr(255), '\xEA', \
	#	struct.pack('<I', int(env['JUMP_FARPTR'], 16)), \
	#	datetime.date.today().strftime('%x'), \
	#	'CR']) #My handle here (CR1901), because why not?
	
	chksum = 0
	for i in final_data:
		chksum += ord(i)
	
	#If doing binary output. Just append the checksum to a new file
	with open(str(target[0]), 'wb') as fp:
		fp.write(final_data)
		fp.seek(-1, 1)
		fp.write(chr(256 - (chksum%256)))
		
	#For Intel HEX and SREC, create manually (unfortunately, thanks to appending
	#checksum ahead of time).
		
	return 0
