
package map_reg;
use strict;
use warnings;

use lib("../../lib");
use Starmade::Chat;
use Starmade::Map;
use Starmade::Sector;
use Starmade::Spawn;
use Starmade::Misc;
use Stard::Base;
use Stard::Regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(map_reg);


my $stard_home = "../..";


## map_reg
# Perform tests for the Starmade::Map library
# INPUT1: name of the player who requested the testing.
sub map_reg {
	my $player = $_[0];

	my $map = "./files/Maps/test.map";
	my %map_config = %{stard_read_config($map)};
	my $blueprint = "Isanth Type-Zero Mc";
	my $sector = "8 0 8";
	
	my %sector_info;
	my @validate;

	if (!starmade_broadcast("###Running Map Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}


	# Check that we can clear the map locations of unite with starmade_clean_map_area
	starmade_spawn_entity($blueprint, "itsz", $sector, -1, 0 );
	test_result("starmade_clean_map_area - full clean return ok", starmade_clean_map_area(\%map_config, "full"));
	%sector_info = %{starmade_sector_info($sector)};
	@validate = keys %{$sector_info{entity}};
	test_result("starmade_clean_map_area - successfull clean", !@validate);


	# Check that we can deploy a map configuration
	test_result("starmade_setup_map - return ok", starmade_setup_map(\%map_config));
	%sector_info = %{starmade_sector_info($sector)};
	test_result("starmade_setup_map - object spawn", $sector_info{entity}{ENTITY_SHIP_test_station});
	test_result("starmade_setup_map - defender spawn", %{starmade_search("Isanth Type-Zero Bm")});


	# check that we can clean things back up.
	test_result("starmade_clean_map_area - full clean return ok 2", starmade_clean_map_area(\%map_config, "full"));

}

