package Starmade::Blueprints;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_blueprint_info starmade_blueprint_delete starmade_blueprint_set_owner starmade_catalog_list starmade_in_bp_catalog starmade_in_bp_catalog_lazy starmade_get_bp_catalog starmade_refresh_bp_catalog_cache);


my %SHIP_BP_CATALOG_CACHE = ();


## starmade_blueprint_info
# Get information about a specific blueprint
# INPUT1: blueprint name
# OUTPUT: blueprint hash %HASH{field} = value
sub starmade_blueprint_info {
	my $blueprint = shift(@_);

	my @output = starmade_cmd("/blueprint_info", $blueprint);
	my %bp_info = ();
	Line: for my $line (@output) {
		if ($line =~/^RETURN:/) {
			next Line;
		}
		if ($line=~/^\s*(\S+):\s+(.*)$/) {
			$bp_info{$1} = $2;
		}
	}
	return \%bp_info;
}

## starmade_blueprint_delete
# Delete a blueprint form the catalog
# INPUT1: blueprint name
# OUTPUT: 1 if success 0 if failure
sub starmade_blueprint_delete {
	my $blueprint = shift(@_);

	return _starmade_pf_cmd('starmade_blueprint_delete', '/blueprint_delete', $blueprint);
}

## starmade_blueprint_set_owner
# Set the owner of a given blueprint
# INPUT1: blueprint name
# OUTPUT: 1 if success 0 if failure
sub starmade_blueprint_set_owner {
	my $blueprint = shift(@_);
	my $player = shift(@_);

	return _starmade_pf_cmd('starmade_blueprint_set_owner', '/blueprint_set_owner', $blueprint, $player);
}

## starmade_catalog_list
# get the list of ships from the starmade catalog
# INPUT1: (optional) owner
sub starmade_catalog_list {
	my $owner;
	if (@_) {
		$owner = shift(@_);
	}

	my @output;
	if ($owner) {
		@output = starmade_cmd("/list_blueprints_by_owner", $owner);
	}
	else {
		@output = starmade_cmd("/list_blueprints");
	}
	my @list;
	#RETURN: [SERVER, [CATALOG] INDEX 98: TCN Argosy MkVI save15, 0]
	for my $line (@output) {
		if ($line =~/RETURN: \[SERVER, \[CATALOG\] INDEX \d+: (.*), 0\]/) {
			push(@list, $1);
		}
	}
	return \@list;
}

## starmade_in_bp_catalog
# Check if given ship is in the catalog
# INPUT1: blueprint name
# OUTPUT: 1 if in catalog, 0 if not
sub starmade_in_bp_catalog {
	my $ship = shift(@_);
	my ($blueprint) = split(':', $ship);

	starmade_get_bp_catalog();
	
	return $SHIP_BP_CATALOG_CACHE{$blueprint};
}

## starmade_in_bp_catalog_lazy
# Check if given ship is in the catalog. Checks the blueprints folder, so it 
# won't know if the blueprint is actually loaded on the server, just that 
# it's in the blueprints folder. This is a lot less overhead at the cost of
# the edge case mentioned above.
# INPUT1: blueprint name
# OUTPUT: 1 if in catalog, 0 if not
sub starmade_in_bp_catalog_lazy {
	my $blueprint = shift(@_);
	my $server_home = get_server_home();
	if ( -d "$server_home/../StarMade/blueprints/$blueprint" ) {
		return 1;
	}
	return 0;
}

## starmade_get_bp_catalog
# Get the current ship blueprint catalog
# OUTPUT: (hash) blueprint catalog entries. format: $HASH{name} = 1
sub starmade_get_bp_catalog {
	if (!%SHIP_BP_CATALOG_CACHE) {
		starmade_refresh_bp_catalog_cache();
	}
	return \%SHIP_BP_CATALOG_CACHE
}

## starmade_refresh_bp_catalog_cache
# Refresh the cache of the blueprint catalog.
sub starmade_refresh_bp_catalog_cache {
	my @list = @{starmade_catalog_list()};
	foreach my $ship (@list) {
		$SHIP_BP_CATALOG_CACHE{$ship} = 1;
	}
	return \%SHIP_BP_CATALOG_CACHE
}


1;


