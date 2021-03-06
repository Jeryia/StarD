package Stard::Multiplexer;
use strict;
use warnings;
use Cwd;
use Text::ParseWords;
use POSIX;

use lib("./lib");

use Starmade::Message;
use Stard::Base;
use Stard::Log;
use Stard::Plugin;

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

## Core libraries for stard.
# This provides the primary functionality for stard to function.
# NOTE: This library requires the Stard::Base environment setup

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(stard_setup_lib_env plugin_server_event plugin_command ai_messages server_messages chat_messages);


##### DANGER GLOBAL VARIABLE!!! #####
my $GLOBAL_overheat_entity;


## plugin_server_event
# launch plugin actions for given event
# So for example, if a player logs in, this will be called 
# with playerLogin playerName accountName
# INPUT1: server event (ie playerLogin)
# INPUT2: arguments to the given event (ie if playerLogin 
# is the event the playername and account will be provided
sub plugin_server_event {
	my $command = shift(@_);
	my @args = @_;

	stard_lib_validate_env();
	my @plugins = @{get_active_plugin_list()};
	my $stard_plugins = get_stard_plugins_dir();
	my $stard_plugin_log = get_stard_plugins_log();

	my $commands_executed = 0;

	stdout_log("Server Event '$command @args' detected, searching for plugins that use it...", 6);

	Plugin: foreach my $plugin (@plugins) {
		my $command_exec = "$stard_plugins/$plugin/serverEvents/$command";
		if (! -x $command_exec ) {
			next Plugin;
		}
		$commands_executed++;
		stdout_log("Found $plugin server event $command. Spawning...", 6);


		spawn_daemon("$stard_plugins/$plugin", "$stard_plugin_log/$plugin-log/event-$command.log", "serverEvents/$command", @args);
	}
	if (!$commands_executed) {
		stdout_log("No plugins found using server event '$command'", 5);
	}
}

## plugin_command
# launch any plugins using the given commands
# INPUT1: command build run (string)
# INPUT2: player running the command
# INPUT3-*: any arguments for the command
sub plugin_command {
	my $command = shift(@_);
	my $player = shift(@_);
	my @args = @_;

	stard_lib_validate_env();
	my @plugins = @{get_active_plugin_list()};
	my $stard_plugins = get_stard_plugins_dir();
	my $stard_plugin_log = get_stard_plugins_log();

	my $commands_executed = 0;

	stdout_log("Searching for command '$command' giving args '$player @args'", 6);
	Plugin: foreach my $plugin (@plugins) {
		my $command_exec = "$stard_plugins/$plugin/commands/$command";
		if (! -x $command_exec ) {
			next Plugin;
		}
		$commands_executed++;
		stdout_log("Spawning server command '$command $player @args'", 6);

		spawn_daemon("$stard_plugins/$plugin", "$stard_plugin_log/$plugin-log/cmd-$command.log", "commands/$command", $player, @args);
	};

	if (! $commands_executed) {
		starmade_pm($player, "Error command: !$command does not exist!");
		stdout_log("No plugins have command '$command'... reporting not found", 5);
	};
}

## ai_messages 
# Process messages from the starmade server that
# start with [AI] hence being an ai message :)
# INPUT1: ai message raw text
sub ai_messages {
	my $message = $_[0];


	# [AI] Setting callback Server(0) Ship[TC Cruiser MKI_1470000327736](10) Executing send callback: true
	# [AI] Setting callback Server(0) Ship[SS Minow](1475) Executing Active (Boolean) [false, true]->[false]; Current: false send callback: true
	if ($message =~/^\[AI\] Setting callback Server\(\d+\) Ship\[(.*)\]\(\d+\) Executing/) {
		my $entity = $1;
		$GLOBAL_overheat_entity= $entity;
		return;
	};
	return;
}


