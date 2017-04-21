#!/usr/bin/perl
package Civ::Object;
use strict;
use warnings;

use lib("../../lib/perl");
use Starmade::Base;
use Starmade::Faction;
use Starmade::Player;
use Starmade::Sector;
use Starmade::Misc;
use Stard::Base;

use Civ::Base;


my $DATA = "./data";
my $DATA_PLAYER = "./data/players";
my $ID_SIZE = 10;
# in minutes
my $OBJ_MAX_AGE = 120;



mkdir($DATA);
if (! -d $DATA) {
	die "Failed to create directory '$DATA': $!";
}
mkdir($DATA_PLAYER);
if (! -d $DATA_PLAYER) {
	die "Failed to create directory '$DATA_PLAYER': $!";
}


our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ship_object remove_ship_object ship_object_jump get_player_from_object_id get_object_id get_object_name get_object_type list_ship_objects clean_old_objects clean_far_objects clean_far_ship get_tracked_players get_object_age signal_potential_attack clear_ship_object);



## _random_pos
# Provide a random position in to spawn units in the given sector
# OUTPUT: position (space seperated list)
sub _random_pos {
	my $sector_size = get_starmade_conf_field('SECTOR_SIZE');

	return int(rand($sector_size * 2 - 500) - $sector_size)
		. " " . int(rand($sector_size * 2 - 500) - $sector_size) 
		. " " . int(rand($sector_size * 2 - 500) - $sector_size)
	;
}

## create_ship_object
# creates a ship object from the object given
# INPUT1: player name (player you are spawning the object against)
# INPUT2: object type (from ./objects.conf)
# INPUT3: sector
# INPUT4: pos (position in the sector)
# OUTPUT: object id (for reference)
sub create_ship_object {
	my $player = shift(@_);
	my $object_type = shift(@_);
	my $sector = shift(@_);
	my $pos = shift(@_);

	mkdir("$DATA_PLAYER/$player");
	if (! -d "$DATA_PLAYER/$player") {
		die "failed to create directory '$DATA_PLAYER/$player': $!\n";
	}
	mkdir("$DATA_PLAYER/$player/objects");
	if (! -d "$DATA_PLAYER/$player") {
		die "failed to create directory '$DATA_PLAYER/$player': $!\n";
	}
	if (!$pos) {
		$pos = _random_pos();
	}
	
	my %object_config = %{stard_read_config("./config/objects.conf")};
	$object_config{$object_type}{faction} = map_faction($object_config{$object_type}{faction});
	my $rand_id = _gen_obj_id();
	my $object_name = "$object_type\_$rand_id";
	
	if (!starmade_spawn_entity_pos(
		$object_config{$object_type}{blueprint},
		$object_name,
		$sector,
		$pos,
		$object_config{$object_type}{faction},
		1
	)) {
		return 0;
	}

	my $fh;
	if(!open($fh, ">", "$DATA_PLAYER/$player/objects/$rand_id")) {
		starmade_despawn_all($object_name, 'all', 1);
		warn "Error Spawning '$object_name'!\n";
		return 0;
	}
	print $fh $object_type;
	close($fh);
	return $rand_id;
}

## remove_ship_object
# remove an object
# INPUT1: player object was spawned for
# INPUT2: Object id
# OUTPUT: (boolean)  0 if failure, 1 if success.
sub remove_ship_object {
	my $player = shift(@_);
	my $id = shift(@_);
	
	if (!-e "$DATA_PLAYER/$player/objects/$id") {
		return 0;
	}
	my $obj_name = get_object_name($player,$id);

	if (!$obj_name) {
		return 0;
	}

	unlink("$DATA_PLAYER/$player/objects/$id") or return 0;
	return starmade_despawn_all($obj_name, 'all', 1);
}

## clear_ship_object
# Removes the tracking for an object. This is generally done when it is defeated 
# to avoid the player losing the object itself to steal.
# INPUT1: player object was spawned for
# INPUT2: Object id
# OUTPUT: (boolean)  0 if failure, 1 if success.
sub clear_ship_object {
	my $player = shift(@_);
	my $id = shift(@_);

	if (!-e "$DATA_PLAYER/$player/objects/$id") {
		return 0;
	}
	my $obj_name = get_object_name($player,$id);

	if (!$obj_name) {
		return 0;
	}

	unlink("$DATA_PLAYER/$player/objects/$id") or return 0;
}


## ship_object_jump
# Cause an ojbect to jump (if it can)
# INPUT1: player object was spawned for
# INPUT2: object id
# OUTPUT: (boolean) 0 if failure, 1 if success.
sub ship_object_jump {
	my $player = shift(@_);
	my $id = shift(@_);

	my $obj_name = get_object_name($player, $id);
	my $obj_type = get_object_type($id);
	my %object_config = %{stard_read_config("./config/objects.conf")};
	my $sector;
	my $pos;

	if (!$object_config{$obj_type}{jump_bp}) {
		return 0;
	}

	my %ships = %{starmade_search($obj_name)};

	if (!$ships{$obj_name}) {
		return 0;
	}

	$sector = $ships{$obj_name};
	my %sector_info = %{starmade_sector_info($sector)};

	if(!$sector_info{entity}{$obj_name}) {
		return 0;
	}
	$pos = $sector_info{entity}{$obj_name}{pos};
	$object_config{$obj_name}{faction} = map_faction($object_config{$obj_name}{faction});

	starmade_despawn_all($obj_name, 'all', 1);
	starmade_spawn_entity_pos($object_config{$obj_type}{jump_bp}, "$obj_name\_j", $sector, $sector_info{entity}{$obj_name}{faction}, $pos, 1);
	
	my $pid = fork();
	if (!$pid) {
		$pid = fork();
		if (!$pid) {
			if ($object_config{$obj_type}{jump_time}) {
				sleep $object_config{$obj_type}{jump_time};
			}
			else {
				sleep 30;
			}
			remove_ship_object($id);
		}
		exit 0;
	}
	waitpid($pid, 0);
	return 1;
}

