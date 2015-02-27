#===============================================================================
#Initial Checks and Imports
#===============================================================================

EnsurePythonVersion(2, 7)
EnsureSConsVersion(2, 2)

#Todo- create COM environment
#Create bin environment as well
#When ready to export to target, only export required modules for motherboard being targeted.
#Ditto with support programs (already compiled as well).

import struct
import os.path
import bios_utils
import re
import datetime

vars = Variables(['variables.cache', 'settings.py'])
vars.AddVariables( \
	PathVariable('NASM_DIR', 'Path to NASM dir (if not on standard SCons paths)', None), \
	EnumVariable('OUTPUT_FORMAT', 'BIOS Output Format (bin, Intel HEX, Motorola SREC)', 'bin', ('bin'))
	)

base_env = Environment(tools = ['nasm', tool_add_finalize], variables=vars) #We are using the custom NASM builder!
vars.Save('variables.cache', base_env)
Help(vars.GenerateHelpText(base_env))

if 'NASM_DIR' in base_env:
	base_env.AppendENVPath('PATH', base_env['NASM_DIR'])

base_env['PROGSUFFIX']='${OBJSUFFIX}' #This will be correct as long as we use "Master include file" format.
base_env['BINSUFFIX']='.${OUTPUT_FORMAT}'
base_env.Append(ASFLAGS = '-f${OUTPUT_FORMAT} -l${TARGET.base}.lst')
base_env.Append(ASPPDEFINES = [{'DATE_STAMP' : '\'' + datetime.date.today().strftime('%x') + '\''}])
bios_obj = base_env.Object('src/bios', 'src/main.asm')
bios_bin = base_env.Finalize('src/bios')


base_env.Clean(bios_obj, ['src/bios.lst', 'src/bios.bin', \
	'src/bios.ith', 'src/bios.srec'])

