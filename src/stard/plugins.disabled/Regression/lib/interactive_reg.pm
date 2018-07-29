
package interactive_reg;
use strict;
use warnings;

use Starmade::Base;
use Starmade::Message;
use Starmade::Faction;
use Starmade::Player;
use Starmade::Sector;
use Starmade::Regression;
use Stard::Multiplexer;

use lib("./lib");
use reg_lib;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(interactive_reg);


my $stard_home = "../..";

## interactive_reg
# Run the regression tests that require interaction from the player.
# INPUT1: player name
sub interactive_reg {
	my $player = shift(@_);


	my $sector = '5 5 5';
	my $test_cmd;
	my $argfile;

	prep_test_category('Interactive', 10);
	
	$test_cmd = "playerLogout";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	unlink("./tmp/serverEvents/playerLogin");
	unlink("./tmp/serverEvents/playerSpawn");
	starmade_pm($player, "Please log out and back in.");
	wait_for_file($argfile, 20);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$player'"));

	$test_cmd = "playerLogin";
	$argfile = "./tmp/serverEvents/$test_cmd";
	wait_for_file($argfile, 20);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$player'"));

	$test_cmd = "playerSpawn";
	$argfile = "./tmp/serverEvents/$test_cmd";
	wait_for_file($argfile, 20);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$player'"));


	
	$test_cmd = "entityFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	my $ship_name = "$test_cmd\_test";
	my $blueprint = "Isanth Type-Zero Mc";
	unlink($argfile);
	starmade_change_sector_for($player, $sector);
	starmade_teleport_to($player, '0 0 20');
	starmade_give_item($player, "Faction Module", 1);
	starmade_despawn_all($ship_name, 'all', 1);
	sleep 1;
	starmade_spawn_entity($blueprint, $ship_name, $sector, 0, 0 );
	starmade_faction_delete(2);
	starmade_faction_create("test faction", '', 2);
	starmade_faction_add_member($player, 2);
	starmade_pm($player, "Please change the faction owner of the ship $ship_name");
	wait_for_file($argfile, 60);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$ship_name' '2'"));

	$test_cmd = "entityUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	starmade_pm($player, "Please unfaction the entity $ship_name, without destroying it's faction block");
	wait_for_file($argfile, 60);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$ship_name'"));

	$test_cmd = "entityUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	starmade_pm($player, "Please destroy the faction block of $ship_name");
	wait_for_file($argfile, 60);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$ship_name'"));
	
	
	$test_cmd = "entityOverheat";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	starmade_cmd("/give_rocket_launcher_op", $player);
	starmade_teleport_to($player, '0 -60 0');
	starmade_pm($player, "Please cause this ship(above you) to overheat with this rocket launcher");
	wait_for_file($argfile, 60);
	test_result("stard_core - interactive $test_cmd", ck_file_string($argfile, "$test_cmd '$ship_name'"));

	starmade_despawn_all($ship_name, 'all', 1);
	starmade_faction_delete(2);

}

sub wait_for_file {
	my $file = shift(@_);
	my $max_time = shift(@_);

	my $time = 0;
	while (! -r $file && $time < $max_time) {
		sleep 1;
		$time++;
	}
	select(undef,undef,undef, .1);
}
