package stard_lib;
use strict;
#use warnings;
use Carp;
use Config::IniFiles;


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
# The makers of stard make no claim of ownership or relationship with the owners of StarMade

#### stard_lib.pm
# primary perl library provided to assist with 
# programs in their communicating with starmade. 
# This library should be used by perl based 
# plugins and internally by stard to talk to 
# the starmade deamon.
#
# NOTE the funtion stard_setup_run_env(PATH) needs to be called to use this library

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(stard_setup_run_env bash_escape_chars starmade_escape_chars stard_validate_env stard_stdlib_set_debug stard_if_debug stard_read_config stard_cmd stard_broadcast stard_pm stard_run_if_admin stard_is_admin stard_admin_list stard_player_list stard_player_info stard_faction_create stard_faction_delete stard_faction_list_bid stard_faction_list_bname stard_faction_list_members stard_give_credits stard_give_item stard_give_item_id stard_give_all_items stard_despawn_sector stard_despawn_all stard_spawn_entity stard_spawn_entity_pos stard_search stard_faction_mod_relations stard_faction_set_all_relations stard_faction_add_member stard_faction_del_member stard_change_sector_for stard_sector_chmod stard_sector_info stard_set_spawn_player starmade_read_starmade_server_config stard_get_starmade_conf_field stard_get_main_conf_field stard_teleport_to stard_loc_distance stard_location_add stard_last_output);


## Global settings
# Location of stard's home directory
our $stard_home;
# Location of the starmade directory (usually /var/starmade)
our $starmade_home;
# Location of the starmade server directory
our $starmade_server;
# Hash of the stard config file
our %stard_config;
# Hash of the starmade config file
our %starmade_config;
# Put the command we are to run together when running starmade commands.
our $stard_cmd;
# Current level of debugging set
our $debug_level = 0;
our %blank_hash = ();
# The output of the last command run (used for debugging)
our $stard_last_output;



## stard_setup_run_env
# setup up basic variables for the stard library. 
# This tells the library where stard's home 
# folder is (by default /var/starmade/stard but 
# we can't be sure so anyone who calls this 
# library needs to tell it where stard is located.
# INPUT1: location of stard home
sub stard_setup_run_env {
	$stard_home = $_[0];

	stard_if_debug(2, "stard_setup_run_env($stard_home)");
	$starmade_home = "$stard_home/..";
	$starmade_server = "$starmade_home/StarMade";
	%stard_config = %{stard_read_config("$stard_home/stard.cfg")};
	%starmade_config = %{starmade_read_starmade_server_config()};

	$stard_cmd = "/usr/bin/java -jar $stard_home/$stard_config{General}{stard_connect_cmd} ";
	$stard_cmd .= bash_escape_chars($stard_config{General}{server}) . " ";
	if ($stard_config{General}{password} =~/\S/) {
		$stard_cmd .= bash_escape_chars($stard_config{General}{password});
	}
	else {
		$stard_cmd .= bash_escape_chars($starmade_config{SUPER_ADMIN_PASSWORD});
	}	
	stard_if_debug(2, "stard_setup_run_env: return:");
};


## bash_escape_chars
# Cleans up the given string to ensure that bash handles it proporly. (no bobby tables :))
# INPUT: string to clean
# OUTPUT: cleaned up string.
sub bash_escape_chars {
	my $string = $_[0];

	stard_if_debug(2, "bash_escape_chars($string)");
	my @chars = split("",$string);

	my $valid_chars = "abcdefghijklmnopqrstuvwxyz1234567890_/ \t@#%^&*()-+\[\].,<>?!':;\{\}=";
	my $output;


	foreach my $char (@chars) {
		if ($valid_chars=~/\Q$char\E/i) {
			$output .= $char;
		}
		else {
			$output .= "\\$char";
		};
	};
	$output = "\"$output\"";
	stard_if_debug(2, "bash_escape_chars: return: $output");
	return $output;
};

