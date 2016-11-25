package Starmade::Player;
use strict;
use warnings;
use Carp;

use Starmade::Message;

#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# StarMade™ is a registered trademark of Schine GmbH (All Rights Reserved)*
# The makers of starmade make no claim of ownership or relationship with the owners of StarMade

#### starmade_lib.pm
# primary perl library provided to assist with 
# programs in their communicating with starmade. 
# This library should be used by perl based 
# plugins and internally by starmade to talk to 
# the starmade deamon.
#
# NOTE the funtion starmade_setup_lib_env(PATH) needs to be called to use this library


require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(starmade_setup_lib_env starmade_run_if_admin starmade_is_admin starmade_admin_list starmade_player_list starmade_player_info starmade_change_sector_for starmade_teleport_to starmade_god_mode starmade_invisibility_mode starmade_give_credits starmade_give_item starmade_give_metaitem starmade_give_item_id starmade_give_all_items starmade_set_spawn_player);

use Starmade::Base;

## Global settings
# Location of the starmade server directory




## starmade_run_if_admin
# If the given player is not an admin, exit and send them a message
# INPUT1: player name
sub starmade_run_if_admin {
	my $player = $_[0];

	if (!starmade_is_admin($player)) {
		starmade_broadcast("$player, you are not an admin, and cannot run that command!");
		exit 1;
	}
}


## starmade_is_admin
# Check if a given player is an admin (note this 
# only checks the admin.txt file, not the actual 
# starmade server. We try to avoid directly 
# communicating with the starmade server when 
# possible to not interfere with it's operation
# INPUT1: player name
# OUTPUT: 1 if player is an admin, 0 if not.
sub starmade_is_admin {
	my $player = lc($_[0]);

	starmade_if_debug(1, "starmade_is_admin($player)");
	starmade_validate_env();
	my $starmade_server = get_server_home();
	open(my $admins_fh, "<", "$starmade_server/admins.txt");
	my @admins = <$admins_fh>;
	close($admins_fh);

	# if there isn't anyone in the admins.txt file starmade thinks everyone
	# is an admin
	if (!(@admins) || $player eq '') {
		return 1;
	}

	foreach my $admin (@admins) {
		$admin = lc($admin);
		$admin=~s/\s//ig;

		if ($player eq $admin) {
			starmade_if_debug(1, "starmade_is_admin: return: 1");
			return 1;
		};
	};
	starmade_if_debug(1, "starmade_is_admin: return: 0");
	return 0;
};


## starmade_admin_list
# Get a list of the current admins from the 
# admins.txt file
# OUTPUT: array of admins.
sub starmade_admin_list {
	starmade_if_debug(1, "starmade_admin_list()");
	starmade_validate_env();
	my $starmade_server = get_server_home();

	open(my $admins_fh, "<", "$starmade_server/admins.txt");
	my @admins = <$admins_fh>;
	foreach my $admin (@admins) {
		$admin =~s/\s//ig;
	};
	starmade_if_debug(1, "starmade_admin_list: return: (" . join(",", @admins) . ")");
	return \@admins;
};


## starmade_player_list
# query the starmade server for all players and information about each one
# OUTPUT: hash table in the format of %hash{playerName}{somefield} = 'field data'
# All fields available and what they are:
# Field         What's in it
# pos           player position in the sector
# control       entity the player is currently controling
# faction       faction id of the player's faction
# credits       how many credits the player has
# account       the starmade account for the player (different from the player's in game name)
# sector      The player's current sector (it's a space delimited string)
# ip            The player's ip address
sub starmade_player_list {
	my @raw = starmade_cmd("/player_list");
	starmade_if_debug(1, "starmade_player_list()");
	starmade_validate_env();

	my %player_list;
	my $pos;
	my $name;
	my $faction = 0;
	my $control;
	my $sector;
	my $smname;
	my $ip;
	my $credits;
	foreach my $line (@raw) {
		if ($line=~/RETURN: \[SERVER, \[PL\] CONTROLLING-POS: \((\S+), (\S+), (\S+)\), \S+\]/) {
			$pos = "$1 $2 $3";
		};
		if (
			$line=~/RETURN: \[SERVER, \[PL\] CONTROLLING: \S+\[(.+)\]\(\d+\), \d+\]/ ||
			$line=~/RETURN: \[SERVER, \[PL\] CONTROLLING: \S+\[\((.+)\)\(-?\d+\)\], \d+\]/
		) {

			$control = $1;
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SECTOR: \((.*)\), \d+\]/) {
			$sector = $1;
			$sector =~s/,//g;
			$sector =~s/\s\s//g;
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] FACTION: Faction \[id=(\d+), name=.*, description=.*, size: \d+; FP: \d+\], 0\]/) {
			$faction = $1;
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] CREDITS: (\d+), \S+\]/) {
			$credits = $1;
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SM-NAME: (.*), 0\]/) {
			$smname = $1;
		};
		if ($line=~/\[SERVER, \[PL\] IP: \/(\S+), 0\]/) {
			$ip = $1;
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] Name: (.+), 0\]/) {
			$name = $1;
			$player_list{$name}{pos} = $pos;
			$player_list{$name}{control} = $control;
			$player_list{$name}{faction} = $faction;
			$player_list{$name}{credits} = $credits;
			$player_list{$name}{smname} = $smname;
			$player_list{$name}{sector} = $sector;
			$player_list{$name}{ip} = $ip;
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{pos} = $pos");
			if ($control) {
				starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{control} = $control");
			}
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{faction} = $faction");
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{credits} = $credits");
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{smname} = $smname");
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{sector} = $sector");
			starmade_if_debug(1, "starmade_player_list: return(multiline): %HASH{$name}{ip} = $ip");

			$name = undef;
			$pos = undef;
			$control = undef;
			$faction = undef;
			$credits = undef;
			$smname = undef;
			$sector = undef;
			$ip = undef;
		};
	};
	
	return \%player_list;
};

