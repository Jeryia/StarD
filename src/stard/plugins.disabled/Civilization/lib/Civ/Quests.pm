#!perl
package Civ::Quests;
use strict;
use warnings;

use lib("../../lib/perl");
use Starmade::Base;
use Starmade::Message;
use Starmade::Misc;
use Starmade::Player;
use Starmade::Sector;
use Stard::Base;

use lib("./lib");
use Civ::Base;

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

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT=qw(quest_active_list quest_active quest_add quest_remove quest_success quest_failed quest_info quest_entity_name quest_start_actions quest_spawn_escort quest_move_escort quest_despawn_escort get_avail_quest_list populate_quest_info_cache set_quest_avail_cur get_quest_avail_cur clear_quest_avail_cur);


## locations of the different configuration files for each category.
#
our %CATEGORY_CONF;
$CATEGORY_CONF{campaign} = "quests_campaign";
$CATEGORY_CONF{combat} = "quests_combat";
$CATEGORY_CONF{courier} = "quests_courier";
$CATEGORY_CONF{engineer} = "quests_engineer";
$CATEGORY_CONF{pirate} = "quests_pirate";

our %CATEGORY_CONF_FILE;
$CATEGORY_CONF_FILE{campaign} = "$Civ::Base::CONFIG_DIR/quests_campaign.conf";
$CATEGORY_CONF_FILE{combat} = "$Civ::Base::CONFIG_DIR/quests_combat.conf";
$CATEGORY_CONF_FILE{courier} = "$Civ::Base::CONFIG_DIR/quests_courier.conf";
$CATEGORY_CONF_FILE{engineer} = "$Civ::Base::CONFIG_DIR/quests_engineer.conf";
$CATEGORY_CONF_FILE{pirate} = "$Civ::Base::CONFIG_DIR/quests_pirate.conf";

my %blank_hash = ();


### Cache variables
my %QUEST_INFO_CACHE;

