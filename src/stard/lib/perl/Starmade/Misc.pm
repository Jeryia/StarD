package Starmade::Misc;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_search starmade_loc_distance starmade_location_add starmade_random_pos starmade_status starmade_wait_until_running starmade_sql_query);


my %SHIP_BP_CATALOG_CACHE = ();

## starmade_search 
# Locate ships/stations that start with the given pattern
# INPUT1: pattern
# OUTPUT: hash of result ships -> sector
sub starmade_search {
	my $pattern = $_[0];
	
	starmade_if_debug(1, "starmade_search($pattern)");
	starmade_validate_env();
	my @output = starmade_cmd("/search", $pattern);
	my %ships;

	foreach my $line (@output) {
		#RETURN: [SERVER, FOUND: Station_Piratestation Alpha_6_9_0_1441738472505 -> (6, 9, 0), 0]
		if ($line=~/RETURN: \[SERVER, FOUND: (.*) -> \((-?\d+), (-?\d+), (-?\d+)\), \d+]/) {
			$ships{$1} = "$2 $3 $4";
			starmade_if_debug(1, "starmade_search: return(multiline): %HASH{$1} = '$2 $3 $4'");
		}
	}
	return \%ships;
}

## starmade_loc_distance
# Return the distance between two locations (sectors or pos)
# INPUT1: location 1 (space seperated list)
# INPUT2: location 2 (space seperated list)
# OUTPUT: distance between the points (float)
sub starmade_loc_distance {
	my $loc1 = $_[0];
	my $loc2 = $_[1];

	my @coords1 = split(" ", $loc1);
	my @coords2 = split(" ", $loc2);

	my @diff;

	for (my $i = 0; $i < 3; $i++) {
		$diff[$i] = $coords1[$i] - $coords2[$i];
	}

	return sqrt(abs(($diff[0])**2 + ($diff[1])**2 + ($diff[2])**2));
}

## starmade_location_add
# Add two location strings together (sectors or pos).
# INPUT1: location string (space delimited list)
# INPUT2: location string (space delimited list)
# OUTPUT: added location strings (space delimited list)
sub starmade_location_add {
	my $location1 = $_[0];
	my $location2 = $_[1];
	my @l1 = split(" ", $location1);
	my @l2 = split(" ", $location2);
	my @return;
	for (my $i = 0; $i < 3; $i++) {
		$return[$i] = $l1[$i] + $l2[$i];
	}
	return join(" ", @return);
};

## starmade_random_pos
# Provide a random position in to spawn units in the given sector
# OUTPUT: position (space seperated list)
sub starmade_random_pos {
	my $sector_size = get_starmade_conf_field('SECTOR_SIZE');

	return int(rand($sector_size * 2 - 500) - $sector_size)
		. " " . int(rand($sector_size * 2 - 500) - $sector_size) 
		. " " . int(rand($sector_size * 2 - 500) - $sector_size)
	;
}

## starmade_status
# Check if the starmade server is running
# OUTPUT: true if running false if not
sub starmade_status {
	my $status = join("", starmade_cmd("/status"));
	if ($status =~/RETURN: \[SERVER,/) {
		return 1;
	};
	return 0;
}

## starmade_wait_until_running
# Block until the starmade daemon is found to be running. Also includes skew to 
# avoid many daemons from querying the starmade server at once.
sub starmade_wait_until_running {
	my $is_running = 0;
	my $skew = 5;

	while (!$is_running) {
		$is_running = starmade_status();
		my $sleep_time = rand($skew);
		select(undef, undef, undef, $sleep_time);
	};
}


## starmade_sql_query
# Run the given sql query
# INPUT1: query to run
# INPUT2: skip header (boolean) 1 to not provide the sql headers, 0 to provide them
# OUTPUT: 2d array hash in format of: $array[row #][entry #]
sub starmade_sql_query {
	my $query = shift(@_);
	my $skip_headers = shift(@_);

	starmade_if_debug(1, "starmade_sql_query('$query', $skip_headers)");
	starmade_validate_env();
	my @lines = starmade_cmd('/sql_query', $query);
	my @return = ();
	my $header = 0;
	Line: foreach my $line (@lines) {
		if ($line=~/^RETURN: \[SERVER, SQL#\d+: "(.*)", 0]$/) {
			if (not $header and $skip_headers) {
				$header++;
				next Line;
			}
			my $result = $1;
			my @entries = split('";"', $result);
			push(@return, \@entries);
			starmade_if_debug(1, "starmade_search: return(multiline): \@ARRAY[] = '" . join(',', @entries) . "'");
		}
	}
	return \@return;
}


1;


