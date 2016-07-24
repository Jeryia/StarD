
package general_reg;
use strict;
use warnings;

use lib("../../lib");
use stard_lib;
use stard_regression;

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


	if (!stard_broadcast("###Running General Tests###")) {
		print "Failed to broadcast message :(\n";
		exit 1;
	}

	# Check to make sure the stard_escape_chars function correctly escapes 
	# the given characters
	$test = "starmade_escape_chars - escape test";
	$input = "test\"'";
	$cmd_result = starmade_escape_chars($input);
	print "echo -n $cmd_result\n";
	$echo = `echo -n $cmd_result`;
	test_result($test, $echo eq "test\"");


	# Check to see if the stard_cmd function will correctly launch a command
	$test = "stard_cmd - basic command";
	$input = "/status";
	$cmd_result = stard_cmd($input);
	test_result($test, $cmd_result =~/SERVER, Players/, "'$input' outputs: '$cmd_result'");

	
	# Check to see if the stard_pm function returns ok with a normal pm.
	$test = "stard_pm - general";
	$input = "pm test";
	test_result($test, stard_pm($player, $input));


	# Check to see if the stard_pm command returns failure for a non-existant player.
	$test = "stard_pm - missing_player";
	$input = "pm test";
	test_result($test, !stard_pm('dWtaUw', $input));

	
	# Check to see if there are admins in the admins.txt file
	my @admins = @{stard_admin_list()};
	test_result($test, @admins, "no admins appear in admins.txt");



	# Check to see if the function stard_is_admin returns trueif given the name of 
	# an admin
	$test = "stard_admin_list - realAdmin";
	test_result($test, stard_is_admin($admins[0]), "admin_list:" . join(",", @admins));


	# Check to see if the function stard_is_admin returns false if given the name 
	# of a non-admin
	$test = "stard_admin_list - fakeAdmin";
	test_result($test, !stard_is_admin('dWtaUw'));


	# Check to see if the stard_location_add, and stard_loc_distance 
	# functions can do the math correctly.
	test_result("stard_location_add", stard_location_add("1 1 1", "1 1 1") eq "2 2 2", stard_location_add("1 1 1", "1 1 1") . "!= '2 2 2'");
	test_result("stard_loc_distance:1", stard_loc_distance("0 0 0", "0 0 1") == 1);
	test_result("stard_loc_distance:2", stard_loc_distance("0 0 0", "0 1 0") == 1);
	test_result("stard_loc_distance:3", stard_loc_distance("0 0 0", "1 0 0") == 1);
	test_result("stard_loc_distance:null", stard_loc_distance("0 0 0", "0 0 0") == 0);
	test_result("stard_loc_distance:dec1", stard_loc_distance("0 0 0", "0 0 0.1") == 0.1);
	test_result("stard_loc_distance:dec2", stard_loc_distance("0 0 0", "0 0.1 0") == 0.1);
	test_result("stard_loc_distance:dec3", stard_loc_distance("0 0 0", "0.1 0 0") == 0.1);
	stard_broadcast("\n\n");
	print "\n\n";
}

1;
