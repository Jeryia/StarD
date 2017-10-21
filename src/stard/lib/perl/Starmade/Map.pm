#!perl
package Starmade::Map;
use strict;
use File::Copy;
use Carp;

use Starmade::Base;
use Starmade::Sector;
use Starmade::Map;
use Starmade::Misc;
use Stard::Log;




our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_clean_map_area starmade_setup_map starmade_repair_map starmade_recenter_map starmade_remap_map_factions);




$|=1;

my $pirate_faction = -1;
my $doodad_faction = -3;


##############################################




## starmade_clean_map_area
# cleans up the locations on the map
# INPUT1: map config (hash)
# INPUT2: cleaning level ("full" delete everything in the sector, "selective" delete only map entities)
sub starmade_clean_map_area {
	my %map_config = %{$_[0]};
	my $clean_level = $_[1];

	Object: foreach my $object (keys %map_config) {
		my $sector = $map_config{$object}{sector};

		starmade_cmd("/load_sector_range $sector $sector");
		if ($clean_level eq "full") {
			# Clean out what's already in the system (pirate stations, trade outputs, and hoolagens)
			if (!starmade_despawn_sector("", "all", "0", $sector)) {
				starmade_boardcast("Error Despawning Sector $sector.\n");
				print starmade_last_output();
				stdout_log("Error Despawning Sector $sector... Aborting game start", 1);
				return 0;
			}
		}
		elsif ($clean_level eq "selective") {
			# Get rid of anything that already has the name (as names need to be unique).
			if (!starmade_despawn_sector($object, "all", "0", $sector)) {
				starmade_broadcast("Error despawning $object in $sector.\n");
				print starmade_last_output();
				stdout_log("Error despawning all...", 1);
				return 0;			
			}
		}
		else {
			carp "starmade_clean_map_area: argument 2 must be 'full' or 'selective'\n"
		}
		if ($map_config{$object}{defenders}) {
			my @defenders = split(",", $map_config{$object}{defenders});

			starmade_despawn_mobs_bulk(\@defenders, $sector);
		}

		if ($map_config{$object}{pirates}) {
			my @pirates = split(",", $map_config{$object}{pirates});

			starmade_despawn_mobs_bulk(\@pirates, $sector);
		}

		if ($map_config{$object}{doodads}) {
			my @doodads = split(",", $map_config{$object}{doodads});

			starmade_despawn_mobs_bulk(\@doodads, $sector);
		};
	}
	return 1;
}

## starmade_setup_map
# Create whatever objects are needed by the given map
# INPUT1: map config (hash)
# OUTPUT: (boolean) true if successfull false if not.
sub starmade_setup_map {
	my %map_config = %{$_[0]};

	my %object_mappings = ();

	Object: foreach my $object (keys %map_config) {
		if ($object eq "General") {
			next Object;
		}
		my $sector = $map_config{$object}{sector};
		my $blueprint = $map_config{$object}{blueprint};
		my $owner = $map_config{$object}{owner};
		my $npc;
	
	
		starmade_cmd("/load_sector_range $sector $sector");
	
		stdout_log("Deleting all entities that start with '$object' just to be sure of no naming collisions", 6);
		# Get rid of anything that already has the name (as names need to be unique).
		if (!starmade_despawn_all($object, "all", "0")) {
			starmade_broadcast("Error despawning all.\n");
			print starmade_last_output();
			stdout_log("Error despawning all...", 1);
			return 0;
		}

		starmade_spawn_entity($blueprint, $object, $sector, $owner, 0);

		if ($map_config{$object}{defenders}) {
			my @defenders = split(",", $map_config{$object}{defenders});
			my @pos = (); 

			if ($map_config{$object}{defender_pos}) {
				@pos = split(",", $map_config{$object}{defender_pos});
			};
			starmade_spawn_mobs_bulk(\@defenders, \@pos, $owner, $sector, 1);
		}

		if ($map_config{$object}{pirates}) {
			my @pirates = split(",", $map_config{$object}{pirates});
			my @pos = (); 

			if ($map_config{$object}{pirate_pos}) {
				@pos = split(",", $map_config{$object}{pirate_pos});
			};
			starmade_spawn_mobs_bulk(\@pirates, \@pos, $pirate_faction, $sector, 1);
		}

		if ($map_config{$object}{doodads}) {
			my @doodads = split(",", $map_config{$object}{doodads});
			my @pos = ();

			if ($map_config{$object}{doodad_pos}) {
				@pos = split(",", $map_config{$object}{doodad_pos});
			};
			starmade_spawn_mobs_bulk(\@doodads, \@pos, $doodad_faction, $sector, 0);
		};
	};
	return 1;
};

