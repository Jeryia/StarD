
package blueprints_reg;
use strict;
use warnings;

use Starmade::Base;
use Starmade::Message;
use Starmade::Player;
use Starmade::Blueprints;
use Starmade::Regression;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(blueprints_reg);


my $stard_home = "../..";

## blueprints_reg
# Perform regression tests for blueprint based functions
# INPUT1: name of the player who requested the testing.
sub blueprints_reg {
	my $player = $_[0];
	my $test;
	my $string;
	my $cmd_result;
	my $input;
	my $echo;

	prep_test_category('Blueprint', 3);
	my %results;
	my $blueprint = 'Isanth Type-Zero Bm';

	test_result("starmade_blueprint_info", starmade_in_bp_catalog($blueprint));
	test_result("starmade_blueprint_info_lazy", starmade_in_bp_catalog_lazy($blueprint));
	%results = %{starmade_blueprint_info($blueprint)};
	test_result("starmade_blueprint_info", $results{'Price'});

	# disabled as these command current crash starmade
	#test_result("starmade_blueprint_set_owner", starmade_blueprint_set_owner($blueprint, $player));
	#test_result("starmade_blueprint_set_owner: no owner", starmade_blueprint_set_owner('Isanth Type-Zero Bm', ''));

}

1;