## _gen_id
# generate a random id
# OUTPUT: random id
sub _gen_id {
	my @chars = split("", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890");

	my $id = "";
	for (1..$ID_SIZE) {
		$id .= $chars[int(rand($#chars +1))];
	}
	return $id;
}

## _gen_obj_id
# generate a unique object id
# OUTPUT: object id.
sub _gen_obj_id {
	my $id = _gen_id();
	while(!_obj_id_unique($id)) {
		$id = _gen_id();
	}
	return $id;
}

## _obj_id_unique
# Check if object id is unique
# OUTPUT: (boolean) 0 if not unque, 1 if it is unique.
sub _obj_id_unique {
	my $id = shift(@_);

	if (get_player_from_object_id($id)) {
		return 0;
	}
	return 1;
}

## get_player_from_object_id
# Determine the player by using the object id
# INPUT1: object id
# OUTPUT: player object was spawned for.
sub get_player_from_object_id {
	my $id = shift(@_);

	my @players = @{get_tracked_players()};

	foreach my $player (@players) {
		if (-e "$DATA_PLAYER/$player/objects/$id") {
			return $player;
		}
	}
}

## get_object_id
# From the name of the object, determine it's id
# INPUT: object name (entity name)
# OUTPUT: object id
sub get_object_id {
	my $name = shift(@_);
	
	if ($name=~/.*_([a-zA-Z0-9]{10})/) {
		return $1;
	}
}

## get_object_name
# Get the object name
# INPUT1: player object was spawned for
# INPUT2: object id
# OUTPUT: object name (entity name)
sub get_object_name {
	my $player = shift(@_);
	my $id = shift(@_);

	my $type;

	open(my $fh, "<", "$DATA_PLAYER/$player/objects/$id") or return 0;
	$type = join("", <$fh>);
	close($fh);
	return "$type\_$id";
}

## get_object_type
# Determine the object type
# INPUT1: player object was spawned for
# INPUT2: object id
# OUTPUT: object type
sub get_object_type {
	my $player = shift(@_);
	my $id = shift(@_);

	my $type;

	open(my $fh, "<", "$DATA_PLAYER/$player/objects/$id") or return ();
	$type = join("", <$fh>);
	close($fh);
	return $type;
}

## list_ship_objects
# List spawned object for the given player
# INPUT1: player name
# OUTPUT: (array pointer) list of objects spawned for the given player
sub list_ship_objects {
	my $player = shift(@_);

	my @objects = ();
	opendir(my $dh, "$DATA_PLAYER/$player/objects") or return \@objects;

	while (readdir $dh) {
		if ($_ ne '.' && $_ ne '..') {
			push(@objects, $_);
		}
	}
	return \@objects;
}

## clean_old_objects
# Remove objects that are older than the max age
sub clean_old_objects {
	my @players = @{get_tracked_players()};

	foreach my $player (@players) {
		my @objects = @{list_ship_objects($player)};

		foreach my $object (@objects) {
			my $age= get_object_age($player, $object);
			if ($age > $OBJ_MAX_AGE) {
				remove_ship_object($player, $object);
			}
		}
	}
}

## clean_far_objects
# Remove objects that are out of range of any player
sub clean_far_objects {
	my @players = @{get_tracked_players()};
	my %player_list = %{starmade_player_list()};

	foreach my $player (@players) {
		my @objects = @{list_ship_objects($player)};
		my $object_removed = 0;

		foreach my $object (@objects) {
			my $age = get_object_age($player, $object);
			if ($age >=1) {
				clean_far_ship($player, $object, \%player_list);
				$object_removed++;
			}
		}
	}
}

## clean_far_ship
# Remove a ship that's too far away from all players
# INPUT1: player name
# INPUT2: object id
# INPUT3: a player list hash
sub clean_far_ship {
	my $player = shift(@_);
	my $id = shift(@_);
	my %player_list = %{shift(@_)};

	my $name= get_object_name($player, $id);
	my %ships = %{starmade_search($name)};
	my $ship_loc;

	# clean out ones that no longer exist
	if (!$ships{$name}) {
		warn "Could not determine location of ship '$name'!\n";
		remove_ship_object($player, $id);
		return;
	}
	$ship_loc = $ships{$name};
	
	
	Player: foreach my $player (keys %player_list) {
		my $sector = $player_list{$player}{sector};
		if (!$sector) {
			next Player;
		}
		my $distance = starmade_loc_distance($sector, $ship_loc);
		if ($distance >= 2) {
			remove_ship_object($player, $id);
		}
	}

}

## get_tracked_players
# Get a list of players this mod has been keeping track of
# OUTPUT: (array pointer) list of players
sub get_tracked_players {
	opendir(my $dh, $DATA_PLAYER);
	my @players = ();
	while (readdir $dh) {
		if ($_ ne '.' && $_ ne '..') {
			push(@players, $_);
		}
	}
	return \@players;
}

## get_object_age
# Determine the age of an object
# INPUT1: player object was spawned for
# INPUT2: object id
# OUTPUT: object age (in minutes)
sub get_object_age {
	my $player = shift(@_);
	my $object = shift(@_);

	my @stat = stat "$DATA_PLAYER/$player/objects/$object" or return 0;
	my $created = $stat[10]; 
	my $curtime = time;
	
	return int($curtime - $created)/60;
}

1;
