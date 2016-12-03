package Stard::Plugin;
use strict;
use warnings;
use Cwd;
use Text::ParseWords;
use Proc::Daemon;
use POSIX;


use Stard::Base;
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

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(stard_setup_lib_env get_active_plugin_list validate_plugins);

my @plugin_list = ();

##### DANGER GLOBAL VARIABLE!!! #####
my $GLOBAL_overheat_entity;


## get_active_plugin_list
# Lists the active plugins
# OUTPUT: array of active plugins
sub get_active_plugin_list {
	stard_lib_validate_env();
	my @plugins = ();
	if (@plugin_list) {
		return \@plugin_list;
	}

	my $stard_plugins = get_stard_plugins_dir();
	opendir(my $dh, $stard_plugins) or die "could not open '$stard_plugins': $!\n";
	while (readdir $dh) {
		my $plugin = $_;
		if ($plugin ne '.' && $plugin ne '..') {
			push(@plugins, $plugin);
		}
	}
	@plugin_list = @plugins;
	return \@plugins;
}

## validate_plugins
# Check plugins to see if they look valid
sub validate_plugins {
	my @plugins = @{get_active_plugin_list()};

	my $stard_plugins = get_stard_plugins_dir();

	stdout_log("Checking plugins", 6);
	foreach my $plugin (@plugins) {
		if (opendir(my $dir, "$stard_plugins/$plugin")) {
			stdout_log("$plugin loaded successfully", 6);
			closedir($dir);
		}
		else {
			stdout_log("$plugin is not loaded. Could not open '$stard_plugins/$plugin': $!", 3);
		}
	}
}

1;
