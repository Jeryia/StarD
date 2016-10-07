package Starmade::Sector;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_sector_chmod starmade_sector_info starmade_get_spawn_sector);



## starmade_sector_chmod
# Change the properties of a sector
# INPUT1: sector to put the player (space delimited list)
# INPUT2: add/remove
# INPUT3: setting (peace, protected, noenter, noexit, noindications, nofploss)
# OUTPUT: 1 if success, 0 if failure
sub starmade_sector_chmod {
	my $sector = $_[0];
	my $modifier = $_[1];
	my $setting = $_[2];
	
	starmade_if_debug(1, "starmade_sector_chmod($sector, $modifier, $setting)");
	starmade_validate_env();
	my $output;
	$modifier =~s/add/+/g;
	$modifier =~s/remove/-/g;

	$output = join("", starmade_cmd("/sector_chmod", split(" ", $sector), $modifier, $setting));
	if ($output =~/SUCCESS/i) {
		starmade_if_debug(1, "starmade_sector_chmod: return 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_sector_chmod: return 0");
	return 0;
};

## starmade_sector_info
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
sub starmade_sector_info {
	my $sector = $_[0];

	starmade_if_debug(1, "starmade_sector_info($sector)");
	starmade_validate_env();
	my @output = starmade_cmd("/sector_info", split(" ", $sector));
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
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{entity}{$name}{faction} = $faction_id");
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{entity}{$name}{pos} = $pos");
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
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{protected} = $protected");
			starmade_if_debug(1, "starmade_sector_info: return(multiline): %HASH{general}{info}{peace} = $peace");
		};
	};
	return \%sector_info;
};

## starmade_get_spawn_sector
# gets the current player spawn sector
# OUTPUT: player spawn sector in space seperated list
sub starmade_get_spawn_sector {
	my $sector_x = starmade_get_main_conf_field("DEFAULT_SPAWN_SECTOR_X");
	my $sector_y = starmade_get_main_conf_field("DEFAULT_SPAWN_SECTOR_Y");
	my $sector_z = starmade_get_main_conf_field("DEFAULT_SPAWN_SECTOR_Z");
	return "$sector_x $sector_y $sector_z";
}

1;