## starmade_player_info
# query the starmade server for all players and information about each one
# INPUT1: player name
# OUTPUT: hash table in the format of %hash{playerName}{somefield} = 'field data'
# All fields available and what they are:
# Field         What's in it
# pos           player position in the sector
# control       entity the player is currently controling
# faction       faction id of the player's faction
# credits       how many credits the player has
# account       the starmade account for the player (different from the player's in game name)
# sector      The player's current sector (it's a space delimited string)
# ip            The player's ip address
sub starmade_player_info {
	my $player = $_[0];

	starmade_if_debug(1, "starmade_player_info($player)");
	my @raw = starmade_cmd("/player_info $player");
	starmade_validate_env();

	my %player_info;
	foreach my $line (@raw) {
		if ($line=~/RETURN: \[SERVER, \[PL\] CONTROLLING-POS: \((\S+), (\S+), (\S+)\), \S+\]/) {
			my $pos = "$1 $2 $3";
			$player_info{pos} = $pos;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{pos} = $pos");
		};
		#RETURN: [SERVER, [PL] CONTROLLING: Ship[TC Heavy Cruiser MKII_1441843270981](17), 0]
		if ($line=~/RETURN: \[SERVER, \[PL\] CONTROLLING: \S+\[(.+)\]\(\d+\), \d+\]/) {
			my $control = $1;
			$player_info{control} = $control;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{control} = $control");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SECTOR: \((.*)\), \d+\]/) {
			my $sector = $1;
			$sector =~s/,//g;
			$sector =~s/\s\s//g;
			$player_info{sector} = $sector;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{sector} = $sector");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] FACTION: Faction \[id=(\d+), name=.*, description=.*, size: \d+; FP: \d+\], 0\]/) {
			my $faction = $1;
			$player_info{faction} = $faction;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{faction} = $faction");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] CREDITS: (\d+), \S+\]/) {
			my $credits = $1;
			$player_info{credits} = $credits;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{credits} = $credits");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SM-NAME: (.*), 0\]/) {
			my $smname = $1;
			$player_info{smname} = $smname;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{smname} = $smname");
		};
		if ($line=~/\[SERVER, \[PL\] IP: \/(\S+), 0\]/) {
			my $ip = $1;
			$player_info{ip} = $ip;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{ip} = $ip");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] Name: (.+), 0\]/) {
			my $name = $1;
			$player_info{name} = $name;
			starmade_if_debug(1, "starmade_player_info: return(multiline): %HASH{name} = $name");
		};
	};
	
	return \%player_info;
};



## starmade_change_sector_for
# Change the current sector for a player
# INPUT1: name of the player you want to change the sector of
# INPUT2: sector to put the player (space delimited list)
# OUTPUT: 1 if success, 0 if failure
sub starmade_change_sector_for {
	my $player = $_[0];
	my $sector = $_[1];

	starmade_if_debug(1, "starmade_change_sector_for($player, $sector)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/change_sector_for", $player, split(" ", $sector)));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_change_sector_for: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_change_sector_for: return: 1");
	return 1;
};

## starmade_teleport_to
# change the position of the player in a given sector
# INPUT1: Player Name
# INPUT2: coords (space seperated list or floats)
# OUTPUT: success or failure
sub starmade_teleport_to {
	my $player = $_[0];
	my $pos = $_[1];

	starmade_if_debug(1, "starmade_teleport_to($player, $pos)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/teleport_to '$player' $pos"));
	if ($output =~/SUCCESS/i) {
		starmade_if_debug(1, "starmade_teleport_to: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_teleport_to: return: 0");
	return 0;
}


## starmade_god_mode
# Change the god mode status of a player
# INPUT1: player name
# INPUT2: (boolean) true to activate god mode, false to deactivate
# OUTPUT: (boolean) true if successful
sub starmade_god_mode {
	my $player = $_[0];
	my $mode = $_[1];

	starmade_if_debug(1, "starmade_god_mode($player, $mode)");
	if ($mode) {
		my @tmp = starmade_cmd("/god_mode '$player' true");
		my $output = join("", @tmp);
		if ($output=~/\[ADMIN COMMAND\] activated godmode for $player/) {
			return 1;
			starmade_if_debug(1, "starmade_god_mode: return 1");
		}
		starmade_if_debug(1, "starmade_god_mode: return 0");
		return 0;
	}
	else {
		my @tmp = starmade_cmd("/god_mode '$player' false");
		my $output = join("", @tmp);
		if ($output=~/\[ADMIN COMMAND\] deactivated godmode for $player/) {
			starmade_if_debug(1, "starmade_god_mode: return 1");
			return 1;
		}
		starmade_if_debug(1, "starmade_god_mode: return 0");
		return 0;
	}
}

