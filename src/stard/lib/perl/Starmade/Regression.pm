package Starmade::Regression;
use strict;
use warnings;

use lib("../../lib");
use Starmade::Message;
use Stard::Base;

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);



@EXPORT = qw(prep_test_category finalize_testing test_result test_command test_event);

my %TESTS_TO_RUN = ();
my %TESTS_PASSED = ();
my $CUR_CATEGORY = "";
my $SUB_TEST = 0;
my %TESTS_FAILED = ();

## prep_test_category
# prepare testing for a given category
# INPUT1: category
# INPUT2: tests to run
# INPUT3: sub test
sub prep_test_category {
	my $category = shift(@_);
	my $tests = shift(@_);
	if (@_) {
		$SUB_TEST = shift(@_);
	}

	$CUR_CATEGORY = $category;
	$TESTS_TO_RUN{$category} = $tests;
	$TESTS_PASSED{$CUR_CATEGORY} = 0;
	$TESTS_FAILED{$CUR_CATEGORY} = 0;
	starmade_broadcast("### Running $category Tests ###");
}

## testing_finalize
# end testing and report results
sub finalize_testing {
	my $total_tests = 0;
	my $errors = 0;
	starmade_broadcast("################################");
	foreach my $category (keys %TESTS_TO_RUN) {
		my $tests = $TESTS_PASSED{$category};
		$total_tests += $TESTS_PASSED{$category};
		$total_tests += $TESTS_FAILED{$category};

		starmade_broadcast("## $category: $TESTS_PASSED{$category}/$TESTS_TO_RUN{$category}");
		if ($TESTS_PASSED{$category} != $TESTS_TO_RUN{$category}) {
			$errors++;
			starmade_broadcast("FAIL! We didn't run $TESTS_TO_RUN{$category} we only ran $TESTS_PASSED{$category}!");
		}
		if ($TESTS_FAILED{$category}) {
			$errors+=$TESTS_FAILED{$category};
			starmade_broadcast("We failed $TESTS_FAILED{$category} tests!");
		}
	}
	if (not $SUB_TEST) {
		starmade_broadcast("Total tests run: $total_tests");
	}
	starmade_broadcast("############");
	starmade_broadcast("Total Failures: $errors");
	if (not $SUB_TEST) {
		if ($errors) {
			starmade_broadcast("Final Result: FAIL... :(");
		}
		else {
			starmade_broadcast("Final Result: SUCCESS!!!!!");
		}
	}
}


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
	select(undef, undef, undef, 0.1);
	if ($result) {
		starmade_broadcast("$test - PASS");
		$TESTS_PASSED{$CUR_CATEGORY}++;
		return 1;
	}
	else {
		starmade_broadcast("$test - FAIL");
		$TESTS_FAILED{$CUR_CATEGORY}++;
		if ($message) {
			starmade_broadcast($message);
		};
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
