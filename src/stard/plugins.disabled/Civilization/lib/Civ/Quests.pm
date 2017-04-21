#!perl
package Civ::Quests;
use strict;
use warnings;
use File::Basename;

use lib("../../lib/perl");
use Starmade::Base;
use Starmade::Message;
use Starmade::Misc;
use Starmade::Player;
use Starmade::Sector;
use Stard::Base;

use lib("./lib");
use Civ::Base;
use Civ::Object;

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
@EXPORT=qw(quest_active_list quest_active quest_add quest_set_start_sector quest_get_start_sector quest_remove quest_success quest_completed_before quest_failed quest_list_objects quest_remove_all_objects quest_create_object quest_remove_object quest_clear_object quest_move_object quest_get_object_id quest_info quest_entity_name quest_start_actions get_avail_quest_list populate_quest_info_cache set_quest_avail_cur get_quest_avail_cur clear_quest_avail_cur quest_processed_quest_info);


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

	my $quests_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category";
	opendir(my $dh, $quests_dir) or return \@quests;
	while (my $file = readdir($dh)) {
		if ( $file ne '.' && $file ne '..') {
			push(@quests, $file);
		}
	}
	close($dh);
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

	my $quest_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest";

	if ( -d $quest_dir ) {
		return 1;
	}
	return 0
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

	my $quest_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest";
	if (!quest_info($category, $quest)) {
		starmade_pm($player, "An error occurred when trying to accept the quest '$quest' of category.\n Please inform an admin what you where doing when you recieved this message");
		print "Error: quest: '$quest' does not exist in category '$category'\n";
		return;
	}
	system('mkdir', '-p', $quest_dir);
	my %player_info = %{starmade_player_info($player)};
	quest_set_start_sector($player, $category, $quest, $player_info{sector});

	quest_start_actions($player, $category, $quest);
}


## quest_set_start_sector
# Sets the starting sector of the given quest. (Where the player got the quest)
# INPUT1: player name
# INPUT2: quest category
# INPUT3: quest name
# INPUT4: sector (space seperated list, ie '3 14 -5')
sub quest_set_start_sector {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $sector = shift(@_);

	my $file = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/start_sector";
	open(my $fh, ">", "$file") or warn "failed to open '$file': $!\n";
	flock($fh, 2) or die "Failed to lock '$file'!\n";
	print $fh "$sector";
	close($fh);
}

## quest_get_start_sector
# Gets the starting sector of the given quest. (Where the player got the quest)
# INPUT1: player name
# INPUT2: quest category
# INPUT3: quest name
# INPUT4: sector (space seperated list, ie '3 14 -5')
sub quest_get_start_sector {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my $sector;
	my $fh;

	my $file = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/start_sector";
	if (!open($fh, "<", "$file")) {
		warn "failed to open '$file': $!\n";
		return;
	}
	flock($fh, 1) or die "Failed to lock '$file':$!\n";
	($sector) = <$fh>;
	close($fh);
	return $sector;
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
	

	my $quest_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest";
	my $quest_objects_dir = "$quest_dir/objects";

	quest_remove_all_objects($player, $category, $quest);
	rmdir($quest_objects_dir);

	unlink("$quest_dir/start_sector");
	rmdir("$quest_dir");
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

	my %quest_config = %{quest_processed_quest_info($player, $category, $quest)};

	my $message = '';

	if ($quest_config{next_objective}) {
		$message = "Objective Complete!\n";
	}
	else {
		$message = "Quest '$quest' has been completed successfully!\n";
		$message   .= "Your Rewards:\n";
	}
	if ($quest_config{reward_credits}) {
		starmade_give_credits($player, $quest_config{reward_credits});
		$message .= "  $quest_config{reward_credits} Credits\n";
	}
	if ($quest_config{reward_reputation}) {
		my @rep_rewards = @{expand_array($quest_config{reward_reputation})};
		foreach my $rep_reward (@rep_rewards) {
			if ($rep_reward=~/(.*):(-?\d+)/) {
				my $rep = $1;
				my $amount = $2;
				reputation_add($player, $rep, $amount);
				$message .= "  $amount $rep reputation\n";
			}
			else {
				print "Invalid reward_reputation: $rep_reward\n";
			}
		}
	}

	starmade_pm($player, $message);
	quest_remove($player, $category, $quest);

	if ($quest_config{next_objective}) {
		quest_add($player, $category, $quest_config{next_objective});
		my %quest_info = %{quest_processed_quest_info($player, $category, $quest_config{next_objective})};
		starmade_pm($player, "New objective: $quest_info{objective_text}");
	}

	open(my $fh, ">>", "$Civ::Base::PLAYER_DATA/$player/quest_c_$category");
	flock($fh, 2);
	print $fh "$quest\n";
	close($fh);
}

