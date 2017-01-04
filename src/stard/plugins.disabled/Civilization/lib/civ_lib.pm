#!perl
use strict;
use warnings;

use lib("../../lib/perl");
use Starmade::Base;
use Starmade::Message;
use Starmade::Misc;
use Starmade::Player;
use Starmade::Sector;
use Stard::Base;

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

our $CONFIG_DIR = "./config";
our $CONFIG_FILE = "$CONFIG_DIR/civ.conf";
our $MAP_FILE = "$CONFIG_DIR/civ.map";
our $FACTION_CONFIG = "$CONFIG_DIR/factions.conf";

## locations of the different configuration files for each category.
our %CATEGORY_CONF_FILE;
$CATEGORY_CONF_FILE{ship} = "$CONFIG_DIR/buy_ships.conf";
$CATEGORY_CONF_FILE{blocks} = "$CONFIG_DIR/buy_blocks.conf";
$CATEGORY_CONF_FILE{dock} = "$CONFIG_DIR/buy_docks.conf";

our %CATEGORY_CONF;
$CATEGORY_CONF{ship} = "buy_ships";
$CATEGORY_CONF{blocks} = "buy_blocks";
$CATEGORY_CONF{dock} = "buy_docks";


my %QUEST_CATEGORY_CONF_FILE;
$QUEST_CATEGORY_CONF_FILE{courier} = "$CONFIG_DIR/quests_courier.conf";
$QUEST_CATEGORY_CONF_FILE{pirate} = "$CONFIG_DIR/quests_pirate.conf";
$QUEST_CATEGORY_CONF_FILE{combat} = "$CONFIG_DIR/quests_combat.conf";
$QUEST_CATEGORY_CONF_FILE{campaign} = "$CONFIG_DIR/quests_campaign.conf";
$QUEST_CATEGORY_CONF_FILE{engineer} = "$CONFIG_DIR/quests_engineer.conf";

my $DATA = "./data";
my $PLAYER_DATA = "$DATA/players";
my $FACTION_MAP_FILE = "$DATA/faction_map";

my %blank_hash = ();

## trade_with_station
# Get the available sector cofiguration, if it is availble and the player is 
# close enough to the sector's station. The player will be informed if they 
# cannot. Returns the map configuration for the given station, if ok.
# INPUT1: player name who's attempting the trade
# INPUT2: (optional) provide player info hash (from starmade_player_info())
# OUTPUT: outputs the configuration for the given sector from the map.
sub get_station_options {
	my $player = shift(@_);
	my %player_info;

	if (@_) {
		 %player_info = %{shift(@_)};
	}
	else {
		%player_info = %{starmade_player_info($player)};
	}

	my %map = %{stard_read_config($MAP_FILE)};
	my %config;
	my $station_name;
	my %sector_info;
	my $station_pos;

	Object: foreach my $object (keys %map) {
		if ($map{$object}{sector} eq $player_info{sector}) {
			%config = %{$map{$object}};
			$station_name = $object;
			last Object;
		}
	}

	if (!%config) {
		starmade_pm($player, "There is nothing availble in this sector.");
		return \%blank_hash;
	}
	%sector_info = %{starmade_sector_info($player_info{sector})};
	if ($sector_info{entity}{"ENTITY_SPACESTATION_$station_name"}{pos}) {
		$station_pos = $sector_info{entity}{"ENTITY_SPACESTATION_$station_name"}{pos}
	}
	else {
		starmade_pm($player, "The station appears to be missing!");
		return \%blank_hash;
	}
	if (starmade_loc_distance($station_pos, $player_info{pos}) > 500) {
		starmade_pm($player, "You are not close enough to the station to trade with it.");
		return \%blank_hash;
	}
	return \%config;
}

## quest_active_list
# Get the list of quests the player is currently on.
# INPUT1: player
# INPUT2: category of quest.
sub quest_active_list {
	my $player = shift(@_);
	my $category = shift(@_);

	my @quests = ();

	open(my $fh, "<", "$PLAYER_DATA/$player/quest_$category") or return \@quests;
	@quests = <$fh>;
	close($fh);

	foreach my $quest (@quests) {
		$quest=~s/^\s//g;
		$quest=~s/\s$//g;
	}
	return \@quests;
}

## quest_active
# Check if a given quest is in progress by the given player.
# INPUT1: player
# INPUT2: category of quest.
# INPUT3: quest name
# OUTPUT: 1 if active, 0 if not.
sub quest_active {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my @quests = @{quest_active_list($player, $category)};

	foreach my $active_quest (@quests) {
		if ($quest eq $active_quest) {
			return 1;
		}
	}
	return 0;
}

## quest_add
# Add the quest to the player's list of active quests.
# INPUT1: player
# INPUT2: category of quest.
# INPUT3: quest name
sub quest_add {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	system('mkdir', '-p', "$PLAYER_DATA/$player/");

	if (!quest_info($category, $quest)) {
		starmade_pm($player, "An error occurred when trying to accept the quest '$quest' of category.\n Please inform an admin what you where doing when you recieved this message");
		print "Error: quest: '$quest' does not exist in category '$category'\n";
		return;
	}

	my $datafile = "$PLAYER_DATA/$player/quest_$category";
	open(my $lock_fh, "<", $datafile);
	flock($lock_fh, 2);

	my @quests = @{quest_active_list($player, $category)};
	foreach my $active_quest (@quests) {
		if ($active_quest eq $quest) {
			close($lock_fh);
			return;
		}
	}
	push(@quests, $quest);

	open(my $fh, ">", "$PLAYER_DATA/$player/quest_$category") or warn "failed to open '$PLAYER_DATA/$player/quest_$category': $!\n";
	print $fh join("\n", @quests);
	close($fh);
	close($lock_fh);
	quest_start_actions($player, $category, $quest);
}

