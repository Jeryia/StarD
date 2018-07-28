package Starmade::Sector;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_sector_chmod starmade_sector_info starmade_get_spawn_sector starmade_despawn_sector starmade_despawn_all starmade_spawn_entity starmade_spawn_entity_pos);



## starmade_sector_chmod
# Change the properties of a sector
# INPUT1: sector to modify
# INPUT2: add/remove
# INPUT3: setting (peace, protected, noenter, noexit, noindications, nofploss)
# OUTPUT: 1 if success, 0 if failure
sub starmade_sector_chmod {
	my $sector = $_[0];
	my $modifier = $_[1];
	my $setting = $_[2];
	
	starmade_if_debug(1, "starmade_sector_chmod($sector, $modifier, $setting)");
	starmade_validate_env();
	my $output;
	$modifier =~s/add/+/g;
	$modifier =~s/remove/-/g;

	$output = join("", starmade_cmd("/sector_chmod", split(" ", $sector), $modifier, $setting));
	if ($output =~/SUCCESS/i) {
		starmade_if_debug(1, "starmade_sector_chmod: return 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_sector_chmod: return 0");
	return 0;
};

## starmade_sector_info
# Get a hash of the sector information. Includes entities in the sector
# INPUT1: sector coords in space seperated list (ie "2 2 2")
# OUTPUT: hash of sector data format below:
# # general data (3d hash even though we only need 2d due to limitations of perl
# $sector_info{general}{info}{protected}
# $sector_info{general}{info}{peace}
#
# # entity data comes in this format
# $sector_info{entity}{$name}{faction}
# $sector_info{entity}{$name}{pos}
sub starmade_sector_info {
	my $sector = $_[0];

	starmade_if_debug(1, "starmade_sector_info($sector)");
	starmade_validate_env();
	my @output = starmade_cmd("/sector_info", split(" ", $sector));
	my %sector_info;
	foreach my $line (@output) {
		#RETURN: [SERVER, LoadedEntity [uid=ENTITY_SHIP_TC Heavy Cruiser MKII_1441843270981rl40, type=Ship, seed=0, lastModifier=, spawner=Jeryia, realName=TC Heavy Cruiser MKII_1441843270981rl40, touched=true, faction=10045, pos=(2219.499, 13.506077, 1478.0774)
		# RETURN: [SERVER, DatabaseEntry [uid=ENTITY_SPACESTATION_recycler_beta2_1444665460, sectorPos=(7, 8, 13), type=2, seed=0, lastModifier=, spawner=, realName=recycler_beta2_1444665460, touched=true, faction=-2, pos=(0.0, 0.0, 0.0), minPos=(-4, -6, -4), maxPos=(4, 2, 4), creatorID=1], 0]
		if (
			$line =~/RETURN: \[SERVER, \S+ \[uid=(.*), sectorPos=\(-?\d+, -?\d+, -?\d+\), type=.*, seed=.*, lastModifier=.*, spawner=.*, realName=.*, touched=.*, faction=(-?\d+), pos=\((\S+), (\S+), (\S+)\)/ ||
			$line =~/RETURN: \[SERVER, \S+ \[uid=(.*), type=.*, seed=.*, lastModifier=.*, spawner=.*, realName=.*, touched=.*, faction=(-?\d+), pos=\((\S+), (\S+), (\S+)\)/
		) {
			my $name = $1;
			my $faction_id = $2;
			my $pos = "$3 $4 $5";
			$sector_info{entity}{$name}{faction} = $faction_id;
			$sector_info{entity}{$name}{pos} = $pos;
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{entity}{$name}{faction} = $faction_id");
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{entity}{$name}{pos} = $pos");
		}
		# StarMade 0.201.x and newer
		# RETURN: [SERVER, LOADED SECTOR INFO: Sector[212](5, 5, 5); Permission[Peace,Protected,NoEnter,NoExit,NoIndication,NoFpLoss]: 010000; Seed: -4194436728658746121; Type: VOID;, 0]
		if ($line=~/RETURN: \[SERVER, LOADED SECTOR INFO: Sector\[\d+\]\(-?\d+, -?\d+, -?\d+\); Permission\[(\S+)\]: (\d+); Seed: \S+; Type: (\S+);, 0\]/) {
			my @perm_keys = split(',', $1);
			my @perm_values = split('', $2);
			my $type = $3;

			for (my $i = 0; $i <= $#perm_keys; $i++) {
				my $perm_name = lc $perm_keys[$i];
				my $perm_value = int $perm_values[$i];
				$sector_info{general}{info}{$perm_name} = $perm_value;
				starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{$perm_name} = $perm_value");
			}

			$sector_info{general}{info}{type} = $type;
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{type} = $type");
		}
		# StarMade 0.200.x and lower
		if ($line=~/RETURN: \[SERVER, LOADED SECTOR INFO: Sector\[\d+\]\(\S+, \S+, \S+\); Protected: (\S+); Peace: (\S+); Seed: \S+; Type: \S+;, \d+\]/) {
			my $protected = $1;
			my $peace = $2;
			$protected=~s/true/1/ig;
			$protected=~s/false/0/ig;
			$peace=~s/true/1/ig;
			$peace=~s/false/0/ig;

			$sector_info{general}{info}{protected} = int($protected);
			$sector_info{general}{info}{peace} = int($peace);
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{protected} = $protected");
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{peace} = $peace");
		}
	};
	return \%sector_info;
};

## starmade_get_spawn_sector
# gets the current player spawn sector
# OUTPUT: player spawn sector in space seperated list
sub starmade_get_spawn_sector {
	my $sector_x = get_starmade_conf_field("DEFAULT_SPAWN_SECTOR_X");
	my $sector_y = get_starmade_conf_field("DEFAULT_SPAWN_SECTOR_Y");
	my $sector_z = get_starmade_conf_field("DEFAULT_SPAWN_SECTOR_Z");
	return "$sector_x $sector_y $sector_z";
}

## starmade_despawn_sector
# Despawns all entities in the given sector that start with the given name
# INPUT1: pattern of entity to delete (give it '' if you want everything)
# INPUT2: mode (used,unused, or all)
# INPUT3: shipOnly (true or false)
# INPUT4: sector (space delimited string)
# OUTPUT: 1 if success, 0 if failure
sub starmade_despawn_sector {
	my $pattern = $_[0];
	my $mode = $_[1];
	my $ship_only = $_[2];
	my $sector = $_[3];

	if ($ship_only) {
		$ship_only = 'true';
	}
	else {
		$ship_only = 'false';
	}

	starmade_if_debug(1, "starmade_despawn_sector($pattern, $mode, $ship_only, $sector)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/despawn_sector", $pattern, $mode, $ship_only, split(' ', $sector)));
	if ($output =~/SUCCESS/i) {
		starmade_if_debug(1, "starmade_despawn_sector: return 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_despawn_sector: return 0");
	return 0;
};

## starmade_despawn_all
# Despawns all entities in the given sector that start with the given name
# INPUT1: pattern of entity to delete (give it '' if you want everything)
# INPUT2: mode (used,unused, or all)
# INPUT3: shipOnly (true or false)
# OUTPUT: 1 if success, 0 if failure
sub starmade_despawn_all {
	my $pattern = $_[0];
	my $mode = $_[1];
	my $ship_only = $_[2];

	if ($ship_only) {
		$ship_only = 'true';
	}
	else {
		$ship_only = 'false';
	}

	starmade_if_debug(1, "starmade_despawn_sector($pattern, $mode, $ship_only)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/despawn_all", $pattern, $mode, $ship_only));
	if ($output =~/SUCCESS/i) {
		starmade_if_debug(1, "starmade_despawn_sector: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_despawn_sector: return: 0");
	return 0;
};

## starmade_spawn_entity
# Spawn the given blueprint with the given name
# INPUT1: Blueprint to use
# INPUT2: Name to give the entity (carefull, this needs to be unique in the game
# INPUT3: Sector to spawn the entity in (space separated list)
# INPUT4: Faction id of the faction the entity is to belong to
# INPUT5: true if ai is to be active, false if not.
# OUTPUT: 1 if success, 0 if failure.
sub starmade_spawn_entity {
	my $blueprint = $_[0];
	my $name = $_[1];
	my $sector = $_[2];
	my $faction = $_[3];
	my $ai = $_[4];

	if ($ai) {
		$ai = 'true';
	}
	else {
		$ai = 'false';
	}

	starmade_if_debug(1, "starmade_spawn_entity($blueprint, $name, $sector, $faction, $ai)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/spawn_entity", $blueprint, $name, split(" ", $sector), $faction, $ai));

	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_spawn_entity: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_spawn_entity: return: 1");
	return 1;
};

## starmade_spawn_entity_pos
# Spawn the given blueprint with the given name
# INPUT1: Blueprint to use
# INPUT2: Name to give the entity (carefull, this needs to be unique in the game
# INPUT3: Sector to spawn the entity in (space seperated list)
# INPUT4: POS to spawn the entity in (space seperated list)
# INPUT5: Faction id of the faction the entity is to belong to
# INPUT6: true if ai is to be active, false if not.
# OUTPUT: 1 if success, 0 if failure.
sub starmade_spawn_entity_pos {
	my $blueprint = $_[0];
	my $name = $_[1];
	my $sector = $_[2];
	my $pos = $_[3];
	my $faction = $_[4];
	my $ai = $_[5];

	if ($ai) {
		$ai = 'true';
	}
	else {
		$ai = 'false';
	}

	starmade_if_debug(1, "starmade_spawn_entity_pos($blueprint, $name, $sector, $pos, $faction, $ai)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/spawn_entity_pos", $blueprint, $name, split(" ",$sector), split(' ', $pos), $faction, $ai));

	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_spawn_entity: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_spawn_entity: return: 1");
	return 1;
};

1;