## starmade_escape_chars
# Cleans up the given string to ensure that starmade handles it proporly. (no bobby tables :))
# INPUT: string to clean
# OUTPUT: cleaned up string.
sub starmade_escape_chars {
	my $string = $_[0];

	stard_if_debug(2, "starmade_escape_chars($string)");
	my @chars = split("",$string);

	my $valid_chars = "abcdefghijklmnopqrstuvwxyz1234567890_/ \t@#%^&*()-+\[\].,<>?!\":;\{\}\(\)\*\&\^!";
	my $output;


	foreach my $char (@chars) {
		if ($valid_chars=~/\Q$char\E/i) {
			$output .= $char;
		}
		# starmade can't handle escaping in it's strings, so we just remove characters we are not sure of
	};
	$output = "'$output'";
	stard_if_debug(2, "starmade_escape_chars: return: $output");
	return $output;
};

## stard_validate_env
# validates that the stard_setup_run_env has been called, and we're setup ok.
sub stard_validate_env {
	if (! ($stard_home =~/\S/)) {
		croak("stard_home has not been set! the function stard_setup_run_env, with a valid stard_home needs to be called before any other functions in the stard_stdlib");
	}
}

## stard_stdlib_set_debug
# Set the debug level for this library
# INPUT1: level to set debugging. (1 will print out inputs and outputs to all 
# functions except stard_cmd, bash_escape_chars, validate_env, and starmade_escape_chars). 
# Setting this to 2 will get you all functions input and output.
sub stard_stdlib_set_debug {
	my $debug = $_[0];
	$debug_level = $debug;
	stard_if_debug(1, "set_debug($debug)");
	stard_if_debug(1, "stard_lib debugging set to $debug!");
}

## stard_if_debug
# prints out the message if the debug_level is high enough.
# INPUT1: debug level of message
# INPUT2: message
sub stard_if_debug {
	my $level = $_[0];
	my $message = $_[1];
	if ($level <= $debug_level) {
		print $message;
		print "\n";
	}
}

## stard_read_config
# Used to read ini stype config files
# INPUT1: location of config file
# OUTPUT: 2d hash of config file contents
sub stard_read_config {
	my $file = $_[0];

	stard_if_debug(2, "stard_read_config($file)");
	my %config;
	if (!tie(%config, 'Config::IniFiles', ( -file => $file))) {
		warn "@Config::IniFiles::errors\n";
		stard_if_debug(2, "stard_read_config: return: ()");
		return \%blank_hash;
	}


	foreach my $key1 (keys %config) {
		if ($debug_level >= 2) {
			print "stard_read_config: return(multiline): [$key1]\n";
		}
		foreach my $key2 (keys %{$config{$key1}}) {
			if ($debug_level >= 2) {
				print "stard_read_config: return(multiline): $key2 = '$config{$key1}{$key2}'\n";
			}
			$config{$key1}{$key2}=~s/^\s+//g;
			$config{$key1}{$key2}=~s/\s+$//g;
			$config{$key1}{$key2}=~s/^'//;
			$config{$key1}{$key2}=~s/'$//;
			$config{$key1}{$key2}=~s/^"//;
			$config{$key1}{$key2}=~s/"$//;
		}
	}
	return \%config;
};

## stard_cmd
# Runs a starmade command against the running starmade server
# INPUT1: (string) command to run against the server (should start with a /)
# OUTPUT: (array) newline delimited array of what the starmade server responded with.
sub stard_cmd {
	my $cmd = shift(@_);
	my @args = @_;

	stard_if_debug(2, "stard_cmd($cmd, " . join(", ", @args) . ")");
	stard_validate_env();
	foreach my $entry (@args) {
		$entry = starmade_escape_chars($entry);
	};

	my $arg = join(" ", @args);
	my $starmade_input = bash_escape_chars("$cmd $arg");

	my @output = `timeout $stard_config{General}{connect_timeout} $stard_cmd $starmade_input 2>&1`;

	stard_if_debug(2, "stard_cmd: return @output");
	$stard_last_output = join("", @output);
	return @output;
};

## fix_newlines
# As starmade does not recognize the new line character, we simulate it with 
# spaces, as lines wrap in chat
# INPUT1: message
# OUTPUT: modified message
sub fix_newlines {
	my $message = $_[0];

	# length of line required to cause it to wrap
	my $line_len = 300;
	my @lines = split("\n", $message);

	# Iterate over all but the last one
	for (my $line_num = 0; $line_num < $#lines; $line_num++) {
		my $len = length($lines[$line_num]);
		my $whitespace = " " x ($line_len - $len);
		$lines[$line_num] .= $whitespace;
	}
	return join("", @lines);
}