## quest_remove
# Remove the quest from the player's active list
# INPUT1: player
# INPUT2: category of quest.
# INPUT3: quest name
sub quest_remove {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	
	my $datafile = "$PLAYER_DATA/$player/quest_$category";

	open(my $lock_fh, "<", $datafile);
	flock($lock_fh, 2);

	my @quests = @{quest_active_list($player, $category)};
	for (my $i = 0; $i <= $#quests; $i++) {
		my $active_quest = $quests[$i];
		if ($active_quest eq $quest) {
			splice(@quests, $i);
		}
	}

	open(my $fh, ">", $datafile) or warn "failed to open '$datafile': $!\n";
	if (@quests) {
		print $fh join("\n", @quests);
	}
	close($fh);
	close($lock_fh);
}

## quest_success
# Reward the player for the completed quest
# INPUT1: player
# INPUT2: category
# INPUT3: quest name
sub quest_success {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my %quest_config = %{quest_info($category, $quest)};

	my $message = '';

	if ($quest_config{next_objective}) {
		$message = "Objective Complete!\n";
	}
	else {
		$message = "Quest '$quest' has been completed successfully!\n";
	}
	if ($quest_config{reward_credits}) {
		$message   .= "Your Rewards:\n";
		starmade_give_credits($player, $quest_config{reward_credits});
		$message .= "  $quest_config{reward_credits} Credits\n";
	}
	starmade_pm($player, $message);
	quest_remove($player, $category, $quest);

	if ($quest_config{next_objective}) {
		quest_add($player, $category, $quest_config{next_objective});
		my %quest_info = %{quest_info($category, $quest_config{next_objective})};
		starmade_pm($player, "New objective: $quest_info{objective_text}");
	}
	open(my $fh, ">>", "$PLAYER_DATA/$player/quest_c_$category");
	flock($fh, 2);
	print $fh "$quest\n";
	close($fh);
}

## quest_failure
# Reward the player for the completed quest
# INPUT1: player
# INPUT2: category
# INPUT3: quest name
sub quest_failed {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my %quest_config = %{quest_info($category, $quest)};

	my $message  = "You have failed the quest '$quest'!\n";
	if ($quest_config{consolation_credits}) {
		$message .= "Consolation Prize:\n";
		starmade_give_credits($player, $quest_config{consolation_credits});
		$message .= "  $quest_config{consolation_credits} Credits\n";
	}
	starmade_pm($player, $message);
	quest_remove($player, $category, $quest);
}

## quest_info
# get the information on a specific quest.
# INPUT1: category of quest.
# INPUT2: quest name
# OUTPUT: hash of quest information
sub quest_info {
	my $category = shift(@_);
	my $quest = shift(@_);

	my %quests = %{stard_read_config($QUEST_CATEGORY_CONF_FILE{$category})};
	print "quests: \n";


	if ($quests{$quest}) {
		return $quests{$quest};
	}
	return \%blank_hash;
}

sub quest_entity_name {
	my $player = shift(@_);
	my $name = shift(@_);

	$name=~s/%player%/$player/g;
	return $name;
}

sub quest_start_actions {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my %quest_info = %{quest_info($category, $quest)};

	my %player_info = %{player_info($player)};

	for (my $i = 1; $quest_info{"intro_message$i"}; $i++) {
		if ($quest_info{"intro_delay$i"}) {
			sleep $quest_info{"intro_delay$i"};
		}
		starmade_pm($player, $quest_info{"intro_message$i"});
	}
	
	if (!$quest_info{sector} || $quest_info{sector} eq $player_info{sector} ) {
		if (
			$quest_info{template} eq 'destroy' &&
			$quest_info{objective} && 
			$quest_info{objective_bp} && 
			$quest_info{objective_fac}
		) {
			starmade_spawn_entity_pos($quest_info{objective_bp}, $quest_info{objective}, $player_info{sector}, starmade_random_pos(), $quest_info{objective_fac}, 1);
		}
		if ($quest_info{enemies} && $quest_info{enemies_fac} && $quest_info{enemies_pos} ) {
			my @enemies = split(',', $quest_info{enemies});
			my @enemies_pos = split(',', $quest_info{enemies_pos});
			starmade_spawn_mobs_bulk(\@enemies, \@enemies_pos, $quest_info{enemies_fac}, $player_info{sector}, 1);
		}
	}
	if ($quest_info{escort} && $quest_info{escort_fac} && $quest_info{escort_bp}) {
		starmade_spawn_entity_pos($quest_info{escort_bp}, $quest_info{escort}, $player_info{sector}, starmade_random_pos(), $quest_info{escort_fac}, 1);
	}

	# Must be last, as thie waits for the countdown to finish before continuing.
	if ($quest_info{failure_countdown} && $quest_info{failure_countdown_name}) {
		starmade_countdown($quest_info{failure_countdown}, $quest_info{failure_countdown_name});
		sleep $quest_info{failure_countdown};
		if (quest_active($player, $category, $quest)) {
			quest_failure($player, $category, $quest);
		}
	}
	if ($quest_info{success_countdown} && $quest_info{success_countdown_name}) {
		starmade_countdown($quest_info{failure_countdown}, $quest_info{failure_countdown_name});
		sleep $quest_info{failure_countdown};
		if (quest_active($player, $category, $quest)) {
			quest_success($player, $category, $quest);
		}
	}
}

1;