## server_messages
# Process messages from the starmade server that 
# start with [SERVER] hence being a server message :)
# INPUT1: server message raw text
sub server_messages {
	my $message = $_[0];

	
	stdout_log("recieved starmade message: $message", 8);
	stard_lib_validate_env();
	my @plugins = @{get_active_plugin_list()};

	# [SERVER] MAIN CORE STARTED DESTRUCTION [ENTITY_SHIP_MOB_Marauder EMP Frigate_1513132118990_0] (3, 4, 6) in 900 seconds - started 1513132128310 caused by PlS[Jeryia ; id(431)(2)f(10005)]
	if ($message =~/^\[SERVER\] MAIN CORE STARTED DESTRUCTION \[(.+)\] \(-?\d+, -?\d+, -?\d+\) in \d+ seconds - started \d+ caused by PlS\[(\w+) ;/) {
		my $entity = $1;
		$entity=~s/ENTITY_SHIP_//g;
		$entity=~s/ENTITY_SPACESTATION_//g;
		plugin_server_event("entityOverheat", $entity, $2);
	}

	# [SERVER] MAIN CORE STARTED DESTRUCTION: in 900 seconds - started 1470514620375
	if ($message =~/^\[SERVER\] MAIN CORE STARTED DESTRUCTION: in \d+ seconds - started \d+/) {
		if ($GLOBAL_overheat_entity) {
			plugin_server_event("entityOverheat", $GLOBAL_overheat_entity);
			$GLOBAL_overheat_entity = undef;
		}
		return;
	};
	# [SERVER][SEGMENTCONTROLLER] PERMANENTLY DELETING ENTITY: ENTITY_SPACESTATION_Beta_base_1443297379.ent
	if (
		$message =~/^\[SERVER\]\[SEGMENTCONTROLLER\] PERMANENTLY DELETING ENTITY: ENTITY_(.+)\.ent/
	) {

		my $entity = $1;
		
		plugin_server_event("entityDestroyed", $entity);
		return;
	};
	# [SREVER] FACTION BLOCK REMOVED FROM SpaceStation[ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034(310)]; resetting faction !!!!!!!!!!!!!!
	if (
		$message =~/^\[SERVER\] FACTION BLOCK REMOVED FROM (\S+)\[(.+)\((\d+)\)\]; resetting faction/ ||
		$message =~/^\[SERVER\] FACTION BLOCK REMOVED FROM (\S+)\[(.+)\]\((\d+)\); resetting faction/
	) {
		my $type = $1;
		my $entity = $2;
		my $id = $3;
		plugin_server_event("entityUnFaction", $entity);
		return;
	};
	# [SERVER] PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(139)] has players attached. Doing Sector Change for PlS[Jeryia ; id(3)(1)f(10073)]: Sector[5](3, 8, 7) -> Sector[23](3, 8, 6)
	# [SERVER] Ship[UE Patrol Ship MKIV_1443985052059](299) has CHARACTER. Doing Sector Change for PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(272)]: Sector[330](5, 8, 4) -> Sector[344](5, 8, 5) ID 344
	if (
		$message =~/^\[SERVER\] Ship\[(.*)\]\(\d+\) has .*\. Doing Sector Change for PlayerCharacter\[\(ENTITY_PLAYERCHARACTER_(.*)\)\(\d+\)\]: Sector\[\d+\]\((-?\d+), (-?\d+), (-?\d+)\) -> Sector\[\d+\]\((-?\d+), (-?\d+), (-?\d+)\) ID/ ||
		$message =~/^\[SERVER\] PlayerCharacter\[\((.*)\)\(\d+\)\] has players attached. Doing Sector Change for PlS\[(.*) ; id\(\d+\)\(\d+\)f\(\d+\)\]: Sector\[\d+\]\((-?\d+), (-?\d+), (-?\d+)\) -> Sector\[\d+\]\((-?\d+), (-?\d+), (-?\d+)\)/
	) {

		my $entity = $1;
		my $player = $2;
		my $old_sector = "$3 $4 $5";
		my $new_sector = "$6 $7 $8";
		
		plugin_server_event("sectorChange", $entity, $player, $old_sector, $new_sector);
		return;
	};
	# [SERVER][SPAWN] SPAWNING NEW CHARACTER FOR PlS[Jeryia [Jeryia]*; id(3)(2)f(0)]
	if ($message =~/^\[SERVER\]\[SPAWN\] SPAWNING NEW CHARACTER FOR PlS\[(\S+) \[(\S+)\]\*; .*\]/) {
		my $player = $1;
		my $account = $2;
		plugin_server_event("playerSpawn", $player, $account);
		return;
	};

	# [SERVER][SPAWN] SPAWNING NEW CHARACTER FOR PlS[Jeryia; id(3)(2)f(0)]
	# [SERVER][SPAWN] SPAWNING NEW CHARACTER FOR PlS[Jeryia2 ; id(198)(2)f(0)]
	if (
		$message =~/^\[SERVER\]\[SPAWN\] SPAWNING NEW CHARACTER FOR PlS\[(\S+); .*\]/ ||
		$message =~/^\[SERVER\]\[SPAWN\] SPAWNING NEW CHARACTER FOR PlS\[(\S+) ; id/
	) {
		my $player = $1;
		plugin_server_event("playerSpawn", $player);
		return;
	};
	# [2015-10-03 11:08:20] [SERVER][LOGIN] new client connected. given id: 2: description: Jeryia
	if ($message =~/^\[SERVER\]\[LOGIN\] new client connected. given id: \d+: description: (\S+)/) {
		my $player = $1;
		plugin_server_event("playerLogin", $player);
		return;
	};
	#[SERVER][DISCONNECT] Client 'RegisteredClient: Jeryia (5) connected: true' HAS BEEN DISCONNECTED
	if ($message =~/^\[SERVER\]\[DISCONNECT\] Client 'RegisteredClient: (\S+) \(\d+\) connected: true' HAS BEEN DISCONNECTED.*/) {
		my $player = $1;
		plugin_server_event("playerLogout", $player);
		return;
	};
	# [SERVER] character PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(486)] has been deleted by Sector[487](8, 8, 8)
	if ($message =~/^\[SERVER\] character PlayerCharacter\[\(ENTITY_PLAYERCHARACTER_(.*)\)\(\d+\)\] has been deleted by (.*)$/) {
		my $player = $1;
		my $killer = $2;
		plugin_server_event("playerDeath", $player, $killer);
		return;
	};
	# [SERVER] onLoggedOut starting for RegisteredClient: Jeryia (2) [Jeryia]connected: true
	if ($message =~/^\[SERVER\] onLoggedOut starting for RegisteredClient: (\S+) \(\d+\) \[(\S+)\]connected:/) {
		my $player = $1;
		my $account = $2;
		plugin_server_event("playerLogout", $player, $account);
		return;
	};
	# [SERVER][ChannelRouter] Faction Changed by PlS[Jeryia ; id(3)(2)f(10041)] to 10041
	# [SERVER][ChannelRouter] Faction Changed by PlS[Jeryia2 ; id(2)(1)f(-1)] to -1
	if ($message =~/^\[SERVER\]\[ChannelRouter\] Faction Changed by PlS\[(\S+) ; id\(\d+\)\(\d+\)f\(-?\d+\)\] to (-?\d+)/) {
		my $player = $1;
		my $faction_id = $2;
		if ($faction_id) {
			plugin_server_event("playerFaction", $player, $faction_id);
		};
		return;
	};
	# [SERVER][ChannelRouter] Faction Changed by PlS[Jeryia [Jeryia]*; id(3)(2)f(10041)] to 10041
	if ($message =~/^\[SERVER\]\[ChannelRouter\] Faction Changed by PlS\[(\S+) \[\S+\]\*?; id\(\d+\)\(\d+\)f\(\d+\)\] to (-?\d+)/) {
		my $player = $1;
		my $faction_id = $2;
		if ($faction_id) {
			plugin_server_event("playerFaction", $player, $faction_id);
		};
		return;
	};
	# [SERVER][Faction] Sending removal of member Jeryia from Faction [id=10041, name=Test Faction, description=description goes here, size: 1; FP: 100]
	if ($message =~/^\[SERVER\]\[Faction\] Sending removal of member (\S+) from Faction \[id=(-?\d+).*/) {
		my $player = $1;
		my $faction_id = $2;
		plugin_server_event("playerUnFaction", $player, $faction_id);
		return;
	};
	# [SERVER] received object faction change request 10038 for object SpaceStation[ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034(310)]
	if (
		$message =~/^\[SERVER\] received object faction change request (-?\d+) for object (\S+)\[(.+)\((-?\d+\))\]/ ||
		$message =~/^\[SERVER\] received object faction change request (-?\d+) for object (\S+)\[(.+)\]\((-?\d+\))/
	) {
	 	my $faction_id = $1;
		my $type = $2;
		my $entity = $3;
		my $id = $4;
		if ($faction_id) {
			plugin_server_event("entityFaction", $entity, $faction_id);
		}
		else {
			plugin_server_event("entityUnFaction", $entity);
		}

		return;
	};
}


## chat_messages
# Process messages from player chat. Mostly for detecting player chat commands.
# INPUT1: raw chat message from the starmade daemon
sub chat_messages {
	my $message = $_[0];

	stard_lib_validate_env();
	if ($message =~/\[CHANNELROUTER\] RECEIVED MESSAGE ON Server\(0\): \[CHAT\]\[sender=(\S+)\]\[receiverType.*\[message=(.*)\]/) {
		my $player = $1;
		my $text = $2;
		stdout_log("chat message: $player: $text", 7);

		# ServerCommand
		if ($text =~/^\!/) {
			if ($text =~/^!(\S+)\s+(.*)/ or $text =~/^!(\S+)/) {
				my $cmd = $1;
				my $args = $2;
				
				if (!$args) {
					$args = '';
				};
				if (!($cmd =~/^\./ || $cmd=~/\//)) {
					stdout_log("Spawning server command '$cmd $player $args'", 6);
					plugin_command($cmd, $player, quotewords('\s+', 0, $args));
				};
			};
		};
	};
};

## spawn_daemon
# Spawns the given process as a daemon (unattached to the main process)
# INPUT1: directory to spawn process in as it's working directory
# INPUT2: where to send logs
# INPUT3-*: command with arguments
sub spawn_daemon {
	my $chdir  = shift(@_);
	my $log  = shift(@_);
	my $cmd  = shift(@_);
	my @args = @_;

	my $pid = fork();

	if (!$pid) {
		my $pid2 = fork();
		if (!$pid2) {
			my $old_stdin = *STDIN;
			my $old_stdout = *STDOUT;
			my $old_stderr = *STDERR;
			open(STDOUT, '>>', $log) or die "Failed to open '$log': $!\n";
			open(STDERR, '>>', $log) or die "Failed to open '$log': $!\n";
			open(STDIN, '<', '/dev/null') or die "Failed to open '$log': $!\n";

			chdir($chdir) or die "Failed to change directory to '$chdir': $!\n";
			my $exec = get_exec_prefix($cmd);
			if ($exec) {
				exec($exec, $cmd, @args) or die "Failed to exec '$exec': $!\n";
			}
			else {
				exec($cmd, @args) or die "Failed to exec '$cmd': $!\n";
			};
		}
		exit 0;
	}
	wait;
}


1;