## stard_broadcast
# Broadcast a server message to all players on the starmade server.
# INPUT1: message to broadcast
# OUTPUT: 1 if successfull, 0 is not
sub stard_broadcast {
	my $message = $_[0];

	stard_if_debug(1, "stard_broadcast($message)");
	stard_validate_env();

	$message = fix_newlines($message);
	my $out = join("",stard_cmd("/chat $message"));
	if ($out =~/\Qbroadcasted as server message:\E/) {
		stard_if_debug(2, "stard_broadcast: return: 1");
		return 1;
	};
	stard_if_debug(1, "stard_broadcast: return: 0");
	return 0;
};

## stard_pm
# send a private message to a player
# INPUT1: player to send message to
# INPUT2: message to send
# OUTPUT: 1 if successful, 0 if not
sub stard_pm {
	my $player = $_[0];
	my $message = $_[1];

	stard_if_debug(1, "stard_pm($player, $message)");
	stard_validate_env();
	$message = fix_newlines($message);
	if ($player =~/\S/) {
		my $out = join("",stard_cmd("/pm $player $message"));
		if ($out =~/\Qsend to $player as server message:\E/) {
			stard_if_debug(1, "stard_pm: return: 1");
			return 1;
		};
	}
	else {
		print $message;
		print "\n";
		stard_if_debug(1, "stard_pm: return: 1");
		return 1;
	}
	stard_if_debug(1, "stard_pm: return: 0");
	return 0;
};

## stard_run_if_admin
# If the given player is not an admin, exit and send them a message
# INPUT1: player name
sub stard_run_if_admin {
	my $player = $_[0];

	if (!stard_is_admin($player)) {
		stard_broadcast("$player, you are not an admin, and cannot run that command!");
		exit 1;
	}
}


## stard_is_admin
# Check if a given player is an admin (note this 
# only checks the admin.txt file, not the actual 
# starmade server. We try to avoid directly 
# communicating with the starmade server when 
# possible to not interfere with it's operation
# INPUT1: player name
# OUTPUT: 1 if player is an admin, 0 if not.
sub stard_is_admin {
	my $player = lc($_[0]);

	stard_if_debug(1, "stard_is_admin($player)");
	stard_validate_env();
	open(my $admins_fh, "<", "$starmade_server/admins.txt");
	my @admins = <$admins_fh>;
	close($admins_fh);

	# if there isn't anyone in the admins.txt file starmade thinks everyone
	# is an admin
	if (!(@admins)) {
		return 1;
	}

	foreach my $admin (@admins) {
		$admin = lc($admin);
		$admin=~s/\s//ig;

		if ($player eq $admin) {
			stard_if_debug(1, "stard_is_admin: return: 1");
			return 1;
		};
	};
	stard_if_debug(1, "stard_is_admin: return: 0");
	return 0;
};


## stard_admin_list
# Get a list of the current admins from the 
# admins.txt file
# OUTPUT: array of admins.
sub stard_admin_list {
	stard_if_debug(1, "stard_admin_list()");
	stard_validate_env();
	open(my $admins_fh, "<", "$starmade_server/admins.txt");
	my @admins = <$admins_fh>;
	foreach my $admin (@admins) {
		$admin =~s/\s//ig;
	};
	stard_if_debug(1, "stard_admin_list: return: (" . join(",", @admins) . ")");
	return \@admins;
};


## stard_player_list
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
sub stard_player_list {
	my @raw = stard_cmd("/player_list");
	stard_if_debug(1, "stard_player_list()");
	stard_validate_env();

	my %player_list;
	my $pos;
	my $name;
	my $faction;
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
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{pos} = $pos");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{control} = $control");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{faction} = $faction");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{credits} = $credits");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{smname} = $smname");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{sector} = $sector");
			stard_if_debug(1, "stard_player_list: return(multiline): %HASH{$name}{ip} = $ip");

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

