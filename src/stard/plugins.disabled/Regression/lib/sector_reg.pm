
package sector_reg;
use strict;
use warnings;

use lib("../../lib");
use stard_lib;
use stard_core;
use stard_regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(sector_reg);


my $stard_home = "../..";

## sector_reg
# Perform sector oriented functionality regression tests for stard
# INPUT1: name of the player who requested the testing.
sub sector_reg {
	my $player = $_[0];	
	my %player_info;

	my $spawn = "2 2 2";
	my $sector1 = "5 5 5";

	if (!stard_broadcast("###Running Sector Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}

	# Check that stard_change_section_for moves the player too the spawn sector
	stard_change_sector_for($player, $spawn);
	%player_info = %{stard_player_info($player)};
	test_result("stard_change_sector_for - spawn", $player_info{sector} eq $spawn);
	# we sleep as StarMade will not allow the player to be moved too often
	sleep 5;


	# Check that we could move the player to annother sector with stard_change_sector_for
	test_result("stard_change_sector", stard_change_sector_for($player, $sector1));
	%player_info = %{stard_player_info($player)};
	test_result("stard_change_sector_for - validate", $player_info{sector} eq $sector1);


	# Check that we can spawn a mob with stard_spawn_entity
	my $ship_name = "spawn_test";
	my $blueprint = "Isanth Type-Zero Mc";
	test_result("stard_spawn_entity", stard_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false' ));
	my %search = %{stard_search($ship_name)};
	my $validate = keys %search;
	test_result("stard_search/stard_spawn_entity", $validate >= 1);
	%search = %{stard_sector_info($sector1)};
	$validate = join(" ", keys %{$search{entity}});
	test_result("stard_sector_info/stard_spawn_entity", $search{entity}{"ENTITY_SHIP_$ship_name"}, $validate);

	
	# Check that we can despawn the mob with stard_despawn_all
	test_result("stard_despawn_all", stard_despawn_all($ship_name, 'all', 'true'));
	%search = %{stard_search($ship_name)};
	$validate = keys %search;
	test_result("stard_despawn_all - validate", $validate <= 0);


	# Check that we can spawn annother mob	$ship_name = "spawn_test2";
	stard_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false');


	# Check that we can despawn the mod with stard_despawn_sector 
	test_result("stard_despawn_sector", stard_despawn_sector($ship_name, 'all', 'true', $sector1));
	%search = %{stard_search($ship_name)};
	$validate = keys %search;
	test_result("stard_despawn_all - validate", $validate <= 0);

	
	# Check that running stard_spawn_entity with an invalid blueprint returns false
	$ship_name = "spawn_test3";
	$blueprint = "goblygook";
	test_result("stard_spawn_entity - invalid blueprint", !stard_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false'));


	# Check that stard_sector_chmod can set a sector to protected
	test_result("stard_sector_chmod - set protected", stard_sector_chmod($sector1, "add", "protected"));
	my %sector_info = %{stard_sector_info($sector1)};
	test_result("stard_sector_chmod/stard_sector_info validation", $sector_info{general}{info}{protected});
	sleep 5;	


	# Check that we can remove the sector protection with stard_sector_chmod
	test_result("stard_sector_chmod - unset protected", stard_sector_chmod($sector1, "remove", "protected"));
	%sector_info = %{stard_sector_info($sector1)};
	test_result("stard_sector_chmod/stard_sector_info validation", !$sector_info{general}{info}{protected});


	stard_broadcast("\n\n");
	print "\n\n";

};

1;
