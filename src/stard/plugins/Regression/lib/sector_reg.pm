
package sector_reg;
use strict;
use warnings;

use Starmade::Message;
use Starmade::Sector;
use Starmade::Player;
use Starmade::Misc;
use Starmade::Regression;

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

	prep_test_category('Sector', 15);

	# Check that starmade_change_section_for moves the player too the spawn sector
	starmade_change_sector_for($player, $spawn);
	%player_info = %{starmade_player_info($player)};
	test_result("starmade_change_sector_for - spawn", $player_info{sector} eq $spawn);
	# we sleep as StarMade will not allow the player to be moved too often
	sleep 5;


	# Check that we could move the player to annother sector with starmade_change_sector_for
	test_result("starmade_change_sector", starmade_change_sector_for($player, $sector1));
	%player_info = %{starmade_player_info($player)};
	test_result("starmade_change_sector_for - validate", $player_info{sector} eq $sector1);


	# Check that we can spawn a mob with starmade_spawn_entity
	my $ship_name = "spawn_test";
	my $blueprint = "Isanth Type-Zero Mc";
	starmade_despawn_all($ship_name, 'all', 'true');
	sleep 1;
	test_result("starmade_spawn_entity", starmade_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false' ));
	my %search = %{starmade_search($ship_name)};
	my $validate = keys %search;
	test_result("starmade_search/starmade_spawn_entity", $validate >= 1);
	%search = %{starmade_sector_info($sector1)};
	$validate = join(" ", keys %{$search{entity}});
	test_result("starmade_sector_info/starmade_spawn_entity", $search{entity}{"ENTITY_SHIP_$ship_name"}, $validate);

	
	# Check that we can despawn the mob with starmade_despawn_all
	test_result("starmade_despawn_all", starmade_despawn_all($ship_name, 'all', 'true'));
	%search = %{starmade_search($ship_name)};
	$validate = keys %search;
	test_result("starmade_despawn_all - validate", $validate <= 0);


	# Check that we can spawn annother mob	$ship_name = "spawn_test2";
	starmade_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false');


	# Check that we can despawn the mod with starmade_despawn_sector 
	test_result("starmade_despawn_sector", starmade_despawn_sector($ship_name, 'all', 'true', $sector1));
	%search = %{starmade_search($ship_name)};
	$validate = keys %search;
	test_result("starmade_despawn_all - validate", $validate <= 0);

	
	# Check that running starmade_spawn_entity with an invalid blueprint returns false
	$ship_name = "spawn_test3";
	$blueprint = "goblygook";
	test_result("starmade_spawn_entity - invalid blueprint", !starmade_spawn_entity($blueprint, $ship_name, $sector1, -1, 'false'));


	# Check that starmade_sector_chmod can set a sector to protected
	test_result("starmade_sector_chmod - set protected", starmade_sector_chmod($sector1, "add", "protected"));
	my %sector_info = %{starmade_sector_info($sector1)};
	test_result("starmade_sector_chmod/starmade_sector_info validation", $sector_info{general}{info}{protected});
	sleep 5;	


	# Check that we can remove the sector protection with starmade_sector_chmod
	test_result("starmade_sector_chmod - unset protected", starmade_sector_chmod($sector1, "remove", "protected"));
	%sector_info = %{starmade_sector_info($sector1)};
	test_result("starmade_sector_chmod/starmade_sector_info validation", !$sector_info{general}{info}{protected});


	starmade_broadcast("\n\n");
	print "\n\n";

};

1;