## stard_player_info
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
sub stard_player_info {
	my $player = $_[0];

	my @raw = stard_cmd("/player_info $player");
	stard_if_debug(1, "stard_player_info($player)");
	stard_validate_env();

	my %player_info;
	foreach my $line (@raw) {
		if ($line=~/RETURN: \[SERVER, \[PL\] CONTROLLING-POS: \((\S+), (\S+), (\S+)\), \S+\]/) {
			my $pos = "$1 $2 $3";
			$player_info{pos} = $pos;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{pos} = $pos");
		};
		#RETURN: [SERVER, [PL] CONTROLLING: Ship[TC Heavy Cruiser MKII_1441843270981](17), 0]
		if ($line=~/RETURN: \[SERVER, \[PL\] CONTROLLING: \S+\[(.+)\]\(\d+\), \d+\]/) {
			my $control = $1;
			$player_info{control} = $control;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{control} = $control");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SECTOR: \((.*)\), \d+\]/) {
			my $sector = $1;
			$sector =~s/,//g;
			$sector =~s/\s\s//g;
			$player_info{sector} = $sector;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{sector} = $sector");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] FACTION: Faction \[id=(\d+), name=.*, description=.*, size: \d+; FP: \d+\], 0\]/) {
			my $faction = $1;
			$player_info{faction} = $faction;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{faction} = $faction");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] CREDITS: (\d+), \S+\]/) {
			my $credits = $1;
			$player_info{credits} = $credits;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{credits} = $credits");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] SM-NAME: (.*), 0\]/) {
			my $smname = $1;
			$player_info{smname} = $smname;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{smname} = $smname");
		};
		if ($line=~/\[SERVER, \[PL\] IP: \/(\S+), 0\]/) {
			my $ip = $1;
			$player_info{ip} = $ip;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{ip} = $ip");
		};
		if ($line=~/RETURN: \[SERVER, \[PL\] Name: (.+), 0\]/) {
			my $name = $1;
			$player_info{name} = $name;
			stard_if_debug(1, "stard_player_info: return(multiline): %HASH{name} = $name");
		};
	};
	
	return \%player_info;
};



## stard_faction_create
# Creates a faction with a given leader
# INPUT1: faction name
# INPUT2: the leader of said faction
# OUTPUT: 1 if successful, 0 if not
sub stard_faction_create {
	my $name = $_[0];
	my $leader = $_[1];

	stard_if_debug(1, "stard_faction_create($name, $leader)");
	stard_validate_env();
	my $output = join("",stard_cmd("/faction_create", $name, $leader));
	if ($output =~/\[SUCCESS\]/) {
		stard_if_debug(1, "stard_faction_create: return: 1");
		return 1;
	};
	stard_if_debug(1, "stard_faction_create: return: 0");
	return 0;
};

## stard_faction_delete
# Deletes a given faction
# INPUT1: faction id
# OUTPUT: 1 if successful, 0 if not
sub stard_faction_delete {
	my $id = $_[0];

	stard_if_debug(1, "stard_faction_create($id)");
	stard_validate_env();
	my $output = join("", stard_cmd("/faction_delete", $id));
	if ($output =~/\[SUCCESS\]/) {
		stard_if_debug(1, "stard_faction_create: return: 1");
		return 1;
	};
	stard_if_debug(1, "stard_faction_create: return: 0");
	return 0;
};

## stard_faction_list_bid
# Get faction data in a hash table using the faction id as the key
# OUTPUT: hash table in the format of %hash{factionID}{someField} = field data
# All fields available and what they are:
# Field         What's in it
# name          faction name
# desc          faction description
# size          number of players in said faction
# points        number of faction points
sub stard_faction_list_bid {
	my $raw = join("",stard_cmd("/faction_list"));

	stard_if_debug(1, "stard_faction_list_bid()");
	stard_validate_env();
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
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$id}{name} = $2");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$id}{desc} = $3");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$id}{size} = $4");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$id}{points} = $5");
			
		};
	};
	return \%faction_list;
};


## stard_faction_list_bname
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
sub stard_faction_list_bname {
	my $raw = join("",stard_cmd("/faction_list"));

	stard_if_debug(1, "stard_faction_list_bname()");
	stard_validate_env();
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
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$name}{id} = $1");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$name}{desc} = $3");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$name}{size} = $4");
			stard_if_debug(1, "stard_faction_list_bid: return(multiline): %HASH{$name}{points} = $5");
		};
	};
	return \%faction_list;
};


