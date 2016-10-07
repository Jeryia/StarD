package Starmade::Chat;
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

	print $message;
	print "\n";
	$message = fix_newlines($message);
	my $out = join("",starmade_cmd("/chat $message"));
	if ($out =~/\Qbroadcasted as server message:\E/) {
		starmade_if_debug(2, "starmade_broadcast: return: 1");
		return 1;
	};
	starmade_if_debug(1, "starmade_broadcast: return: 0");
	return 0;
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
	if ($player =~/\S/) {
		$message = fix_newlines($message);
		my $out = join("",starmade_cmd("/pm $player $message"));
		if ($out =~/\Qsend to $player as server message:\E/) {
			starmade_if_debug(1, "starmade_pm: return: 1");
			return 1;
		};
	}
	else {
		print $message;
		print "\n";
		starmade_if_debug(1, "starmade_pm: return: 1");
		return 1;
	}
	starmade_if_debug(1, "starmade_pm: return: 0");
	return 0;
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

## fix_newlines
# As starmade does not recognize the new line character, we simulate it with 
# spaces, as lines wrap in chat
# INPUT1: message
# OUTPUT: modified message
sub fix_newlines {
	my $message = $_[0];

	# length of line required to cause it to wrap
	my $line_len = 300;
	my @lines = split("\n", $message);

	# Iterate over all but the last one
	for (my $line_num = 0; $line_num < $#lines; $line_num++) {
		my $len = length($lines[$line_num]);
		my $whitespace = " " x ($line_len - $len);
		$lines[$line_num] .= $whitespace;
	}
	return join("", @lines);
}


1;