## quest_active_list
# Get the list of quests the player is currently on.
# INPUT1: player
# INPUT2: category of quest.
sub quest_active_list {
	my $player = shift(@_);
	my $category = shift(@_);

	my @quests = ();

	open(my $fh, "<", "$Civ::Base::PLAYER_DATA/$player/quest_$category") or return \@quests;
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

	system('mkdir', '-p', "$Civ::Base::PLAYER_DATA/$player/");

	if (!quest_info($category, $quest)) {
		starmade_pm($player, "An error occurred when trying to accept the quest '$quest' of category.\n Please inform an admin what you where doing when you recieved this message");
		print "Error: quest: '$quest' does not exist in category '$category'\n";
		return;
	}

	my $datafile = "$Civ::Base::PLAYER_DATA/$player/quest_$category";
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

	open(my $fh, ">", "$Civ::Base::PLAYER_DATA/$player/quest_$category") or warn "failed to open '$Civ::Base::PLAYER_DATA/$player/quest_$category': $!\n";
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
	
	my $datafile = "$Civ::Base::PLAYER_DATA/$player/quest_$category";


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

	open(my $fh, ">>", "$Civ::Base::PLAYER_DATA/$player/quest_c_$category");
	flock($fh, 2);
	print $fh "$quest\n";
	close($fh);
	if ($quest_config{escort}) {
		sleep 10;
		quest_despawn_escort($player, $quest_config{escort});
	}

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
	if ($quest_config{escort}) {
		quest_despawn_escort($player, $quest_config{escort});
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

	populate_quest_info_cache($category);

	if ($QUEST_INFO_CACHE{$category} && $QUEST_INFO_CACHE{$category}{$quest}) {
		return $QUEST_INFO_CACHE{$category}{$quest};
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

	my %player_info = %{starmade_player_info($player)};

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
			starmade_spawn_entity_pos($quest_info{objective_bp}, $quest_info{objective}, $player_info{sector}, starmade_random_pos(), map_faction($quest_info{objective_fac}), 1);
		}
		if ($quest_info{enemies} && map_faction($quest_info{enemies_fac}) && $quest_info{enemies_pos} ) {
			my @enemies = split(',', $quest_info{enemies});
			my @enemies_pos = split(',', $quest_info{enemies_pos});
			starmade_spawn_mobs_bulk(\@enemies, \@enemies_pos, $quest_info{enemies_fac}, $player_info{sector}, 1);
		}
	}
	if ($quest_info{escort} && $quest_info{escort_fac} && $quest_info{escort_bp}) {
		quest_spawn_escort($player, $player_info{sector}, $quest_info{escort}, $quest_info{escort_fac}, $quest_info{escort_bp});
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

sub quest_spawn_escort {
	my $player = shift(@_);
	my $sector = shift(@_);
	my $escort = shift(@_);
	my $esc_faction = shift(@_);
	my $blueprint = shift(@_);


	quest_despawn_escort($player, $escort);
	select(undef, undef, undef, 0.2);

	starmade_spawn_entity_pos($blueprint, "$escort\_$player", $sector, starmade_random_pos(), map_faction($esc_faction), 1);

}

sub quest_move_escort {
	my $player = shift(@_);
	my $sector = shift(@_);
	my $escort = shift(@_);
	my $esc_faction = shift(@_);
	my $blueprint = shift(@_);

	my %ships = %{starmade_search("$escort\_$player")};
	if (
		!$ships{"$escort\_$player"} ||
		starmade_loc_distance($ships{"$escort\_$player"}, $sector) >= 2
	) {
		sleep 4;
		quest_spawn_escort($player, $sector, $escort, $esc_faction, $blueprint);
		return;
	}
}

sub quest_despawn_escort {
	my $player = shift(@_);
	my $escort = shift(@_);

	starmade_despawn_all("$escort\_$player", "all", "true");
}


sub get_avail_quest_list {
	my $player = shift(@_);

	my %station_options = %{get_station_options($player)};
	my %potential_quests = ();
	my %avail_quests = %{get_quest_avail_cur($player)};

	if (%avail_quests) {
		return \%avail_quests;
	}
	
	# Gather quests we may use at this location
	foreach my $category (keys %CATEGORY_CONF) {
		if ($station_options{$CATEGORY_CONF{$category}}) {
			$potential_quests{$category} = expand_array($station_options{$CATEGORY_CONF{$category}});
		}
	}

	# Check each quest to see if it if offered at this time.
	foreach my $category (keys %CATEGORY_CONF) {
		my @quests = ();
		foreach my $quest (@{$potential_quests{$category}}) {
			my %quest_info = %{quest_info($quest, $category)};
			if (reqs_ok($player, \%quest_info)) {
				push(@quests, $quest);
			}
		}
		if (@quests) {
			$avail_quests{$category} = \@quests;
		}
	}

	set_quest_avail_cur($player, \%avail_quests);
	return \%avail_quests;
}

sub populate_quest_info_cache {
	my $category = shift(@_);

	if ($CATEGORY_CONF{$category} && !$QUEST_INFO_CACHE{$category}) {
		$QUEST_INFO_CACHE{$category} = stard_read_config($CATEGORY_CONF_FILE{$category});
	}
}

sub set_quest_avail_cur {
	my $player = shift(@_);
	my %avail_quests = %{shift(@_)};


	my %output = ();
	foreach my $category (keys %avail_quests) {
		$output{$category} = join(",", @{$avail_quests{$category}});
	}

	system('mkdir', '-p', "$Civ::Base::PLAYER_DATA/$player");
	write_basic_config("$Civ::Base::PLAYER_DATA/$player/quest_avail_cur", \%output);
}

sub get_quest_avail_cur {
	my $player = shift(@_);
	my %avail_quests = ();

	my %input = %{read_basic_config("$Civ::Base::PLAYER_DATA/$player/quest_avail_cur")};

	foreach my $category (keys %input) {
		my @quests = split("\n", @{$avail_quests{$category}});
		$avail_quests{$category} = \@quests;
	}

	return \%avail_quests;
}

sub clear_quest_avail_cur {
	my $player = shift(@_);

	unlink("$Civ::Base::PLAYER_DATA/$player/quest_avail_cur");
}

1;