## stard_faction_list_members
# Get a list of the players in a given faction
# INPUT1: faction id
# OUTPUT: array holding each faction member
sub stard_faction_list_members {
	my $id = $_[0];

	stard_if_debug(1, "stard_faction_list_members($id)");
	stard_validate_env();
	my $raw = join( "", stard_cmd("/faction_list_members", $id));
	my @members_raw = split(' \[player', $raw);
	my %members;

	foreach my $member (@members_raw) {
		#UID=Jeryia, roleID=0]}, 0]
		if ($member=~/UID=(.*), roleID=(\S+)\]/) {
			my $name = $1;
			my $role = $2;
			$members{$name}{roleID} = $role;
			stard_if_debug(1, "stard_faction_list_members: return(multiline): %HASH{$name}{roleID} = $role");
		};
	};
	return \%members;

};

## stard_give_credits
# Give credits to player (note you can give a negative number to take them away as well.
# INPUT1: Player name
# INPUT2: Amount to give the player
# OUTPUT: 1 is success, 0 if failure
sub stard_give_credits {
	my $player = $_[0];
	my $amount = int($_[1]);

	stard_if_debug(1, "stard_give_credits($player, $amount)");
	stard_validate_env();
	my $output = join("",stard_cmd("/give_credits", $player, $amount));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_give_credits: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_give_credits: return: 1");
	return 1;
};


## stard_give_item
# Give the player specified item (name)
# INPUT1: Player to give the item to
# INPUT2: Name of the item to give
# INPUT3: Amount of item to give
# OUTPUT: 1 if success, 0 if failure
sub stard_give_item {
	my $player = $_[0];
	my $item = $_[1];
	my $amount = int($_[2]);

	stard_if_debug(1, "stard_give_item($player, $item, $amount)");
	stard_validate_env();
	my $output = join("", stard_cmd("/give", $player, $item, $amount));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_give_item: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_give_item: return: 1");
	return 1;
};

## stard_give_item_id
# Give the player specified item (name)
# INPUT1: Player to give the item to
# INPUT2: Id of the item to give
# INPUT3: Amount of item to give
# OUTPUT: 1 if success, 0 if failure
sub stard_give_item_id {
	my $player = $_[0];
	my $item = int($_[1]);
	my $amount = int($_[2]);

	stard_if_debug(1, "stard_give_item_id($player, $item, $amount)");
	stard_validate_env();
	my $output = join("", stard_cmd("/giveid", $player, $item, $amount));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_give_item_id: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_give_item_id: return: 1");
	return 1;
};

## stard_give_all_items
# Give specified player all items (usefull for taking away all items ironically)
# INPUT1: Player to give to
# INPUT2: Amount to give them
# OUTPUT: 1 if success, 0 if failure
sub stard_give_all_items {
	my $player = $_[0];
	my $amount = int($_[1]);

	stard_if_debug(1, "stard_give_all_items($player, $amount)");
	stard_validate_env();
	my $output = stard_cmd("/give_all_items", $player, $amount);
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_give_all_items: return: 0");
		return 0;
	}
	stard_if_debug(1, "stard_give_all_items: return: 1");
	return 1;
};

## stard_despawn_sector
# Despawns all entities in the given sector that start with the given name
# INPUT1: pattern of entity to delete (give it '' if you want everything)
# INPUT2: mode (used,unused, or all)
# INPUT3: shipOnly (true or false)
# INPUT4: sector (space delimited string)
# OUTPUT: 1 if success, 0 if failure
sub stard_despawn_sector {
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

	stard_if_debug(1, "stard_despawn_sector($pattern, $mode, $ship_only, $sector)");
	stard_validate_env();
	my $output = join("", stard_cmd("/despawn_sector", $pattern, $mode, $ship_only, split(' ', $sector)));
	if ($output =~/SUCCESS/i) {
		stard_if_debug(1, "stard_despawn_sector: return 1");
		return 1;
	};
	stard_if_debug(1, "stard_despawn_sector: return 0");
	return 0;
};

## stard_despawn_all
# Despawns all entities in the given sector that start with the given name
# INPUT1: pattern of entity to delete (give it '' if you want everything)
# INPUT2: mode (used,unused, or all)
# INPUT3: shipOnly (true or false)
# OUTPUT: 1 if success, 0 if failure
sub stard_despawn_all {
	my $pattern = $_[0];
	my $mode = $_[1];
	my $ship_only = $_[2];

	if ($ship_only) {
		$ship_only = 'true';
	}
	else {
		$ship_only = 'false';
	}

	stard_if_debug(1, "stard_despawn_sector($pattern, $mode, $ship_only)");
	stard_validate_env();
	my $output = join("", stard_cmd("/despawn_all", $pattern, $mode, $ship_only));
	if ($output =~/SUCCESS/i) {
		stard_if_debug(1, "stard_despawn_sector: return: 1");
		return 1;
	};
	stard_if_debug(1, "stard_despawn_sector: return: 0");
	return 0;
};

