
package player_reg;
use strict;
use warnings;

use lib("../../lib");
use Starmade::Player;
use Starmade::Chat;
use Stard::Regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(player_reg);


my $stard_home = "../..";

## player_reg
# Perform player oriented functionality regression tests for stard
# INPUT1: name of the player who requested the testing.
sub player_reg {
	my $player = $_[0];
	if (!starmade_broadcast("###Running Player Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}


	# Check to see if the starmade_god_mode function returns true when used 
	# against a player that exists.
	test_result("god_mode active", starmade_god_mode($player, 1));
	test_result("god_mode inactive", starmade_god_mode($player, 0));

	# Check to see if the starmade_god_mode function returns false when used
	# against a player that does not exist
	test_result("god_mode invalid", !starmade_god_mode('msbr', 1));

	
	
	# Check to see if the starmade_inviability_mode function returns true when 
	# used against a player that exists.
	test_result("invisibility_mode active", starmade_invisibility_mode($player, 1));
	test_result("invisibility_mode inactive", starmade_invisibility_mode($player, 0));


	# Check to see if the starmade_inviability_mode function returns false when 
	# used against a player that exists.
	test_result("invisibility_mode invalid", !starmade_invisibility_mode('msbr', 1));


	# Check to see that the function player_list returns results
	my %player_list = %{starmade_player_list()};
	my %player_info1 = %{$player_list{$player}};
	test_result(
		"player_list",
		keys %player_info1
	);
	starmade_broadcast("$player\'s data:");
	for my $field (keys %player_info1) {
		starmade_broadcast("$field: $player_info1{$field}");
	};


	# Check to see that the function starmade_player_info returns the same results 
	# about the player as starmade_player_list
	my %player_info2 = %{starmade_player_info($player)};
	test_result("starmade_player_info", keys %player_info2);
	my $consistancy = 1;
	for my $field (keys %player_info1) {
		if ($player_info1{$field} ne $player_info1{$field}) {
			starmade_broadcast("player_list and player_info data don't match!");
			starmade_broadcast("$field: $player_info1{$field} != $player_info2{$field}");
			$consistancy = 0;
		}
	};
	test_result("starmade_player_info,starmade_player_list - consistancy", $consistancy);
	starmade_broadcast("\n\n");


	# Check to see that the given functions return true when used against a player
	# that exists.
	test_result("starmade_give_credits", starmade_give_credits($player, 100));
	test_result("starmade_give_item", starmade_give_item($player, "Thruster", 1));
	test_result("starmade_give_all_items", starmade_give_all_items($player, -1));
	test_result("starmade_set_spawn_player", starmade_set_spawn_player($player));

	# Check to see that the given functions return false when used against a
	# player that does not exist.
	test_result("starmade_give_credits: unknown player", !starmade_give_credits('adfaddreh', 100));
	test_result("starmade_give_item: unknown player", !starmade_give_item('adfaddreh', "Thruster", 1));
	test_result("starmade_set_spawn_player:unknown player", !starmade_set_spawn_player('adfaddreh'));
	test_result("starmade_give_all_items: unknown player", !starmade_give_credits('adfaddreh', -1));

	# Check to see that if given an invalid item, starmade_give_item returns 
	# false
	test_result("starmade_give_item: unknown item", !starmade_give_item($player, "Thrusterz", 1));
	print "\n\n";	
}

1;
