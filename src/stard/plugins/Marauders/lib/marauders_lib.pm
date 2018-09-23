#!/usr/bin/perl
package marauders_lib;
use strict;
use warnings;

use lib("../../lib/perl");
use Starmade::Base;
use Starmade::Faction;
use Starmade::Player;
use Starmade::Sector;
use Starmade::Misc;
use Stard::Base;


my $DATA = "./data";
my $DATA_PLAYER = "./data/players";
my $ID_SIZE = 8;
# in minutes
my $OBJ_MAX_AGE = 60;
my $CONFIG = "./marauders.conf";



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
@EXPORT = qw(player_defeat player_victory last_engagement last_victory last_defeat attack_ok add_threat_level get_threat_level launch_attack start_attack_event create_ship_object remove_ship_object ship_object_jump get_player_from_object_id get_object_id get_object_name get_object_type list_ship_objects clean_old_objects clean_far_objects clean_far_ship get_tracked_players get_object_age signal_potential_attack clear_ship_object);


## player_defeat
# Actions to perform when the player has been defeated by attacking mobs.
# INPUT1: player name
sub player_defeat {
	my $player = shift(@_);

	my %config = %{stard_read_config($CONFIG)};

	add_threat_level($player, $config{General}{defeat_threat});
	open(my $fh, ">", "$DATA_PLAYER/$player/defeat") or die "failed to write to '$DATA_PLAYER/$player/defeat': $!\n";
	close($fh);
	
}

## player_victory
# Actions to perform when the player has defeated the attacking mobs
# INPUT1: player name
sub player_victory {
	my $player = shift(@_);

	my %config = %{stard_read_config($CONFIG)};

	add_threat_level($player, $config{General}{victory_threat});
	open(my $fh, ">", "$DATA_PLAYER/$player/victory") or die "failed to write to '$DATA_PLAYER/$player/victory': $!\n";
	close($fh);
	
}

## last_engagement
# Determine how long it's been since the player has won or lost a battle with the marauders
# INPUT1: player name
# OUTPUT: time (in minutes) since last victory or defeat.
sub last_engagement {
	my $player = shift(@_);

	my $vic_time = last_victory($player);
	my $def_time = last_defeat($player);

	if ($vic_time < $def_time) {
		return $vic_time;
	}
	return $def_time;
}

## last_victory
# Determine how long it's been since the player last won a battle with the marauders
# INPUT1: player name
# OUTPUT: time (in minutes) since the last victory
sub last_victory {
	my $player = shift(@_);

	my @stat = stat "$DATA_PLAYER/$player/victory" or return time;
	my $vic_time = $stat[9];
	my $cur_time = time;

	return int(($cur_time - $vic_time) /60);
	
}

## last_defeat
# Determine how long it's been since the player last lost a battle with the marauders
# INPUT1: player name
# OUTPUT: time (in minutes) since the last defeat
sub last_defeat {
	my $player = shift(@_);

	my @stat = stat "$DATA_PLAYER/$player/defeat" or return time;
	my $def_time = $stat[9];
	my $cur_time = time;

	return int(($cur_time - $def_time) /60);
}

## attack_ok
# Determine if it's ok to attack the player
# INPUT1: player name
# OUTPUT: (boolean) 0 if it's not ok to attack player, 1 if it is ok.
sub attack_ok {
	my $player = shift(@_);
	my %player_info = %{shift(@_)};

	my %config = %{stard_read_config($CONFIG)};
	my $spawn = starmade_get_spawn_sector();

	# Attack is not ok, if last attack was too soon.
	if (last_defeat($player) < $config{General}{min_attack_time_after_defeat}) {
		return 0;
	}
	if (last_victory($player) < $config{General}{min_attack_time_after_victory}) {
		return 0;
	}
	if (@{list_ship_objects($player)}) {
		return 0;
	}
	if (starmade_loc_distance($spawn, $player_info{sector}) <= $config{General}{spawn_safety_distance}) {
		return 0;
	}
	

	return 1;
}

## add_threat_level
# Add the given amount to the player's threat
# INPUT1: Player Name
# INPUT2: threat amount to add
sub add_threat_level {
	my $player = shift(@_);
	my $threat = shift(@_);

	my %config = %{stard_read_config($CONFIG)};
	my $cur_threat = get_threat_level($player);
	my $new_threat = $cur_threat + $threat;

	if ($new_threat < 0) {
		$new_threat =0;
	}

	if ($new_threat > $config{General}{max_threat}) {
		$new_threat = $config{General}{max_threat};
	}
	
	mkdir("$DATA_PLAYER/$player");
	open(my $fh, ">", "$DATA_PLAYER/$player/threat") or die "failed to write to '$DATA_PLAYER/$player/threat': $!\n";
	flock($fh, 2);
	print $fh $new_threat;
	close($fh);
}