## stard_spawn_entity
# Spawn the given blueprint with the given name
# INPUT1: Blueprint to use
# INPUT2: Name to give the entity (carefull, this needs to be unique in the game
# INPUT3: Sector to spawn the entity in (space separated list)
# INPUT4: Faction id of the faction the entity is to belong to
# INPUT5: true if ai is to be active, false if not.
# OUTPUT: 1 if success, 0 if failure.
sub stard_spawn_entity {
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

	stard_if_debug(1, "stard_spawn_entity($blueprint, $name, $sector, $faction, $ai)");
	stard_validate_env();
	my $output = join("", stard_cmd("/spawn_entity", $blueprint, $name, split(" ", $sector), $faction, $ai));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_spawn_entity: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_spawn_entity: return: 1");
	return 1;
};

## stard_spawn_entity_pos
# Spawn the given blueprint with the given name
# INPUT1: Blueprint to use
# INPUT2: Name to give the entity (carefull, this needs to be unique in the game
# INPUT3: Sector to spawn the entity in (space seperated list)
# INPUT4: POS to spawn the entity in (space seperated list)
# INPUT5: Faction id of the faction the entity is to belong to
# INPUT6: true if ai is to be active, false if not.
# OUTPUT: 1 if success, 0 if failure.
sub stard_spawn_entity_pos {
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

	stard_if_debug(1, "stard_spawn_entity_pos($blueprint, $name, $sector, $pos, $faction, $ai)");
	stard_validate_env();
	my $output = join("", stard_cmd("/spawn_entity_pos", $blueprint, $name, split(" ",$sector), split(' ', $pos), $faction, $ai));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_spawn_entity: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_spawn_entity: return: 1");
	return 1;
};

## stard_search 
# Locate ships/stations that start with the given pattern
# INPUT1: pattern
# OUTPUT: hash of result ships -> sector
sub stard_search {
	my $pattern = $_[0];
	
	stard_if_debug(1, "stard_search($pattern)");
	stard_validate_env();
	my @output = stard_cmd("/search", $pattern);
	my %ships;

	foreach my $line (@output) {
		#RETURN: [SERVER, FOUND: Station_Piratestation Alpha_6_9_0_1441738472505 -> (6, 9, 0), 0]
		if ($line=~/RETURN: \[SERVER, FOUND: (.*) -> \((\d+), (\d+), (\d+)\), \d+]/) {
			$ships{$1} = "$2 $3 $4";
			stard_if_debug(1, "stard_search: return(multiline): %HASH{$1} = '$2 $3 $4'");
		}
	}
	return \%ships;
}

## stard_faction_mod_relations
# Set the relations between two factions
# INPUT1: faction id of firest faction
# INPUT2: faction id of second faction
# INPUT3: relation (ally,enemy, or neutral)
# OUTPUT: 1 if success, 0 if failure
sub stard_faction_mod_relations {
	my $faction1 = $_[0];
	my $faction2 = $_[1];
	my $relation = $_[2];

	stard_if_debug(1, "stard_faction_mod_relations($faction1, $faction2, $relation)");
	stard_validate_env();
	my $output = join("", stard_cmd("/faction_mod_relation", $faction1, $faction2, $relation));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_faction_mod_relations: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_faction_mod_relations: return: 1");
	return 1;
};


