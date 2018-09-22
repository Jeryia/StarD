package Starmade::Faction;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_faction_create starmade_faction_delete starmade_faction_list_bid starmade_faction_list_bname starmade_faction_list_members starmade_faction_mod_relations starmade_faction_set_all_relations starmade_faction_add_member starmade_faction_del_member starmade_player_suspend_faction starmade_player_unsuspend_faction);



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

	starmade_if_debug(1, "starmade_faction_list_bid()");
	starmade_validate_env();
	my @raw = starmade_cmd("/faction_list");

	my %faction_list;
	foreach my $faction (@raw) {
		# RETURN: [SERVER, FACTION: Faction [id=-2005, name=Neutral Fauna Fac 5, description=A Neutral Fanua Faction, size: 0; FP: 100]; HomeBaseName: ; HomeBaseUID: ; HomeBaseLocation: (0, 0, 0); Owned: [], 0]
		if ($faction=~/RETURN: \[SERVER, FACTION: Faction \[id=(-?\d+), name=(.*), description=(.*), size: (\d+); FP: (-?\d+)]; HomeBaseName: (.*); HomeBaseUID: (.*); HomeBaseLocation: \((-?\d+), (-?\d+), (-?\d+)\); Owned: \[(.*)\], 0\]/) {
			my $id = $1;
			$faction_list{$id}{name} = $2;
			$faction_list{$id}{desc} = $3;
			$faction_list{$id}{size} = $4;
			$faction_list{$id}{points} = $5;
			$faction_list{$id}{homeType} = $6;
			$faction_list{$id}{homeUID} = $7;
			$faction_list{$id}{homeLoc} = "$8 $9 $10";
			$faction_list{$id}{sectors} = $11;
			foreach my $key (sort keys %{$faction_list{$id}}) {
				starmade_if_debug(1, "starmade_faction_list_bid: return(multiline): %HASH{$id}{$key} = $faction_list{$id}{$key}");
			}
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

	my $faction_bid = starmade_faction_list_bid();
	my %faction_bname = ();
	foreach my $faction_id (keys %{$faction_bid}) {
		$faction_bname{$faction_bid->{$faction_id}{name}}{id} = $faction_id;
		foreach my $key (keys %{$faction_bid->{$faction_id}}) {
			$faction_bname{$faction_bid->{$faction_id}{name}}{$key} = $faction_bid->{$faction_id}{$key};
		}
	}
	return \%faction_bname;
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
			my $rank = $2;
			$members{$name} = $rank;
			starmade_if_debug(1, "starmade_faction_list_members: return(multiline): %HASH{$name} = $rank");
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
	return _starmade_pf_cmd('starmade_faction_mod_relations', '/faction_mod_relation', $faction1, $faction2, $relation);
};


## starmade_faction_set_all_relations
# Set the relations between all factions
# INPUT1: relation (ally,enemy, or neutral
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_set_all_relations {
	my $relation = $_[0];

	starmade_if_debug(1, "starmade_faction_set_all_relations($relation)");
	starmade_validate_env();
	return _starmade_pf_cmd('starmade_faction_set_all_relations', '/faction_set_all_relations', $relation);
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
	return _starmade_pf_cmd('starmade_faction_add_member', '/faction_join_id', $player, $faction_id);
};

## starmade_faction_mod_member
# Set the player's rank in the given faction
# INPUT1: name of the player to add to the faction
# INPUT2: rank (1-5) to set the player to. 1 founder
# OUTPUT: 1 if success, 0 if failure
sub starmade_faction_mod_member {
	my $player = $_[0];
	my $rank = $_[1];

	starmade_if_debug(1, "starmade_faction_mod_member($player, $rank)");
	starmade_validate_env();
	return _starmade_pf_cmd('starmade_faction_mod_member', '/faction_mod_member', $player, $rank);
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
	return _starmade_pf_cmd('starmade_faction_del_member', '/faction_del_member', $player, $faction_id);
};


## starmade_player_suspend_faction
# Temporarily remove player from their faction
# INPUT1: player
sub starmade_player_suspend_faction {
	# disabled until bug T3155 is fixed
	return 0;
	my $player = shift(@_);

	starmade_if_debug(1, "starmade_player_suspend_faction($player)");
	starmade_validate_env();
	
	my $output = join("", starmade_cmd("/player_suspend_faction", $player));
	if ($output =~/suspended faction for/) {
		starmade_if_debug(1, "starmade_player_suspend_faction: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_player_suspend_faction: return: 0");
	return 0;
}

## starmade_player_unsuspend_faction
# Temporarily remove player from their faction
# INPUT1: player
sub starmade_player_unsuspend_faction {
	# disabled until bug T3155 is fixed
	return 0;
	my $player = shift(@_);
	
	starmade_if_debug(1, "starmade_player_unsuspend_faction($player)");
	starmade_validate_env();

	my $output = join("", starmade_cmd("/player_unsuspend_faction", $player));
	if ($output =~/unsuspended faction for/) {
		starmade_if_debug(1, "starmade_player_unsuspend_faction: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_player_unsuspend_faction: return: 0");
	return 0;
}

1;