sub quest_completed_before {
	my $player = shift(@_);
	my $quest = shift(@_);
	my $category = shift(@_);

	my @quests;

	open(my $fh, "<", "$Civ::Base::PLAYER_DATA/$player/quest_c_$category") or return 0;
	flock($fh, 1);
	@quests = <$fh>;
	close($fh);
	
	foreach my $c_quest (@quests) {
		chomp $c_quest;
		if ($c_quest eq $quest) {
			return 1;
		}
	}
	return 0;
}

## quest_failed
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

sub quest_list_objects {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);


	my $quest_objects_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/objects";

	my @objects = ();
	opendir(my $dh, "$quest_objects_dir") or return \@objects;

	while (readdir $dh) {
		if ($_ ne '.' && $_ ne '..') {
			push(@objects, $_);
		}
	}
	return \@objects;
}

sub quest_remove_all_objects {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);

	my @objects = @{quest_list_objects($player, $category, $quest)};	

	foreach my $object (@objects) {
		quest_remove_object($player, $category, $quest, $object);
	}
}


sub quest_create_object {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $object_tag = shift(@_);
	my $object_type = shift(@_);
	my $sector = shift(@_);
	my $pos = shift(@_);

	my $quest_objects_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/objects";
	my $object = create_ship_object($player, $object_type, $sector, $pos);

	system("mkdir", "-p", "$quest_objects_dir");
	if ( $object ) {
		link("$Civ::Base::PLAYER_DATA/$player/objects/$object", "$quest_objects_dir/$object_tag") or return 0;
		return 1;
	}
	return 0;
}


## quest_remove_object
# remove the quest object.
# INPUT1: player name
# INPUT2: quest category
# INPUT3: quest name
# INPUT4: object tag (this identifies the object for the quest).
sub quest_remove_object {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $object_tag = shift(@_);

	my $quest_objects_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/objects";
	my $object_id = quest_get_object_id($player, $category, $quest, $object_tag);

	if ( $object_id && remove_ship_object($player, $object_id)) {
		unlink("$quest_objects_dir/$object_tag");
		return 1;
	}
	return 0;
}

## quest_clear_object
# remove the quest object without removing it from starmade
# INPUT1: player name
# INPUT2: quest category
# INPUT3: quest name
# INPUT4: object tag (this identifies the object for the quest).
sub quest_clear_object {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $object_tag = shift(@_);

	my $quest_objects_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/objects";
	my $object_id = quest_get_object_id($player, $category, $quest, $object_tag);

	if ( $object_id && clear_ship_object($player, $object_id)) {
		unlink("$quest_objects_dir/$object_tag");
		return 1;
	}
	return 0;
}

## quest_move_object
# remove the quest object.
## quest_move_object
# remove the quest object.
# INPUT1: player name
# INPUT2: quest category
# INPUT3: quest name
# INPUT4: object tag
# INPUT5: sector to move object to.
sub quest_move_object {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $object_tag = shift(@_);
	my $sector = shift(@_);
	
	my $object_id = quest_get_object_id($player, $category, $quest, $object_tag);
	my $object_name = get_object_name($player, $object_id);
	my %quest_info = %{quest_info($category, $quest)};

	if (!($quest_info{$object_tag})) {
		return 0;
	}

	my %ships = %{starmade_search($object_name)};
	if (
		$ships{$object_name} ||
		starmade_loc_distance($ships{$object_name}, $sector) >= 2
	) {
		quest_remove_object($player, $object_id);
		sleep 4;
		quest_create_object(
			$player, 
			$category, 
			$quest, 
			$sector, 
			$object_tag,
			$quest_info{$object_tag},
			$sector,
		);
	}
	return 1;
}

