#!perl
package reg_lib;
use strict;
use warnings;

use Starmade::Message;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ck_file_string);


my $stard_home = "../..";

## ck_file_string
# check for a specific string in a file's contents
# INPUT1: file
# INPUT2: string
# OUTPUT: (boolean) true if string is found, false if not
sub ck_file_string {
	my $file = shift(@_);
	my $string = shift(@_);

	my $fh;
	if (!open($fh, "<", $file)) {
		warn "Failed to open file '$file': $!\n";
		starmade_broadcast("Failed to open file '$file': $!\n");
		return 0;
	}
	while (<$fh>) {
		if ($_ =~/\Q$string\E/) {
			return 1;
		}
	}
	return 0;
}
