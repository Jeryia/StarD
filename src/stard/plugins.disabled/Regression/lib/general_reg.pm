
package general_reg;
use strict;
use warnings;

use Starmade::Base;
use Starmade::Message;
use Starmade::Player;
use Starmade::Misc;
use Stard::Regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(general_reg);


my $stard_home = "../..";

## general_reg
# perform basic functionality regression tests for stard
# INPUT1: name of the player who requested the testing.
sub general_reg {
	my $player = $_[0];
	my $test;
	my $string;
	my $cmd_result;
	my $input;
	my $echo;


	if (!starmade_broadcast("###Running General Tests###")) {
		print "Failed to broadcast message :(\n";
		exit 1;
	}

	# Check to make sure the starmade_escape_chars function correctly escapes 
	# the given characters
	$test = "starmade_escape_chars - escape test";
	$input = "test\"'";
	$cmd_result = starmade_escape_chars($input);
	print "echo -n $cmd_result\n";
	$echo = `echo -n $cmd_result`;
	test_result($test, $echo eq "test\"");


	# Check to see if the starmade_cmd function will correctly launch a command
	$test = "starmade_cmd - basic command";
	$input = "/status";
	$cmd_result = starmade_cmd($input);
	test_result($test, $cmd_result =~/SERVER, Players/, "'$input' outputs: '$cmd_result'");

	
	# Check to see if the starmade_pm function returns ok with a normal pm.
	$test = "starmade_pm - general";
	$input = "pm test";
	test_result($test, starmade_pm($player, $input));


	# Check to see if the starmade_pm command returns failure for a non-existant player.
	$test = "starmade_pm - missing_player";
	$input = "pm test";
	test_result($test, !starmade_pm('dWtaUw', $input));

	
	# Check to see if there are admins in the admins.txt file
	my @admins = @{starmade_admin_list()};
	test_result($test, @admins, "no admins appear in admins.txt");



	# Check to see if the function starmade_is_admin returns trueif given the name of 
	# an admin
	$test = "starmade_admin_list - realAdmin";
	test_result($test, starmade_is_admin($admins[0]), "admin_list:" . join(",", @admins));


	# Check to see if the function starmade_is_admin returns false if given the name 
	# of a non-admin
	$test = "starmade_admin_list - fakeAdmin";
	test_result($test, !starmade_is_admin('dWtaUw'));


	# Check to see if the starmade_location_add, and starmade_loc_distance 
	# functions can do the math correctly.
	test_result("starmade_location_add", starmade_location_add("1 1 1", "1 1 1") eq "2 2 2", starmade_location_add("1 1 1", "1 1 1") . "!= '2 2 2'");
	test_result("starmade_loc_distance:1", starmade_loc_distance("0 0 0", "0 0 1") == 1);
	test_result("starmade_loc_distance:2", starmade_loc_distance("0 0 0", "0 1 0") == 1);
	test_result("starmade_loc_distance:3", starmade_loc_distance("0 0 0", "1 0 0") == 1);
	test_result("starmade_loc_distance:null", starmade_loc_distance("0 0 0", "0 0 0") == 0);
	test_result("starmade_loc_distance:dec1", starmade_loc_distance("0 0 0", "0 0 0.1") == 0.1);
	test_result("starmade_loc_distance:dec2", starmade_loc_distance("0 0 0", "0 0.1 0") == 0.1);
	test_result("starmade_loc_distance:dec3", starmade_loc_distance("0 0 0", "0.1 0 0") == 0.1);
	starmade_broadcast("\n\n");
	print "\n\n";
}

1;
