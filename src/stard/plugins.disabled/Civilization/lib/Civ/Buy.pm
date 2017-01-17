#!perl
package Civ::Buy;
use strict;
use warnings;

use lib("../../lib/perl");
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
@EXPORT=qw(get_avail_item_list item_info populate_item_info_cache set_item_avail_cur get_item_avail_cur clear_item_avail_cur);

## locations of the different configuration files for each category.
our %CATEGORY_CONF_FILE;
$CATEGORY_CONF_FILE{ship} = "$Civ::Base::CONFIG_DIR/buy_ships.conf";
$CATEGORY_CONF_FILE{blocks} = "$Civ::Base::CONFIG_DIR/buy_blocks.conf";
$CATEGORY_CONF_FILE{dock} = "$Civ::Base::CONFIG_DIR/buy_docks.conf";

our %CATEGORY_CONF;
$CATEGORY_CONF{ship} = "buy_ships";
$CATEGORY_CONF{blocks} = "buy_blocks";
$CATEGORY_CONF{dock} = "buy_docks";

my %ITEM_INFO_CACHE = ();


my %blank_hash = ();

sub get_avail_item_list {
	my $player = shift(@_);

	my %station_options = %{get_station_options($player)};
	my %potential_items = ();
	my %avail_items = %{get_item_avail_cur($player)};

	if (%avail_items) {
		return \%avail_items;
	}
	
	# Gather items we may use at this location
	foreach my $category (keys %CATEGORY_CONF) {
		if ($station_options{$CATEGORY_CONF{$category}}) {
			$potential_items{$category} = @{expand_array($station_options{$CATEGORY_CONF{$category}})};
		}
	}

	# Check each item to see if it if offered at this time.
	foreach my $category (keys %CATEGORY_CONF) {
		my @items = ();
		foreach my $item (@{$potential_items{$category}}) {
			my %item_info = %{item_info($item, $category)};
			if (reqs_ok($player, \%item_info)) {
				push(@items, $item);
			}
		}
		if (@items) {
			$avail_items{$category} = \@items;
		}
	}

	set_item_avail_cur($player, \%avail_items);
	return \%avail_items;
}


## item_info
# get the information on a specific item.
# INPUT1: category of item.
# INPUT2: item name
# OUTPUT: hash of item information
sub item_info {
	my $category = shift(@_);
	my $item = shift(@_);

	populate_item_info_cache($category);

	if ($ITEM_INFO_CACHE{$category} && $ITEM_INFO_CACHE{$category}{$item}) {
		return $ITEM_INFO_CACHE{$category}{$item};
	}
	return \%blank_hash;
}

sub populate_item_info_cache {
	my $category = shift(@_);

	if ($CATEGORY_CONF{$category} && !$ITEM_INFO_CACHE{$category}) {
		$ITEM_INFO_CACHE{$category} = stard_read_config($CATEGORY_CONF_FILE{$category});
	}
}
sub set_item_avail_cur {
	my $player = shift(@_);
	my %avail_items = %{shift(@_)};


	my %output = ();
	foreach my $category (keys %avail_items) {
		$output{$category} = join("\n", @{$avail_items{$category}});
	}

	system('mkdir', '-p', "$Civ::Base::PLAYER_DATA/$player");
	write_basic_config("$Civ::Base::PLAYER_DATA/$player/item_avail_cur", \%output);
}

sub get_item_avail_cur {
	my $player = shift(@_);
	my %avail_items = ();

	my %input = %{read_basic_config("$Civ::Base::PLAYER_DATA/$player/item_avail_cur")};

	foreach my $category (keys %input) {
		my @items = split(",", $input{$category});
		$avail_items{$category} = \@items;
	}

	return \%avail_items;
}

sub clear_item_avail_cur {
	my $player = shift(@_);

	unlink("$Civ::Base::PLAYER_DATA/$player/item_avail_cur");
}

1;
