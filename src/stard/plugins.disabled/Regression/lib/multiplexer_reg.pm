
package multiplexer_reg;
use strict;
use warnings;

use lib("../../lib");
use stard_lib;
use stard_core;
use stard_regression;

use lib("./lib");
use reg_lib;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(multiplexer_reg);


my $stard_home = "../..";

## multiplexer_reg
# Run the regression tests against the multiplexer itself.
# The goal of these tests is to ensure that the output starmade gives
# is what the stard-multiplexer expects.
# INPUT1: player name
sub multiplexer_reg {
	my $player = shift(@_);


	my $sector = '5 5 5';
	my $test_cmd;
	my $argfile;

	if (!stard_broadcast("###Running Multiplexer Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}

	

	$test_cmd = "playerFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_faction_create("$player Faction", $player, 1);
	stard_faction_add_member($player, 1);
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd '$player' '1'\n"));

	$test_cmd = "playerFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_faction_create("$player Faction", $player, 2);
	stard_faction_add_member($player, 2);
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd '$player' '2'\n"));

	$test_cmd = "playerUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_faction_del_member($player, 2);
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd '$player' '2'\n"));


	my $ship_name = "spawn_test";
	my $blueprint = "Isanth Type-Zero Mc";
	$test_cmd = "entityDestroyed";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_change_sector_for($player, $sector);
	stard_spawn_entity($blueprint, $ship_name, $sector, -1, 'false');
	stard_despawn_all($ship_name, 'all', 'true');
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'SHIP_$ship_name'\n"));

	$test_cmd = "sectorChange";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_change_sector_for($player, '5 5 5');
	sleep 5;
	stard_change_sector_for($player, '2 3 4');
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "'$player' '5 5 5' '2 3 4'\n"));

	$test_cmd = "playerDeath";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	stard_cmd("/kill_character", $player);
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd '$player' "));
	
}
