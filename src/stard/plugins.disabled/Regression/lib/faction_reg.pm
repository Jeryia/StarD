
package faction_reg;
use strict;
use warnings;

use lib("../../lib");
use stard_lib;
use stard_regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(faction_reg);


my $stard_home = "../..";

## general_reg
## faction_reg
# Perform faction oriented functionality regression tests for stard
# INPUT1: name of the player who requested the testing.
sub faction_reg {
	my $player = $_[0];
	my %factions_bid;
	my %factions_bname;
	my %player_info;
	my $faction = "Test Faction";
	if (!stard_broadcast("###Running Factions Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}

	
	# Clear out all factions (so we are sure to have no conflicts
	%factions_bname = %{stard_faction_list_bname()};
	while ($factions_bname{$faction}) {
		if ($factions_bname{$faction}{id} > 0) {
			stard_faction_delete($factions_bname{$faction}{id});
			%factions_bname = %{stard_faction_list_bname()};
		}
	}


	# Check that stard_faction_list_bid() returns information on the pirate faction
	%factions_bid = %{stard_faction_list_bid()};
	test_result("stard_faction_list_bid", defined $factions_bid{'-1'}, "faction_ids:" . join(",", keys %factions_bid));
	test_result("stard_faction_list_bid - name", defined $factions_bid{'-1'}{name});
	test_result("stard_faction_list_bid - desc", defined $factions_bid{'-1'}{desc});
	test_result("stard_faction_list_bid - size", defined $factions_bid{'-1'}{size});
	test_result("stard_faction_list_bid - points", defined $factions_bid{'-1'}{points});


	# Check that stard_faction_list_bname() returns information on the pirate faction
	%factions_bname = %{stard_faction_list_bname()};
	test_result("stard_faction_list_bname", defined $factions_bname{Pirates});
	test_result("stard_faction_list_bname - id", defined $factions_bname{Pirates}{id});
	test_result("stard_faction_list_bname - desc", defined $factions_bname{Pirates}{desc});
	test_result("stard_faction_list_bname - size", defined $factions_bname{Pirates}{size});
	test_result("stard_faction_list_bname - points", defined $factions_bname{Pirates}{points});


	# Check that stard_faction_list_bname and stard_faction_list_bid are giving the same information
	test_result("stard_faction_list_bname - consistancy", $factions_bname{Pirates}{id} == -1);
	test_result("stard_faction_list_bid - consistancy", $factions_bid{-1}{name} eq "Pirates");


	# Check that stard_faction_create creates a faction
	test_result("stard_faction_create", stard_faction_create($faction, ''));
	%factions_bname = %{stard_faction_list_bname()};
	test_result("stard_faction_create - validate", defined $factions_bname{$faction});


	# Check that stard_faction_add_member adds a player to that faction
	my $faction_id = $factions_bname{$faction}{id};
	test_result("stard_faction_add_member", stard_faction_add_member($player, $faction_id));
	%player_info = %{stard_player_info($player)};
	test_result("stard_faction_add_member - validate", $player_info{faction} == $faction_id);


	# Check that stard_faction_list_members mentions the player we just added
	my %members = %{stard_faction_list_members($faction_id)};
	test_result("stard_faction_list_members", defined $members{$player});


	# Check to see if faction_del_member removes the player from the faction
	test_result("stard_faction_del_member", stard_faction_del_member($player, $faction_id));
	%player_info = %{stard_player_info($player)};
	test_result("stard_faction_del_member - validate", ! defined $player_info{faction});


	# Check if stard_faction_delete deletes the faction
	test_result("stard_faction_delete", stard_faction_delete($faction_id));
	%factions_bname = %{stard_faction_list_bname()};
	test_result("stard_faction_delete - validate", !(defined $factions_bname{$faction}));
	stard_broadcast("\n\n");
	print "\n\n";
}

1;