## starmade_repair_map
# Create whatever objects are needed by the given map if they do not exist.
# INPUT1: map config (hash)
# OUTPUT: (boolean) true if successfull false if not.
sub starmade_repair_map {
	my %map_config = %{$_[0]};

	my %object_mappings = ();

	Object: foreach my $object (keys %map_config) {
		if ($object eq "General") {
			next Object;
		}
		my $sector = $map_config{$object}{sector};
		my $blueprint = $map_config{$object}{blueprint};
		my $owner = $map_config{$object}{owner};
		my $npc;

		my %sector_info = starmade_sector_info($sector);
	
	
		starmade_cmd("/load_sector_range $sector $sector");


		if (!$sector_info{entity}{$object} || $sector_info{entity}{$object}{$owner}) {
			stdout_log("Recreating object '$object' as it does not appear be to exist", 6);
			# Get rid of anything that already has the name (as names need to be unique).
			if (!starmade_despawn_all($object, "all", "0")) {
				starmade_broadcast("Error despawning all.\n");
				print starmade_last_output();
				stdout_log("Error despawning all...", 1);
				return 0;
			}
			sleep 1;
			starmade_spawn_entity($blueprint, $object, $sector, $owner, 0);
		}


		if ($map_config{$object}{defenders}) {
			my @defenders = split(",", $map_config{$object}{defenders});
			my @pos = (); 

			starmade_despawn_mobs_bulk(\@defenders, $sector);


			if ($map_config{$object}{defender_pos}) {
				@pos = split(",", $map_config{$object}{defender_pos});
			};
			starmade_spawn_mobs_bulk(\@defenders, \@pos, $owner, $sector, 1);
		}

		if ($map_config{$object}{pirates}) {
			my @pirates = split(",", $map_config{$object}{pirates});
			my @pos = (); 

			starmade_despawn_mobs_bulk(\@pirates, $sector);

			if ($map_config{$object}{pirate_pos}) {
				@pos = split(",", $map_config{$object}{pirate_pos});
			};
			starmade_spawn_mobs_bulk(\@pirates, \@pos, $pirate_faction, $sector, 1);
		}

		if ($map_config{$object}{doodads}) {
			my @doodads = split(",", $map_config{$object}{doodads});
			my @pos = ();

			starmade_despawn_mobs_bulk(\@doodads, $sector);

			if ($map_config{$object}{doodad_pos}) {
				@pos = split(",", $map_config{$object}{doodad_pos});
			};
			starmade_spawn_mobs_bulk(\@doodads, \@pos, $doodad_faction, $sector, 0);
		};
	};
	return 1;
};

# starmade_spawn_mobs_bulk
# spawn a large number of different mobs
# INPUT1: (array pointer) ship blueprints
# INPUT2: (array pointer) ship positions
# INPUT3: faction id
# INPUT4: sector (space seperated string)
# INPUT5: (boolean) ai active
sub starmade_spawn_mobs_bulk {
        my @ships = @{$_[0]};
        my @ship_pos = @{$_[1]};
        my $faction = $_[2];
        my $sector = $_[3];
        my $ai;

	if ($_[4]) {
		$ai = "true";
	}
	else {
		$ai = "false";
	}

        my $i;
        for ($i = 0; $i <= $#ships; $i++) {
                my $ship = $ships[$i];

                my $name = "$ship-$sector\_$i";
                if (@ship_pos) {
                        my $pos = $ship_pos[$i];
                        if (!starmade_spawn_entity_pos($ship, $name, $sector, $pos, $faction, $ai)) {
                                print starmade_last_output();
                                stdout_log("Error spawning ship '$ship' with '$name'...", 1);
                        };
                }
                else {
                        if (!starmade_spawn_entity($ship, $name, $sector, $faction, $ai)) {
                                print starmade_last_output();
                                stdout_log("Error spawning ship '$ship' with '$name'...", 1);
                        };
                };
        };
}

# starmade_despawn_mobs_bulk
# Despawn a large number of different mobs that where created by 
# starmade_spawn_mobs_bulk
# INPUT1: (array pointer) ship blueprints
# INPUT2: sector (space seperated string)
sub starmade_despawn_mobs_bulk {
        my @ships = @{$_[0]};
	my $sector = $_[2];

        my $i;
        for ($i = 0; $i <= $#ships; $i++) {
                my $ship = $ships[$i];

                my $name = "$ship-$sector\_$i";
                if (!starmade_despawn_all($name, "all", "0")) {
                       print starmade_last_output();
                       stdout_log("Error despawning '$name'...", 1);
                };
        };
}


## starmade_recenter_map
# Changes the sectors in the map hash to have a center of the given coords
# INPUT1: Map hash pointer
# INPUT2: Sector to become center (space seperated string)
sub starmade_recenter_map {
	my %map = %{shift(@_)};
	my $center = shift(@_);
	my %new_map = %map;

	for my $object (keys %map) {
		if ($map{$object}{sector}) {
			$new_map{$object}{sector} = starmade_location_add($map{$object}{sector}, $center);
		}
	}
	return \%new_map;
}

## starmade_remap_map_factions
# Changes the dummy faction numbers to the real numbers
# INPUT1: Map hash pointer
# INPUT2: hash pointer to mappings of dummy faction -> real faction
sub starmade_remap_map_factions {
	my %map = %{shift(@_)};
	my %faction_map = %{shift(@_)};
	my %new_map = %map;

	for my $object (keys %map) {
		print "$object faction: $map{$object}{owner}\n";
		print "faction_map: 1-> $faction_map{1}\n";
		if ($map{$object}{owner} && $faction_map{$map{$object}{owner}}) {
			print "map: $map{$object}{owner} -> $faction_map{$map{$object}{owner}}\n";
			$new_map{$object}{owner} = $faction_map{$map{$object}{owner}};
		}
	}
	return \%new_map;
}


1;
