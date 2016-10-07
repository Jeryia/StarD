package Starmade::Spawn;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_despawn_sector starmade_despawn_all starmade_spawn_entity starmade_spawn_entity_pos);



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