## stard_faction_set_all_relations
# Set the relations between all factions
# INPUT1: relation (ally,enemy, or neutral
# OUTPUT: 1 if success, 0 if failure
sub stard_faction_set_all_relations {
	my $relation = $_[0];

	stard_if_debug(1, "stard_faction_set_all_relations($relation)");
	stard_validate_env();
	my $output = join("", stard_cmd("/faction_set_all_relations", $relation));
	if ($output =~/ERROR/i) {
	stard_if_debug(1, "stard_faction_set_all_relations: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_faction_set_all_relations: return: 1");
	return 1;
};

## stard_faction_add_member
# Add a player to a given faction.
# INPUT1: name of the player to add to the faction
# INPUT2: faction id of faction to join
# OUTPUT: 1 if success, 0 if failure
sub stard_faction_add_member {
	my $player = $_[0];
	my $faction_id = $_[1];

	stard_if_debug(1, "stard_faction_add_member($player, $faction_id)");
	stard_validate_env();
	my $output = join("", stard_cmd("/faction_join_id", $player, $faction_id));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_faction_add_member: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_faction_add_member: return: 1");
	return 1;
};


## stard_faction_del_member
# Remove a player from a faction
# INPUT1: Name of the player to remove from the faction
# INPUT2: faction id of the faction to remove the player from
# OUTPUT: 1 if success, 0 if failure
sub stard_faction_del_member {
	my $player = $_[0];
	my $faction_id = $_[1];

	stard_if_debug(1, "stard_faction_del_member($player, $faction_id)");
	stard_validate_env();
	my $output = join("", stard_cmd("/faction_del_member", $player, $faction_id));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_faction_del_member: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_faction_del_member: return: 1");
	return 1;
};

## stard_change_sector_for
# Change the current sector for a player
# INPUT1: name of the player you want to change the sector of
# INPUT2: sector to put the player (space delimited list)
# OUTPUT: 1 if success, 0 if failure
sub stard_change_sector_for {
	my $player = $_[0];
	my $sector = $_[1];

	stard_if_debug(1, "stard_faction_del_member($player, $sector)");
	stard_validate_env();
	my $output = join("", stard_cmd("/change_sector_for", $player, split(" ", $sector)));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_faction_del_member: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_faction_del_member: return: 1");
	return 1;
};

## stard_sector_chmod
# Change the properties of a sector
# INPUT1: sector to put the player (space delimited list)
# INPUT2: add/remove
# INPUT3: setting (peace, protected, noenter, noexit, noindications, nofploss)
# OUTPUT: 1 if success, 0 if failure
sub stard_sector_chmod {
	my $sector = $_[0];
	my $modifier = $_[1];
	my $setting = $_[2];
	
	stard_if_debug(1, "stard_sector_chmod($sector, $modifier, $setting)");
	stard_validate_env();
	my $output;
	$modifier =~s/add/+/g;
	$modifier =~s/remove/-/g;

	$output = join("", stard_cmd("/sector_chmod", split(" ", $sector), $modifier, $setting));
	if ($output =~/SUCCESS/i) {
		stard_if_debug(1, "stard_sector_chmod: return 1");
		return 1;
	};
	stard_if_debug(1, "stard_sector_chmod: return 0");
	return 0;
};

## stard_sector_info
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
sub stard_sector_info {
	my $sector = $_[0];

	stard_if_debug(1, "stard_sector_info($sector)");
	stard_validate_env();
	my @output = stard_cmd("/sector_info", split(" ", $sector));
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
			stard_if_debug(1, "stard_sector_info: return(multiline): %HASH{entity}{$name}{faction} = $faction_id");
			stard_if_debug(1, "stard_sector_info: return(multiline): %HASH{entity}{$name}{pos} = $pos");
		}
		if ($line=~/RETURN: \[SERVER, LOADED SECTOR INFO: Sector\[\d+\]\(\S+, \S+, \S+\); Protected: (\S+); Peace: (\S+); Seed: \S+; Type: \S+;, \d+\]/) {
			my $protected = $1;
			my $peace = $2;
			$protected=~s/true/1/ig;
			$protected=~s/false/0/ig;
			$peace=~s/true/1/ig;
			$peace=~s/false/0/ig;

			$sector_info{general}{info}{protected} = int($protected);
			$sector_info{general}{info}{peace} = int($peace);
			stard_if_debug(1, "stard_sector_info: return(multiline): %HASH{general}{info}{protected} = $protected");
			stard_if_debug(1, "stard_sector_info: return(multiline): %HASH{general}{info}{peace} = $peace");
		};
	};
	return \%sector_info;
};




## stard_set_spawn_player
# Set the player's current position to be that player's spawn sector
# INPUT1: name of player
# OUTPUT: 1 if success, 0 if failure
sub stard_set_spawn_player {
	my $player = $_[0];

	stard_if_debug(1, "stard_set_spawn_player($player)");
	stard_validate_env();
	my $output = join("", stard_cmd("/set_spawn_player", $player));
	if ($output =~/ERROR/i) {
		stard_if_debug(1, "stard_set_spawn_player: return: 0");
		return 0;
	};
	stard_if_debug(1, "stard_set_spawn_player: return: 1");
	return 1;
};