## get_threat_level
# INPUT1: Player Name# OUTPUT: threat level for the given player
sub get_threat_level {
	my $player = shift(@_);

	my $threat;

	open(my $fh, "<", "$DATA_PLAYER/$player/threat") or return 0;
	flock($fh, 2);
	$threat = join("",<$fh>);
	$threat=~/\D/g;

	if ($threat=~/\d+\.?\d*/) {
		return $threat;
	}
	return 0;
}

## signal_potential_attack
# Run checks to see if attack should take place, and attack if we should
# INPUT1: player name
sub signal_potential_attack {
	my $trigger_player = shift(@_);

	my %config = %{stard_read_config($CONFIG)};
	
	my $attack_chance = $config{General}{encounter_chance};
	if ( $attack_chance >= int(rand(100))) {
		my %player_list = %{starmade_player_list()};
		if (!attack_ok($trigger_player, $player_list{$trigger_player})) {
			return;
		}
	
		my $attack_sector = $player_list{$trigger_player}{sector};

		foreach my $player (keys %player_list) {
			if ($player_list{$player}{sector} eq $attack_sector) {
				launch_attack($player, get_threat_level($player));
			}
		}
	}
}

## launch_attack
# send an attack against the given player based on their threat
# INPUT1: player
# INPUT2: level of attack (optional)
sub launch_attack {
	my $player = shift(@_);
	my $level = shift(@_);

	my %wave_options = %{stard_read_config("./waves.conf")};
	my %config_options = %{stard_read_config($CONFIG)};
	my $wave_closest_name;
	my $wave_closest_level;
	my @wave_choices;
	my $attack_event;

	if (!$level) {
		$level = get_threat_level($player);
	}

	foreach my $wave (keys %wave_options) {
		my $wave_diff = abs($level - $wave_options{$wave}{level});

		if ($wave_diff <= $config_options{General}{wave_variance}) {
			push(@wave_choices, $wave);
		}
		elsif (!(defined $wave_closest_name) || $wave_diff < $wave_closest_level) {
			$wave_closest_name = $wave;
			$wave_closest_level = $wave_diff;
		};
	};

	if (@wave_choices) {
		$attack_event = $wave_choices[int(rand($#wave_choices +1))];
	}
	elsif ($wave_closest_name) {
		$attack_event = $wave_closest_name;
	}
	else {
		return 0;
	}
	
	start_attack_event($player, $wave_options{$attack_event});
}

## start_attack_event
# Sends the specified attack against the given player
# INPUT1: player name
# INPUT2: hash of the wave to use
sub start_attack_event {
	my $player = shift(@_);
	my %wave = %{shift(@_)};

	my %player_info = %{starmade_player_info($player)};
	my @attack_wave;
	my @attack_wave_pos;

	if ($wave{scout}) {
		my $object = create_ship_object($player, $wave{scout}, $player_info{sector}, _random_pos());

		if ($wave{scout_wait}) {
			sleep $wave{scout_wait};
			%player_info = %{starmade_player_info($player)};
		}
		if (!get_object_name($player, $object)) {
			# if scout is disabled/destroyed cancel attack
			return;
		}
		if ($wave{scout_clear}) {
			remove_ship_object($player, $object);
		}
		
		# if player goes too far away, don't
		my %player_info_new = %{starmade_player_info($player)};
		if (starmade_loc_distance($player_info{sector}, $player_info_new{sector}) >= 2) {
			return;
		}
		%player_info = %player_info_new;
	}

	@attack_wave = split(",", $wave{objects});
	@attack_wave_pos = split(",", $wave{obj_pos});

	my $sector_size = get_starmade_conf_field('SECTOR_SIZE');

	my $attack_center = _random_pos();
	

	for (my $i = 0; $i <= $#attack_wave; $i++) {
		my $object = $attack_wave[$i];
		my $pos = starmade_location_add($attack_wave_pos[$i], $attack_center);
		create_ship_object($player, $object, $player_info{sector}, $pos);
	}
}

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
	
	my %object_config = %{stard_read_config("./objects.conf")};
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
	my %object_config = %{stard_read_config("./objects.conf")};
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
	
	if ($name=~/.*_([a-zA-Z0-9]{8})/) {
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
	my %config = %{stard_read_config($CONFIG)};

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

		#
		if ($object_removed) {
			add_threat_level($player, $config{General}{retreat_threat});
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
