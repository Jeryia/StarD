#!perl
package Civ::Base;
use strict;
use warnings;

use lib("../../lib/perl");
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

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT=qw(get_station_options reqs_ok reputation_ok reputation_get reputation_add expand_array populate_map_cache read_basic_config write_basic_config map_faction populate_faction_map_cache);


our $CONFIG_DIR = "./config";
our $CONFIG_FILE = "$CONFIG_DIR/civ.conf";
our $MAP_FILE = "$CONFIG_DIR/civ.map";
our $FACTION_CONFIG = "$CONFIG_DIR/factions.conf";

our $DATA = "./data";
our $PLAYER_DATA = "$DATA/players";
our $FACTION_MAP_FILE = "$DATA/faction_map";
our $MAP_CREATED = "$DATA/map.created";

my %blank_hash = ();


our %MAP_CACHE = ();
our %FACTION_MAP_CACHE = ();

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
	elsif ($sector_info{entity}{"ENTITY_SHIP_$station_name"}{pos}) {
		$station_pos = $sector_info{entity}{"ENTITY_SHIP_$station_name"}{pos};
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

sub reqs_ok {
	my $player = shift(@_);
	my %info = %{shift(@_)};

	if ($info{chance_offered}) {
		if ($info{chance_offered} <= int(rand(100))) {
			return 0;
		}
	}

	if ($info{need_reputation}) {
		my @rep_strings = @{expand_array($info{need_reputation})};
		foreach my $rep_string (@rep_strings) {
			# regex match: Terran_Alliance >= 2
			if ($rep_string=~/(\S+)\s+(=|==|>|<|<=|>=)\s+(\d+)/) {
				my $rep_name = $1;
				my $comp_op = $2;
				my $value = $3;
				if (!reputation_ok($player, $rep_name, $comp_op, $value)) {
					return 0;
				}
			}
			else {
				print "Malformed reputation string: '$rep_string'! Assuming not met\n";
				return 0;
			}
		}
	}
	return 1;
}

sub reputation_ok {
	my $player = shift(@_);
	my $rep_name = shift(@_);
	my $comp_op = shift(@_);
	my $value = shift(@_);
	
	my $rep = reputation_get($player, $rep_name);
	$comp_op=~s/^=$/==/;


	if ($comp_op eq '>=') {
		if ($rep >= $value) {
			return 1;
		}
		return 0;
	}
	if ($comp_op eq '<=') {
		if ($rep <= $value) {
			return 1;
		}
		return 0;
	}
	if ($comp_op eq '>') {
		if ($rep > $value) {
			return 1;
		}
		return 0;
	}
	if ($comp_op eq '<') {
		if ($rep < $value) {
			return 1;
		}
		return 0;
	}
	if ($comp_op eq '==') {
		if ($rep == $value) {
			return 1;
		}
		return 0;
	}
}

sub reputation_get {
	my $player = shift(@_);
	my $rep_name = shift(@_);

	my $rep;

	open(my $fh, "<", "$PLAYER_DATA/$player/Reputation/$rep_name") or return 0;
	flock($fh, 1) or return 0;
	$rep = <$fh>;
	close($fh);

	$rep=~s/\s//g;
	if ($rep =~/^-?\d+$/) {
		return $rep;
	}
	return 0;
}

sub reputation_add {
	my $player = shift(@_);
	my $rep_name = shift(@_);
	my $amount = shift(@_);

	my $cur_rep = 0;
	my $fh_r;
	my $fh_w;

	system('mkdir', '-p', "$PLAYER_DATA/$player/Reputation");
	if(open($fh_r, "<", "$PLAYER_DATA/$player/Reputation/$rep_name")) {
		flock($fh_r, 2) or return 0;
		$cur_rep = int(<$fh_r>); 
	}

	open($fh_w, ">", "$PLAYER_DATA/$player/Reputation/$rep_name") or return 0;
	print $fh_w ($cur_rep + $amount);

	close($fh_w);
	close($fh_r);

	return 0;
}

sub expand_array {
	my $array = shift(@_);
	my @return = ();

	if (ref $array eq 'ARRAY') {
		foreach my $item (@{$array}) {
			push(@return, split(',', $item));
		}
	}
	else {
		push(@return, split(',', $array));
	}
	return \@return;
}

sub populate_map_cache {
	if (!%MAP_CACHE) {
		%MAP_CACHE = %{stard_read_config($MAP_FILE)};
	}
}

sub read_basic_config {
	my $config_file = shift(@_);

	my %config = ();
	my $config_fh;
	if (!open($config_fh, "<", $config_file)) {
		print "Error opening $config_file: $!\n";
		return \%config;
	}
	my @lines = <$config_fh>;
	close($config_fh);
	Line: foreach my $line (@lines) {
		if ($line=~/^\s*(\S+)\s*=(.*)/) {
			my $field = $1;
			my $value = $2;
			# trim out any whitespace at the beginning or end
			$field=~s/^\s+//g;
			$field=~s/\s+$//g;
			$value=~s/^\s+//g;
			$value=~s/\s+$//g;
			$value=~s/^"//g;
			$value=~s/"$//g;
			$value=~s/^'//g;
			$value=~s/'$//g;
			
			$config{$field} = $value;
			$config{$field}=~s/^\s+//g;
		};
	};
	return \%config;
};

## write_basic_config
# Write out a hash to a config file
# INPUT1: config file to write to
# INPUT2: Hash to write to the config file (only supports 1d hash)
# OUTPUT: success or failure (boolean)
sub write_basic_config {
	my $config_file = shift(@_);
	my %config = %{shift(@_)};

	open(my $config_fh, ">", $config_file) or return 0;

	Line: foreach my $key (keys %config) {
		print $config_fh "$key='$config{$key}'\n";
	};
	close($config_fh);
	return 1;
}

sub map_faction {
	my $faction = shift(@_);

	populate_faction_map_cache();

	if ($FACTION_MAP_CACHE{$faction}) {
		return $FACTION_MAP_CACHE{$faction};
	}
	return $faction;
}
sub populate_faction_map_cache {
	if (!%FACTION_MAP_CACHE) {
		%FACTION_MAP_CACHE = %{read_basic_config($FACTION_MAP_FILE)};
	}
}

1;
