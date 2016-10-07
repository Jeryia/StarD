package Starmade::Faction;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_faction_create starmade_faction_delete starmade_faction_list_bid starmade_faction_list_bname starmade_faction_list_members starmade_faction_mod_relations starmade_faction_set_all_relations starmade_faction_add_member starmade_faction_del_member);



## starmade_faction_create
# Creates a faction with a given leader
# INPUT1: faction name
# INPUT2: the leader of said faction
# INPUT3: (optional) faction id to create faction as.
# OUTPUT: 1 if successful, 0 if not
sub starmade_faction_create {
	my $name = $_[0];
	my $leader = $_[1];
	my $id = $_[2];

	starmade_if_debug(1, "starmade_faction_create($name, $leader)");
	starmade_validate_env();

	if ($id) {
		my $output = join("",starmade_cmd("/faction_create_as", $id, $name, $leader));
		if ($output =~/\[SUCCESS\]/) {
			starmade_if_debug(1, "starmade_faction_create: return: 1");
			return 1;
		};
	}
	else {
		my $output = join("",starmade_cmd("/faction_create", $name, $leader));
		if ($output =~/\[SUCCESS\]/) {
			starmade_if_debug(1, "starmade_faction_create: return: 1");
			return 1;
		};
	}
	starmade_if_debug(1, "starmade_faction_create: return: 0");
	return 0;
};

## starmade_faction_delete
# Deletes a given faction
# INPUT1: faction id
# OUTPUT: 1 if successful, 0 if not
sub starmade_faction_delete {
	my $id = $_[0];

	starmade_if_debug(1, "starmade_faction_delete($id)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/faction_delete", $id));
	if ($output =~/\[SUCCESS\]/) {
		starmade_if_debug(1, "starmade_faction_delete: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_faction_delete: return: 0");
	return 0;
};

## starmade_faction_list_bid
# Get faction data in a hash table using the faction id as the key
# OUTPUT: hash table in the format of %hash{factionID}{someField} = field data
# All fields available and what they are:
# Field         What's in it
# name          faction name
# desc          faction description
# size          number of players in said faction
# points        number of faction points
sub starmade_faction_list_bid {
	my $raw = join("",starmade_cmd("/faction_list"));

	starmade_if_debug(1, "starmade_faction_list_bid()");
	starmade_validate_env();
	$raw=~s/^\$RETURN: \[SERVER, FACTIONS: \{Faction \[//;
	$raw=~s/\}, 0]\nRETURN: [SERVER, END; Admin command execution ended, 0]$//;

	my @factions = split('\], Faction \[', $raw);
	my %faction_list;
	foreach my $faction (@factions) {
		if (
			$faction=~/id=(\d+), name=(.*), description=(.*), size: (\d+); FP: (\d+)/ ||
			$faction=~/id=(-\d+), name=(.*), description=(.*), size: (\d+); FP: (\d+)/
		) {
			my $id = $1;
			$faction_list{$id}{name} = $2;
			$faction_list{$id}{desc} = $3;
			$faction_list{$id}{size} = $4;
			$faction_list{$id}{points} = $5;
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$id}{name} = $2");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$id}{desc} = $3");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$id}{size} = $4");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$id}{points} = $5");
			
		};
	};
	return \%faction_list;
};


## starmade_faction_list_bname
# Get faction data in a hash table using the faction name as the key.
# WARNING! the faction name is not necessarily unique, but it can be 
# useful to search by faction name. this funcion is mostly for convenience, 
# use it carefully.
# OUTPUT: hash table in the format of %hash{factionName}{someField} = field data
# All fields available and what they are:
# Field         What's in it
# id            faction id
# desc          faction description
# size          number of players in said faction
# points        number of faction points
sub starmade_faction_list_bname {
	my $raw = join("",starmade_cmd("/faction_list"));

	starmade_if_debug(1, "starmade_faction_list_bname()");
	starmade_validate_env();
	$raw=~s/^\$RETURN: \[SERVER, FACTIONS: \{Faction \[//;
	$raw=~s/\}, 0]\nRETURN: [SERVER, END; Admin command execution ended, 0]$//;

	my @factions = split('\], Faction \[', $raw);
	my %faction_list;
	foreach my $faction (@factions) {
		if ($faction=~/id=(\d+), name=(.*), description=(.*), size: (\d+); FP: (\d+)/ ||
			$faction=~/id=(-\d+), name=(.*), description=(.*), size: (\d+); FP: (\d+)/
		) {
			my $name = $2;
			$faction_list{$name}{id} = $1;
			$faction_list{$name}{desc} = $3;
			$faction_list{$name}{size} = $4;
			$faction_list{$name}{points} = $5;
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$name}{id} = $1");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$name}{desc} = $3");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$name}{size} = $4");
			starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$name}{points} = $5");
		};
	};
	return \%faction_list;
};


## starmade_faction_list_members
# Get a list of the players in a given faction
# INPUT1: faction id
# OUTPUT: array holding each faction member
sub starmade_faction_list_members {
	my $id = $_[0];

	starmade_if_debug(1, "starmade_faction_list_members($id)");
	starmade_validate_env();
	my $raw = join( "", starmade_cmd("/faction_list_members", $id));
	my @members_raw = split(' \[player', $raw);
	my %members;

	foreach my $member (@members_raw) {
		#UID=Jeryia, roleID=0]}, 0]
		if ($member=~/UID=(.*), roleID=(\S+)\]/) {
			my $name = $1;
			my $role = $2;
			$members{$name}{roleID} = $role;
			starmade_if_debug(1, "starmade_faction_list_members: return(multiline): %HASH{$name}{roleID} = $role");
		};
	};
	return \%members;

};

## starmade_faction_mod_relations
# Set the relations between two factions
# INPUT1: faction id of firest faction
# INPUT2: faction id of second faction
# INPUT3: relation (ally,enemy, or neutral)
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_mod_relations {
	my $faction1 = $_[0];
	my $faction2 = $_[1];
	my $relation = $_[2];

	starmade_if_debug(1, "starmade_faction_mod_relations($faction1, $faction2, $relation)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/faction_mod_relation", $faction1, $faction2, $relation));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_faction_mod_relations: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_faction_mod_relations: return: 1");
	return 1;
};


## starmade_faction_set_all_relations
# Set the relations between all factions
# INPUT1: relation (ally,enemy, or neutral
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_set_all_relations {
	my $relation = $_[0];

	starmade_if_debug(1, "starmade_faction_set_all_relations($relation)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/faction_set_all_relations", $relation));
	if ($output =~/ERROR/i) {
	starmade_if_debug(1, "starmade_faction_set_all_relations: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_faction_set_all_relations: return: 1");
	return 1;
};

## starmade_faction_add_member
# Add a player to a given faction.
# INPUT1: name of the player to add to the faction
# INPUT2: faction id of faction to join
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_add_member {
	my $player = $_[0];
	my $faction_id = $_[1];

	starmade_if_debug(1, "starmade_faction_add_member($player, $faction_id)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/faction_join_id", $player, $faction_id));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_faction_add_member: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_faction_add_member: return: 1");
	return 1;
};


## starmade_faction_del_member
# Remove a player from a faction
# INPUT1: Name of the player to remove from the faction
# INPUT2: faction id of the faction to remove the player from
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_del_member {
	my $player = $_[0];
	my $faction_id = $_[1];

	starmade_if_debug(1, "starmade_faction_del_member($player, $faction_id)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/faction_del_member", $player, $faction_id));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_faction_del_member: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_faction_del_member: return: 1");
	return 1;
};

1;
