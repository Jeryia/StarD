package Stard::Base;
use strict;
use warnings;
use Cwd;
use Text::ParseWords;
use Proc::Daemon;
use POSIX;

use lib("./lib");

use Stard::Log;

#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# StarMade™ is a registered trademark of Schine GmbH (All Rights Reserved)*
# The makers of stard make no claim of ownership or relationship with the owners of StarMade

## Core libraries for stard.
# This provides the primary functionality for stard to function.
# NOTE: This library requires stard_lib.pm

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(stard_read_config get_stard_conf_field stard_setup_lib_env stard_lib_validate_env get_exec_prefix get_stard_home get_stard_plugins_dir get_stard_plugins_log);


my %exec_prefix_table;
$exec_prefix_table{perl} = "%PERL%";
$exec_prefix_table{bash} = "%BASH%";
$exec_prefix_table{python} = "%PYTHON%";

my $stard_home;
my $stard_log;
my $stard_plugins;
my $stard_plugin_log;
my %stard_config;
my %blank_hash = ();
my $debug_level = 0;


## stard_setup_lib_env
# setup up basic variables for the stard core library.
# This tells the library where stard's home 
# folder is (by default /var/starmade/stard but 
# we can't be sure so anyone who calls this 
# library needs to tell it where stard is located.
# INPUT1: location of stard home
sub stard_setup_lib_env {
	$stard_home = $_[0];

	$stard_plugins = "$stard_home/plugins";
	$stard_log = "$stard_home/log";
	$stard_plugin_log = "$stard_log/plugins";
	stdout_log("stard_core setup. Found stard home: '$stard_home'", 6);
};

## stard_lib_validate_env
# validates that the setup_core_run_env has been called, and we're setup ok.
sub stard_lib_validate_env {
	if (! ($stard_home =~/\S/)) {
		croak("stard_home has not been set! the function stard_setup_core_env, with a valid stard_home needs to be called before any other functions in the stard_stdlib");
	}
}

## stard_if_debug
# prints out the message if the debug_level is high enough.
# INPUT1: debug level of message
# INPUT2: message
sub stard_if_debug {
	my $level = $_[0];
	my $message = $_[1];
	if ($level <= $debug_level) {
		print $message;
		print "\n";
	}
}

## stard_set_debug
# set the debugging level for the stard libraries
# INPUT1: debug level to set
sub stard_set_debug {
	my $level = $_[0];
	print "stard_set_debug($level)\n";
	$debug_level = $level;
}

## get_exec_prefix
# Determine what program to execute the script with
# INPUT1: executable
# OUTPUT: command to launch with
sub get_exec_prefix {
	my $exec = $_[0];

	# grab first line of the file (the exec prefix)
	open(my $fh, "<", $exec) or return;
	my $prefix = <$fh>;
	close($fh);

	# compare against 
	if ($prefix =~/#!(.*)\n/) {
		my $exec_prefix = $1;
		if ($exec_prefix_table{$exec_prefix}) {
			return $exec_prefix_table{$exec_prefix};
		}
		else {
			return $exec_prefix;
		}
	}
	return;
}

## stard_read_config
# Used to read ini stype config files
# INPUT1: location of config file
# OUTPUT: 2d hash of config file contents
sub stard_read_config {
	my $file = $_[0];

	stard_if_debug(2, "stard_read_config($file)");
	my %config;
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
			if (ref $config{$key1}{$key2} eq "ARRAY") {
				my @array = ();
				foreach my $value (@{$config{$key1}{$key2}}) {
					$value=~s/^\s+//g;
					$value=~s/\s+$//g;
					$value=~s/^'//;
					$value=~s/'$//;
					$value=~s/^"//;
					$value=~s/"$//;
					push(@array, $value);
				}
				$config{$key1}{$key2} = \@array;
			}
			else {
				$config{$key1}{$key2}=~s/^\s+//g;
				$config{$key1}{$key2}=~s/\s+$//g;
				$config{$key1}{$key2}=~s/^'//;
				$config{$key1}{$key2}=~s/'$//;
				$config{$key1}{$key2}=~s/^"//;
				$config{$key1}{$key2}=~s/"$//;
			}
		}
	}
	return \%config;
};

## get_stard_conf_field
# get a specific field from the stard config file
# INPUT1: field to grab
# INPUT2: topic (General if not given)
# OUTPUT: value of field
sub get_stard_conf_field {
	my $field = shift(@_);
	my $topic = shift(@_);

	if (! $topic) {
		$topic = "General";
		stard_if_debug(1, "get_stard_conf_field($field)");
	}
	else {
		stard_if_debug(1, "get_stard_conf_field($field, $topic)");
	}


	# we cache this if a value is requested from the config.
	if (!%stard_config) {
		%stard_config = %{stard_read_config("$stard_home/stard.cfg")};
	}


	stard_lib_validate_env();
	stard_if_debug(1, "get_stard_conf_field: return: $stard_config{$topic}{$field}");
	return $stard_config{$topic}{$field};
}

## get_stard_home
# Output: Path to the stard home
sub get_stard_home {
	return $stard_home;
}

## get_stard_plugins_dir
# Output: Path to the stard home
sub get_stard_plugins_dir {
	return $stard_plugins;
}

## get_stard_plugins_log
## Output: path to the stard home
sub get_stard_plugins_log {
	return $stard_plugin_log;
}

1;
