#!/usr/bin/python

# Location of stard's home directory
stard_home = ''
# Location of the starmade directory (usually /var/starmade)
starmade_home = ''
# Location of the stard server directory
starmade_server = ''
# Hash of the stard config file
stard_config = dict()
# Hash of the starmade config file
starmade_config = dict()
# Put the command we are to run together when running stard commands.
starmade_cmd = list()
# Current level of debugging set
debug_level = 0
# The output of the last command run (used for debugging)
starmade_last_output = ''


## starmade_if_debug
# prints out the message if the debug_level is high enough.
# INPUT1: debug level of message
# INPUT2: message
def starmade_if_debug(level, message):
    if level <= debug_level:
        print message + "\n"

## starmade_setup_lib_env
# setup up basic variables for the stard library. 
# This tells the library where stard's home 
# folder is (by default /var/starmade/stard) but 
# we can't be sure so anyone who calls this 
# library needs to tell it where stard is located.
# INPUT1: location of stard home
def starmade_setup_lib_env(dir):
    stard_home = dir
    
    starmade_if_debug(2, "starmade_setup_lib_env(" + stard_home + ")")
    starmade_home = stard_home + "/.."
    starmade_server = starmade_home +"/StarMade"
    stard_setup_lib_env(stard_home)

    starmade_cmd.append("%JAVA%")
    starmade_cmd.append("-jar")
    starmade_cmd.append("$stard_home/" . get_stard_conf_field('stard_connect_cmd'))
    starmade_cmd.append(get_stard_conf_field('server')

    if get_stard_conf_field('password'):
        starmade_cmd.append(get_stard_conf_field('password'))
    else:
    	starmade_cmd.append(get_starmade_conf_field('SUPER_ADMIN_PASSWORD'))
    }
    starmade_if_debug(2, "starmade_setup_lib_env: return:")

## starmade_escape_chars
# Cleans up the given string to ensure that starmade handles it proporly. (no bobby tables :))
# INPUT: string to clean
# OUTPUT: cleaned up string.
def starmade_escape_chars(string):
    starmade_if_debug(2, "starmade_escape_chars(" + string+ ")")

    valid_chars = "abcdefghijklmnopqrstuvwxyz1234567890_/ \t@#%^&*()-+\[\].,<>?!\":;\{\}\(\)\*\&\^!"
    output = ''


        # starmade can't handle escaping in it's strings, so we just remove characters we are not sure of
    for char in string:
        if char in valid_chars:
            output += char

    starmade_if_debug(2, "starmade_escape_chars: return: " + output)
    return output

## starmade_validate_env
# validates that the starmade_setup_lib_env has been called, and we're setup ok.
def starmade_validate_env():
    if not starmade_home:
        "stard_home has not been set! the function starmade_setup_lib_env, with a valid stard_home needs to be called before any other functions in the starmade libraries";

## starmade_stdlib_set_debug
# Set the debug level for this library
# INPUT1: level to set debugging. (1 will print out inputs and outputs to all 
# functions except starmade_cmd, validate_env, and starnade_escape_chars). 
# Setting this to 2 will get you all functions input and output.
def starmade_stdlib_set_debug(debug):
    debug_level = debug
    starmade_if_debug(1, "set_debug(" + debug + ")")
    starmade_if_debug(1, "starmade_stdlib debugging set to " +debug + "!")

## starmade_cmd
# Runs a starmade command against the running starmade server
# INPUT1: (string) command to run against the server (should start with a /) in an array with any arguments desired
# OUTPUT: (array) newline delimited array of what the starmade server responded with.
def starmade_cmd(cmd, args):
    output = ()

    starmade_if_debug(2, "starmade_cmd(" + cmd + ")")
    starmade_validate_env()

    for entry in args:
	entry = starmade_escape_chars(entry)


    # fork a subprocess to launch the starmade command
    output = subprocess.check_output([ 'timeout',  get_stard_conf_field('connect_timeout')] + starmade_cmd + cmd)    

    starmade_if_debug(2, "starmade_cmd: return " + output)
    starmade_last_output = output
    return output


