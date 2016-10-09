
package plugin_reg;
use strict;
use warnings;

use Starmade::Message;
use Stard::Base;
use Stard::Plugin;
use Stard::Regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(plugin_reg);


my $stard_home = "../..";

## plugin_reg
# run tests on all active plugins (who have a regression test)
# INPUT1: player name
sub plugin_reg {
	my $player = shift(@_);

	my @plugins = sort(@{get_active_plugin_list()});
	foreach my $plugin (@plugins) {
		test_result("Plugin $plugin - Final Result", plugin_reg_launch($plugin, $player));
	}
}


## plugin_reg_launch
# Spawns off the regression tests for the given plugin (if it has one)
# INPUT1: plugin name
# OUTPUT: (boolean) sucess if plugin's regression came back ok
sub plugin_reg_launch {
	my $plugin = shift(@_);
	my $player = shift(@_);

	if ( ! -x "../$plugin/.regression") {
		return 1; 
	}


	starmade_broadcast("###Running $plugin Plugin Tests###");

	my $pid = fork();
	if ($pid) {
		waitpid($pid, 0);
		if ( $? == 0) {
			return 1;
		}
		return 0;
	}
	else {
		# other plugins will always be one 
		# directory down from this one
		chdir("../$plugin") or die "could not chdir to '../$plugin'\n";
		my $exec = get_exec_prefix("./.regression");
		exec("$exec", "./.regression", $player);
		die "Failed to run ./regression for $plugin!\n";
	}
}
