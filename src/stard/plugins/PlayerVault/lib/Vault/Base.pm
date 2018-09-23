package Vault::Base;
use strict;
use warnings;

use Storable;

use lib("../../lib/perl");
use Starmade::Player;
use Starmade::Sector;
use Starmade::Message;
use Starmade::Misc;
use Stard::Base;

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_vault_area populate_vault_hash populate_prev_loc_hash create_vault_area vault_teleport);

my $vault_file = "./vault.dat";
my $prev_loc_file = "./prev_loc.dat";
my $start_vault = "-100 -1600 -100";
my $vault_spacing = 2;
my $config_file = "./playervault.cfg";

my %vault = ();
my %prev_locs = ();
my %config = ();


sub get_vault_area {
	my $player = shift(@_);
	populate_vault_hash();

	return $vault{$player};
}

sub populate_config_hash {
	if (!%config && -r $config_file) {
		%config = %{stard_read_config($config_file)};

		if (!$config{vault_sector_start}) {
			$config{vault_sector_start} = "-600 -1600 -600";
		}
		if (!$config{vault_access_sector}) {
			$config{vault_access_sector} = "2 2 2";
		}
		if (!$config{vault_spacing}) {
			$config{vault_spacing} = "2";
		}
	}
}

sub populate_vault_hash {
	if (!%vault && -r $vault_file) {
		%vault = %{retrieve($vault_file)};
	}
}

sub populate_prev_loc_hash {
	if (!%prev_locs && -r $prev_loc_file) {
		%prev_locs = %{retrieve($prev_loc_file)};
	}
}

sub create_vault_area {
	my $player = shift(@_);

	populate_vault_hash();
	populate_config_hash();

	if (!$vault{$player}) {
		my $num_vaults = (keys %vault);
		my $vault_distance = $config{vault_spacing} * $num_vaults;
		my $vault_location = starmade_location_add($config{vault_sector_start}, "0 0 $vault_distance");
		$vault{$player} = $vault_location;

		starmade_sector_chmod($vault_location, 'add', 'protected');
		starmade_sector_chmod($vault_location, 'add', 'noexit');
		starmade_sector_chmod($vault_location, 'add', 'noenter');
		starmade_sector_chmod($vault_location, 'add', 'peace');

		store(\%vault, $vault_file);
	}
}

sub in_vault_access_sector {
	my $sector = shift(@_);

	populate_config_hash();

	my @access_sectors = @{expand_array($config{vault_access_sector})};
	foreach my $access_sector (@access_sectors) {
		if ($sector eq $access_sector) {
			return 1;
		}
	}
	return 0;
}

sub vault_teleport {
	my $player = shift(@_);

	my %player_info = %{starmade_player_info($player)};

	if (!$vault{$player}) {
		create_vault_area($player);
	}
	populate_prev_loc_hash();
	populate_config_hash();

	if ($player_info{sector} eq $vault{$player}) {
		if (!$prev_locs{$player}) {
			starmade_change_sector_for($player, '2 2 2');
			return;
		}
		starmade_change_sector_for($player, $prev_locs{$player});
		starmade_pm($player, "You have been teleported back to where you where! Type !vault to return to your vault.");
		return;
	}
	elsif (in_vault_access_sector($player_info{sector})) {
		$prev_locs{$player} = $player_info{sector};
		store(\%prev_locs, $prev_loc_file);
		
		starmade_change_sector_for($player, $vault{$player});
		starmade_pm($player, "You have been teleported to your vault! To go back type !vault");
		
	}
	else {
		my $access_sectors = join("\n", @{expand_array($config{vault_access_sector})});
		starmade_pm($player, "You need to be in a vault access sector to access your vault! Vault Access Sectors: \n$access_sectors");
	}
}


1;