## quest_get_object_id
# INPUT1: player
# INPUT2: category
# INPUT3: quest
# INPUT4: object tag
sub quest_get_object_id {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	my $object_tag = shift(@_);


	my $quest_objects_dir = "$Civ::Base::PLAYER_DATA/$player/active_quests_$category/$quest/objects";
	my $object_id;
	if ( -l "$quest_objects_dir/$object_tag" ) {
		$object_id = basename(readlink("$quest_objects_dir/$object_tag"));
	}
	else {
		unlink("$quest_objects_dir/$object_tag");
		return 0;
	}

	return $object_id;
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

	my %quest_info = %{quest_processed_quest_info($player, $category, $quest)};

	my %player_info = %{starmade_player_info($player)};

	for (my $i = 1; $quest_info{"intro_message$i"}; $i++) {
		if ($quest_info{"intro_delay$i"}) {
			sleep $quest_info{"intro_delay$i"};
		}
		starmade_pm($player, $quest_info{"intro_message$i"});
	}
	
	if (!$quest_info{sector} || $quest_info{sector} eq $player_info{sector} ) {
		for (my $i = 1; defined $quest_info{"sector_spawn$i"}; $i++) {
			quest_create_object($player, $category, $quest, "sector_spawn$i", $quest_info{"sector_spawn$i"}, $quest_info{sector});
		}
		if ($quest_info{victory_on_arrival}) {
			quest_success($player, $category, $quest);
		}
	}
	for (my $i = 1; $quest_info{"escort$i"}; $i++) {
		quest_create_object($player, $category, $quest, "escort$i", $quest_info{"escort$i"}, $player_info{sector});
	}

	# Must be last, as thie waits for the countdown to finish before continuing.
	if ($quest_info{failure_countdown}) {
		sleep $quest_info{failure_countdown};
		if (quest_active($player, $category, $quest)) {
			quest_failed($player, $category, $quest);
		}
	}
	if ($quest_info{victory_countdown}) {
		sleep $quest_info{failure_countdown};
		if (quest_active($player, $category, $quest)) {
			quest_success($player, $category, $quest);
		}
	}
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
		Quest: foreach my $quest (@{$potential_quests{$category}}) {
			my %quest_info = %{quest_processed_quest_info($player, $category, $quest)};

			if ($quest_info{not_repeatable} && quest_completed_before($player, $quest, $category)) {
				next Quest;
			}
			if (!reqs_ok($player, \%quest_info)) {
				next Quest;
			}
			push(@quests, $quest);
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
		$avail_quests{$category} = expand_array($input{$category});;
	}

	return \%avail_quests;
}

sub clear_quest_avail_cur {
	my $player = shift(@_);

	unlink("$Civ::Base::PLAYER_DATA/$player/quest_avail_cur");
}

sub quest_processed_quest_info {
	my $player = shift(@_);
	my $category = shift(@_);
	my $quest = shift(@_);
	
	my $distance = 0;
	my $start_sector;
	my %quest_info = %{quest_info($category, $quest)};

	if ( $quest_info{sector} && $quest_info{sector} =~/-?\d+\s+-?\d+\s+-?\d+/) {
		$start_sector = quest_get_start_sector($player, $category, $quest);
		if ( !$start_sector) {
			my %player_info = %{starmade_player_info($player)};
			$start_sector = $player_info{sector};
		}
		$distance = starmade_loc_distance($start_sector, $quest_info{sector});
	}

	foreach my $key (keys %quest_info) {
		$quest_info{$key}=~s/\$distance/$distance/g;
		
		while ($quest_info{$key}=~/\$(\w+)\W/) {
			my $ref = $1;
			if ($quest_info{$ref}) {
				$quest_info{$key}=~s/\$$ref/$quest_info{$ref}/g;
			}
			else {
				$quest_info{$key}=~s/\$$ref/\%<INVALID>$ref\%/g;
				print "Error! Invalid reference '\$$ref' in quest category: '$category', quest: '$quest'\n";
			}
		}

		if ($quest_info{$key} =~/(-?\d+\.?\d*) \* (-?\d+\.?\d*)/) {
			my $num1 = $1;
			my $num2 = $2;
			my $answer = int($num1 * $num2);
			
			$quest_info{$key} =~s/$num1 \* $num2/$answer/g;
		}
		if ($quest_info{$key} =~/(-?\d+\.?\d*) \/ (-?\d+\.?\d*)/) {
			my $num1 = $1;
			my $num2 = $2;
			my $answer = int($num1 / $num2);
			
			$quest_info{$key} =~s/$num1 \/ $num2/$answer/g;
		}
		if ($quest_info{$key} =~/(-?\d+\.?\d*) \+ (-?\d+\.?\d*)/) {
			my $num1 = $1;
			my $num2 = $2;
			my $answer = int($num1 + $num2);
			
			$quest_info{$key} =~s/$num1 \+ $num2/$answer/g;
		}
		if ($quest_info{$key} =~/(-?\d+\.?\d*) \- (-?\d+\.?\d*)/) {
			my $num1 = $1;
			my $num2 = $2;
			my $answer = int($num1 - $num2);
			
			$quest_info{$key} =~s/$num1 \- $num2/$answer/g;
		}
	}
	return \%quest_info;
}

1;
