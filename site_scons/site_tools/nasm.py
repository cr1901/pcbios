#Custom builder for NASM- The default-provided builder isn't exceptionally powerful.
#It won't even accept a custom scanner for whatever reason!

#Python includes
import re
import os.path

#SCons includes
import SCons.Defaults
import SCons.Scanner
import SCons.Tool

#Taken from NASM builder
ASSuffixes = ['.s', '.asm', '.ASM']
ASPPSuffixes = ['.spp', '.SPP', '.sx']
if SCons.Util.case_sensitive_suffixes('.s', '.S'):
	ASPPSuffixes.extend(['.S'])
else:
	ASSuffixes.extend(['.S'])

#Custom scanner
#http://stackoverflow.com/questions/4798149/ignore-comments-using-sed-but-keep-the-lines-untouched
nasm_include_re = re.compile(r'\%include\s+\'(\S+)\'', re.M)

def nasm_inc_scan(node, env, path, arg):
	contents = node.get_text_contents()
	includes = nasm_include_re.findall(contents)
	#print includes
	if includes == []:
		return []
	results = []
	for inc in includes:
		for dir in path:
			file = str(dir) + os.sep + inc
			if os.path.exists(file):
				results.append(file)
				break
	return env.File(results)

#Copied from Borland builder
def findIt(program, env):
    # First search in the SCons path and then the OS path:
    progpath = env.WhereIs(program) or SCons.Util.WhereIs(program)
    if progpath:
        dir = os.path.dirname(progpath)
        env.PrependENVPath('PATH', dir)
    return progpath	


#Modified from SCons.Tool.createProgBuilder- we add an extra Action to generate
#a linkfile! Possible improvement: Use the env.Textfile builder and just have
#Textfile be the source builder for linking?
def createNASMProgBuilder(env):
	pass
	"""This is a utility function that creates the Program
	Builder in an Environment if it is not there already.
	 
	If it is already there, we return the existing one.
	"""
	 
	"""try:
		program = env['BUILDERS']['Program']
	except KeyError:
		import SCons.Defaults
		program = SCons.Builder.Builder(action = 
		[SCons.Action.Action(create_linkfile, "Creating linkfile for $TARGET ..."),
		SCons.Action.Action("$LINKCOM", "$LINKCOMSTR")],
			emitter = '$PROGEMITTER',
			prefix = '$PROGPREFIX',
			suffix = '$PROGSUFFIX',
			src_suffix = '$OBJSUFFIX',
			src_builder = 'Object',
		target_scanner = SCons.Tool.ProgramScanner)
		env['BUILDERS']['Program'] = program
	return program"""


def generate(env):
	findIt('nasm', env)
	
	scan_nasm = SCons.Scanner.Scanner(function = nasm_inc_scan, argument = None, path_function=SCons.Scanner.FindPathDirs('ASPPPATH'))
	SCons.Tool.SourceFileScanner.add_scanner('.asm', scan_nasm)
	static_obj, shared_obj = SCons.Tool.createObjBuilders(env)
	
	for suffix in ASSuffixes:
		static_obj.add_action(suffix, SCons.Defaults.ASAction)
		static_obj.add_emitter(suffix, SCons.Defaults.StaticObjectEmitter)
	
	"""for suffix in ASPPSuffixes:
		static_obj.add_action(suffix, SCons.Defaults.ASPPAction)
		static_obj.add_emitter(suffix, SCons.Defaults.StaticObjectEmitter)"""
        createNASMProgBuilder(env)
        
        env['_ASPPINCFLAGS'] = '${_concat(\'-i\', ASPPPATH, \'/\', __env__, RDirs, TARGET, SOURCE)}',
        env['_ASPPDEFFLAGS'] = '${_defines(\'-d\', ASPPDEFINES, None, __env__)}'
        
	env['AS'] = 'nasm'
	env['_ASCOMCOM'] = '$_ASPPDEFFLAGS $_ASPPINCFLAGS'
	env['ASCOM'] = '$AS $ASFLAGS $_ASCOMCOM -o $TARGET $SOURCES'
	env['ASPPPATH'] = ''
	env['ASPPDEFINES'] = ''
	env['ASFLAGS'] = ''
	

def exists(env):
    return env.Detect('nasm')