## stard_read_starmade_server_config
# Get the curent starmade config file in hash format
# OUTPUT: hash of starmade config file
sub starmade_read_starmade_server_config {

	stard_if_debug(2, "starmade_read_starmade_server_config()");
	stard_validate_env();
	my %config;
	open(my $config_fh, "<", "$starmade_server/server.cfg");
	my @lines = <$config_fh>;
	close($config_fh);
	Line: foreach my $line (@lines) {
		if ($line =~/\/\//) {
			my @tmp = split("\/\/", $line);
			$line = $tmp[0];
		}
		if ($line=~/^(\S+)\s+=(.*)/) {
			my $field = $1;
			my $value = $2;
			# trim out any whitespace at the beginning or end
			$field=~s/^\s+//ig;
			$field=~s/\s+$//ig;
			$value=~s/^\s+//ig;
			$value=~s/\s+$//ig;
			
			$config{$field} = $value;
			$config{$field}=~s/^\s+//g;
			stard_if_debug(2, "starmade_read_starmade_server_config: return(multiline): %HASH{$field} = $value");
		};
	};
	return \%config;
};

## stard_get_starmade_conf_field
# get a specific field from the starmade config file
# INPUT1: field to grab
# OUTPUT: value of field
sub stard_get_starmade_conf_field {
	my $field = $_[0];

	stard_if_debug(1, "stard_get_starmade_conf_field($field)");
	stard_validate_env();
	stard_if_debug(1, "stard_get_starmade_conf_field: return: $starmade_config{$field}");
	return $starmade_config{$field};
}

## stard_get_main_conf_field
# get a specific field from the stard.cfg file
# INPUT1: field to grab
# OUTPUT: value of field
sub stard_get_main_conf_field {
	my $field = $_[0];

	stard_if_debug(1, "stard_get_main_conf_field($field)");
	stard_validate_env();
	stard_if_debug(1, "stard_get_main_conf_field: return: $stard_config{$field}");
	return $stard_config{General}{$field};
}

## stard_teleport_to
# change the position of the player in a given sector
# INPUT1: Player Name
# INPUT2: coords (space seperated list or floats)
# OUTPUT: success or failure
sub stard_teleport_to {
	my $player = $_[0];
	my $pos = $_[1];

	stard_if_debug(1, "stard_teleport_to($player, $pos)");
	stard_validate_env();
	my $output = join("", stard_cmd("/teleport_to '$player' $pos"));
	if ($output =~/SUCCESS/i) {
		stard_if_debug(1, "stard_teleport_to: return: 1");
		return 1;
	};
	stard_if_debug(1, "stard_teleport_to: return: 0");
	return 0;
}


## stard_loc_distance
# Return the distance between two locations (sectors or pos)
# INPUT1: location 1 (space seperated list)
# INPUT2: location 2 (space seperated list)
# OUTPUT: distance between the points (float)
sub stard_loc_distance {
	my $loc1 = $_[0];
	my $loc2 = $_[1];

	my @coords1 = split(" ", $loc1);
	my @coords2 = split(" ", $loc2);

	my @diff;

	for (my $i = 0; $i < 3; $i++) {
		$diff[$i] = $coords1[$i] - $coords2[$i];
	}
	
	return sqrt(abs(($diff[0])**2 + ($diff[1])**2 + ($diff[2])**2));
}

## stard_location_add
# Add two location strings together (sectors or pos).
# INPUT1: location string (space delimited list)
# INPUT2: location string (space delimited list)
# OUTPUT: added location strings (space delimited list)
sub stard_location_add {
	my $location1 = $_[0];
	my $location2 = $_[1];
	my @l1 = split(" ", $location1);
	my @l2 = split(" ", $location2);
	my @return;
	for (my $i = 0; $i < 3; $i++) {
		$return[$i] = $l1[$i] + $l2[$i];
	}
	return join(" ", @return);
};

## stard_last_output
# Get the last recorded output from starmade. Usefull if you don't know why 
# a command failed
# OUTPUT: (string) output of last run command
sub stard_last_output {
	return $stard_last_output;
}
1;
