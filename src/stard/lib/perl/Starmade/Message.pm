package Starmade::Message;
use strict;
use warnings;
use Carp;

use Starmade::Base;

require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT= qw(starmade_setup_lib_env starmade_broadcast starmade_pm starmade_countdown);


## starmade_broadcast
# Broadcast a server message to all players on the starmade server.
# INPUT1: message to broadcast
# OUTPUT: 1 if successfull, 0 is not
sub starmade_broadcast {
	my $message = $_[0];

	starmade_if_debug(1, "starmade_broadcast($message)");
	starmade_validate_env();

	my $ret =1;
	print $message;
	print "\n";
	my @lines = split("\n", $message);
	foreach my $line (@lines) {
		my $out = join("",starmade_cmd("/chat $line"));
		if (!($out =~/\Qbroadcasted as server message:\E/)) {
			$ret = 0;
		};
		sleep .1;
	}
	starmade_if_debug(2, "starmade_broadcast: return: $ret");
	return $ret;
};


## starmade_pm
# send a private message to a player
# INPUT1: player to send message to
# INPUT2: message to send
# OUTPUT: 1 if successful, 0 if not
sub starmade_pm {
	my $player = $_[0];
	my $message = $_[1];

	starmade_if_debug(1, "starmade_pm($player, $message)");
	starmade_validate_env();
	my $ret = 1;
	if ($player =~/\S/) {
		my @lines = split("\n", $message);
		foreach my $line (@lines) {
			my $out = join("",starmade_cmd("/pm $player $line"));
			if (!($out =~/\Qsend to $player as server message:\E/)) {
				$ret = 0;
			}
			sleep .1;
		}
	}
	else {
		print $message;
		print "\n";
	}
	starmade_if_debug(1, "starmade_pm: return: $ret");
	return $ret;
};

## starmade_countdown
# start a countdown timer on the server
# INPUT1: duration
# INPUT2: message
sub starmade_countdown {
	my $duration = $_[0];
	my $message = $_[1];

	
	starmade_if_debug(1, "starmade_countdown($duration, $message)");
	starmade_validate_env();
	my $output = join("",starmade_cmd("/start_countdown $duration", $message));

	if ($output =~/\[SUCCESS\]/) {
		return 1;
	}
	return 0;
}

1;
