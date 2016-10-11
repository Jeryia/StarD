package Starmade::Regression;
use lib("../../lib");
use Starmade::Chat;
use Stard::Base;

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);


@EXPORT = qw(test_result test_command test_event);

## test_result
# Process the result of the test and report on it. Also wait .25 seconds to not 
# slam the starmade server.
# INPUT1: test being run
# INPUT2: (boolean) 0 if failure, nonzero if success
# INPUT3: Optional message to include with failure results
sub test_result {
	my $test = $_[0];
	my $result = $_[1];
	my $message = $_[2];
	select(undef, undef, undef, 0.25);
	if ($result) {
		starmade_broadcast("$test - PASS");
		return 1;
	}
	else {
		starmade_broadcast("$test - FAIL");
		if ($message) {
			starmade_broadcast($message);
		};
		exit 1;
	};
	return 0;
};

## test_command
# Launches a cammand withing the plugin's directory
# Note this is intended only for testing as it will only
# Launch tests for the current plugin
# INPUT1: command name
# INPUT2-*: args
# OUTPUT: return code
sub test_command {
	my $cmd = shift(@_);
	my @args = @_;

	$cmd = "./commands/$cmd";
	my $exec = get_exec_prefix($cmd);
	return system($exec, $cmd, @args);
}
                                       
## test_event
# Launches a server event withing the plugin's directory
# Note this is intended only for testing as it will only
# Launch tests for the current plugin
# INPUT1: command name
# INPUT2-*: args
# OUTPUT: return code
sub test_event {
	my $event = shift(@_);
	my @args = @_;

	$event = "./serverEvents/$event";
	my $exec = get_exec_prefix($event);
	return system($exec, $event, @args);
}

1;