## starmade_invisibility_mode
# Change the invisability mode status of a player
# INPUT1: player name
# INPUT2: (boolean) true to activate invisability mode, false to deactivate
# OUTPUT: (boolean) true if successful
sub starmade_invisibility_mode {
	my $player = $_[0];
	my $mode = $_[1];

	starmade_if_debug(1, "starmade_invisibility_mode($player, $mode)");
	if ($mode) {
		my @tmp = starmade_cmd("/invisibility_mode '$player' true");
		my $output = join("", @tmp);
		if ($output=~/\[ADMIN COMMAND\] activated invisibility for $player/) {
			starmade_if_debug(1, "starmade_invisibility_mode: return 1");
			return 1;
		}
		starmade_if_debug(1, "starmade_invisibility_mode: return 0");
		return 0;
		
	}
	else {
		my @tmp = starmade_cmd("/invisibility_mode '$player' false");
		my $output = join("", @tmp);
		if ($output=~/\[ADMIN COMMAND\] deactivated invisibility for $player/) {
			starmade_if_debug(1, "starmade_invisibility_mode: return 1");
			return 1;
		}
		starmade_if_debug(1, "starmade_invisibility_mode: return 0");
		return 0;
	}
}

## starmade_give_credits
# Give credits to player (note you can give a negative number to take them away as well.
# INPUT1: Player name
# INPUT2: Amount to give the player
# OUTPUT: 1 is success, 0 if failure
sub starmade_give_credits {
	my $player = $_[0];
	my $amount = int($_[1]);

	starmade_if_debug(1, "starmade_give_credits($player, $amount)");
	starmade_validate_env();
	my $output = join("",starmade_cmd("/give_credits", $player, $amount));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_give_credits: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_give_credits: return: 1");
	return 1;
};

## starmade_give_item
# Give the player specified item (name)
# INPUT1: Player to give the item to
# INPUT2: Name of the item to give
# INPUT3: Amount of item to give
# OUTPUT: 1 if success, 0 if failure
sub starmade_give_item {
	my $player = $_[0];
	my $item = $_[1];
	my $amount = int($_[2]);

	starmade_if_debug(1, "starmade_give_item($player, $item, $amount)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/give", $player, $item, $amount));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_give_item: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_give_item: return: 1");
	return 1;
};

## starmade_give_metaitem
# Give the player specified meta item 
# INPUT1: Player to give the item to
# INPUT2: Name of the meta item to give.
# OUTPUT: 1 if success, 0 if failure
sub starmade_give_metaitem {
	my $player = $_[0];
	my $item = $_[1];

	starmade_if_debug(1, "starmade_give_metaitem($player, $item)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/give_metaitem", $player, $item));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_give_metaitem: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_give_metaitem: return: 1");
	return 1;
};

## starmade_give_item_id
# Give the player specified item (name)
# INPUT1: Player to give the item to
# INPUT2: Id of the item to give
# INPUT3: Amount of item to give
# OUTPUT: 1 if success, 0 if failure
sub starmade_give_item_id {
	my $player = $_[0];
	my $item = int($_[1]);
	my $amount = int($_[2]);

	starmade_if_debug(1, "starmade_give_item_id($player, $item, $amount)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/giveid", $player, $item, $amount));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_give_item_id: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_give_item_id: return: 1");
	return 1;
};

## starmade_give_all_items
# Give specified player all items (usefull for taking away all items ironically)
# INPUT1: Player to give to
# INPUT2: Amount to give them
# OUTPUT: 1 if success, 0 if failure
sub starmade_give_all_items {
	my $player = $_[0];
	my $amount = int($_[1]);

	starmade_if_debug(1, "starmade_give_all_items($player, $amount)");
	starmade_validate_env();
	my $output = starmade_cmd("/give_all_items", $player, $amount);
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_give_all_items: return: 0");
		return 0;
	}
	starmade_if_debug(1, "starmade_give_all_items: return: 1");
	return 1;
};

## starmade_set_spawn_player
# Set the player's current position to be that player's spawn sector
# INPUT1: name of player
# OUTPUT: 1 if success, 0 if failure
sub starmade_set_spawn_player {
	my $player = $_[0];

	starmade_if_debug(1, "starmade_set_spawn_player($player)");
	starmade_validate_env();
	my $output = join("", starmade_cmd("/set_spawn_player", $player));
	if ($output =~/ERROR/i) {
		starmade_if_debug(1, "starmade_set_spawn_player: return: 0");
		return 0;
	};
	starmade_if_debug(1, "starmade_set_spawn_player: return: 1");
	return 1;
};

1;
