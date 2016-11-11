
import ConfigParser


exec_prefix_table['perl'] = "%PERL%";
exec_prefix_table['bash'] = "%BASH%";
exec_prefix_table['python'] = "%PYTHON%";

stard_home = ""
stard_log = ""
stard_plugins=""
stard_plugin_log = ""
stard_config = dict()
debug_level = 0



## stard_setup_lib_env
# setup up basic variables for the stard core library.
# This tells the library where stard's home 
# folder is (by default /var/starmade/stard but 
# we can't be sure so anyone who calls this 
# library needs to tell it where stard is located.
# INPUT1: location of stard home
def stard_setup_lib_env(dir):
    stard_home = dir

    stard_plugins = stard_home + "/plugins"
    stard_log = stard_home + "/log"
    stard_plugin_log = stard_log + "/plugins"
    stdout_log("stard_core setup. Found stard home: '" + stard_home + "'", 6)

## stard_lib_validate_env
# validates that the setup_core_run_env has been called, and we're setup ok.
def stard_lib_validate_env():
    if not stard_home:
        print "stard_home has not been set! the function stard_setup_core_env, with a valid stard_home needs to be called before any other functions in the stard_stdlib"


## stard_if_debug
# prints out the message if the debug_level is high enough.
# INPUT1: debug level of message
# INPUT2: message
def stard_if_debug(level, message):

    if level <= debug_level:
        print message
        print "\n"

## get_exec_prefix
# Get the first line in a file, and use it as an executable
# INPUT1: executable
# OUTPUT: command to launch with
def get_exec_prefix(exec):

    exec_prefix = ""

    # grab first line of the file (the exec prefix)
    fh = open(exec, 'r')
    prefix = fh.readline()
    fh.close()

    #compare against 
    search = re.search("#!(.*)\n", prefix
    if search:
	exec_prefix = search.group(0)
	if exec_prefix_table[exec_prefix]:
	    return exec_prefix_table[exec_prefix];
	else:
	    return exec_prefix;
	return

## stard_read_config
# Used to read ini stype config files
# INPUT1: location of config file
# OUTPUT: 2d hash of config file contents
def stard_read_config(file):

	stard_if_debug(2, "stard_read_config(" + file + ")");
	config = dict()
	if (!tie(%config, 'Config::IniFiles', ( -file => $file))) {
		foreach my $line (@Config::IniFiles::errors) {
			warn $line;
		}
		stard_if_debug(2, "stard_read_config: return: ()");
		return \%blank_hash;
	}


	foreach my $key1 (keys %config) {
		if ($debug_level >= 2) {
			print "stard_read_config: return(multiline): [$key1]\n";
		}
		foreach my $key2 (keys %{$config{$key1}}) {
			if ($debug_level >= 2) {
				print "stard_read_config: return(multiline): $key2 = '$config{$key1}{$key2}'\n";
			}
			$config{$key1}{$key2}=~s/^\s+//g;
			$config{$key1}{$key2}=~s/\s+$//g;
			$config{$key1}{$key2}=~s/^'//;
			$config{$key1}{$key2}=~s/'$//;
			$config{$key1}{$key2}=~s/^"//;
			$config{$key1}{$key2}=~s/"$//;
		}
	}
	return \%config;
};

        
