package Starmade::Base;
use strict;
use warnings;
use Carp;
use Config::IniFiles;

use Stard::Base qw(stard_read_config get_stard_conf_field stard_setup_lib_env);

# This library should be used by perl based 
# plugins and internally by stard to talk to 
# the starmade deamon.
#
# NOTE the funtion starmade_setup_lib_env(PATH) needs to be called to use this library


require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT=qw(starmade_setup_lib_env starmade_escape_chars starmade_validate_env starmade_stdlib_set_debug starmade_if_debug starmade_cmd get_starmade_home get_server_home starmade_last_output starmade_read_starmade_server_config starmade_get_starmade_conf_field get_starmade_conf_field);


## Global settings
# Location of stard's home directory
my $stard_home;
# Location of the starmade directory (usually /var/starmade)
my $starmade_home;
# Location of the stard server directory
my $starmade_server;
# Hash of the stard config file
my %stard_config;
# Hash of the starmade config file
my %starmade_config;
# Put the command we are to run together when running stard commands.
my @starmade_cmd;
# Current level of debugging set
my $debug_level = 0;
# The output of the last command run (used for debugging)
my $starmade_last_output;



## starmade_setup_lib_env
# setup up basic variables for the stard library. 
# This tells the library where stard's home 
# folder is (by default /var/starmade/stard) but 
# we can't be sure so anyone who calls this 
# library needs to tell it where stard is located.
# INPUT1: location of stard home
sub starmade_setup_lib_env {
	$stard_home = $_[0];

	starmade_if_debug(2, "starmade_setup_lib_env($stard_home)");
	$starmade_home = "$stard_home/..";
	$starmade_server = "$starmade_home/StarMade";
	stard_setup_lib_env($stard_home);
	@starmade_cmd = ();

	push(@starmade_cmd, "/usr/bin/java", "-jar");
	push(@starmade_cmd, "$stard_home/" . get_stard_conf_field('stard_connect_cmd'));
	push(@starmade_cmd, get_stard_conf_field('server'));
	if (defined get_stard_conf_field('password') && get_stard_conf_field('password') =~/\S/) {
		push(@starmade_cmd, get_stard_conf_field('password'));
	}
	else {
		push(@starmade_cmd, get_starmade_conf_field('SUPER_ADMIN_PASSWORD'));
	}	
	starmade_if_debug(2, "starmade_setup_lib_env: return:");
};

## starmade_escape_chars
# Cleans up the given string to ensure that starmade handles it proporly. (no bobby tables :))
# INPUT: string to clean
# OUTPUT: cleaned up string.
sub starmade_escape_chars {
	my $string = $_[0];

	starmade_if_debug(2, "starmade_escape_chars($string)");
	my @chars = split("",$string);

	my $valid_chars = "abcdefghijklmnopqrstuvwxyz1234567890_/ \t@#%^&*()-+\[\].,<>?!\":;\{\}\(\)\*\&\^!";
	my $output = '';


	foreach my $char (@chars) {
		if ($valid_chars=~/\Q$char\E/i) {
			$output .= $char;
		}
		# starmade can't handle escaping in it's strings, so we just remove characters we are not sure of
	};
	$output = "'$output'";
	starmade_if_debug(2, "starmade_escape_chars: return: $output");
	return $output;
};

## starmade_validate_env
# validates that the starmade_setup_lib_env has been called, and we're setup ok.
sub starmade_validate_env {
	if (! ($starmade_home =~/\S/)) {
		croak("stard_home has not been set! the function starmade_setup_lib_env, with a valid stard_home needs to be called before any other functions in the starmade libraries");
	}
}

## starmade_stdlib_set_debug
# Set the debug level for this library
# INPUT1: level to set debugging. (1 will print out inputs and outputs to all 
# functions except starmade_cmd, validate_env, and starnade_escape_chars). 
# Setting this to 2 will get you all functions input and output.
sub starmade_stdlib_set_debug {
	my $debug = $_[0];
	$debug_level = $debug;
	starmade_if_debug(1, "set_debug($debug)");
	starmade_if_debug(1, "starmade_stdlib debugging set to $debug!");
}

## starmade_if_debug
# prints out the message if the debug_level is high enough.
# INPUT1: debug level of message
# INPUT2: message
sub starmade_if_debug {
	my $level = $_[0];
	my $message = $_[1];
	if ($level <= $debug_level) {
		print $message;
		print "\n";
	}
}


## starmade_cmd
# Runs a starmade command against the running starmade server
# INPUT1: (string) command to run against the server (should start with a /)
# OUTPUT: (array) newline delimited array of what the starmade server responded with.
sub starmade_cmd {
	my $cmd = shift(@_);
	my @args = @_;

	my @output;

	if (@args) {
		starmade_if_debug(2, "starmade_cmd($cmd, " . join(", ", @args) . ")");
	}
	else {
		starmade_if_debug(2, "starmade_cmd($cmd)");
	}

	starmade_validate_env();

	foreach my $entry (@args) {
		$entry = starmade_escape_chars($entry);
	};

	# fork a subprocess to launch the starmade command
	pipe(READ, WRITE);
	my $child = fork();
	if ($child) {
		close(WRITE);
		@output = <READ>;
	}
	else {
		close(READ);
		open(STDOUT, ">&", \*WRITE) or die "$!";
		open(STDERR, ">&", \*WRITE) or die "$!";

		exec("timeout", get_stard_conf_field('connect_timeout'), @starmade_cmd, $cmd, @args );
	}
	

	starmade_if_debug(2, "starmade_cmd: return @output");
	$starmade_last_output = join("", @output);
	return @output;
};



## get_server_home
# Output: path to starmade server
sub get_server_home {
	return $starmade_server;
}

## starmade_last_output
# Get the last recorded output from the starmade server. Usefull if you don't know why 
# a command failed
# OUTPUT: (string) output of last run command
sub starmade_last_output {
	return $starmade_last_output;
}


## starmade_read_server_config
# Get the curent starmade config file in hash format
# OUTPUT: hash of starmade config file
sub starmade_read_server_config {

	starmade_if_debug(2, "starmade_read_server_config()");
	starmade_validate_env();
	my %config;
	open(my $config_fh, "<", "$starmade_server/server.cfg");
	my @lines = <$config_fh>;
	close($config_fh);
	Line: foreach my $line (@lines) {
		if ($line =~/\/\//) {
			my @tmp = split("\/\/", $line);
			$line = $tmp[0];
		}
		if ($line=~/^(\S+)\s+=(.*)/) {
			my $field = $1;
			my $value = $2;
			# trim out any whitespace at the beginning or end
			$field=~s/^\s+//ig;
			$field=~s/\s+$//ig;
			$value=~s/^\s+//ig;
			$value=~s/\s+$//ig;
			
			$config{$field} = $value;
			$config{$field}=~s/^\s+//g;
			starmade_if_debug(2, "starmade_read_server_config: return(multiline): %HASH{$field} = $value");
		};
	};
	return \%config;
};

## get_starmade_conf_field
# get a specific field from the stard.cfg file
# INPUT1: field to grab
# OUTPUT: value of field
sub get_starmade_conf_field {
	my $field = $_[0];

	if (!%starmade_config) {
		%starmade_config = %{starmade_read_server_config()};
	}

	starmade_if_debug(1, "get_starmade_conf_field($field)");
	starmade_validate_env();
	starmade_if_debug(1, "get_starmade_conf_field: return: $starmade_config{$field}");
	return $starmade_config{$field};
}

1;
