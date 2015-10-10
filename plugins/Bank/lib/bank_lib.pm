use strict;
use warnings;
#Copyright (c) 2015, Jeryia
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

my $bank_data = "./data/";
mkdir $bank_data;

sub bank_lock_account {
	my $player = $_[0];

	my $file = "$bank_data/$player";
	system("touch", $file);
	open(my $lock_fh, "<", "$bank_data/$player") or return 0;
	flock($lock_fh, 2) or return 0;
	return $lock_fh;
};


sub bank_unlock_account {
	my $lock_fh = $_[0];
	close($lock_fh) or return 0;
	return 1;
};

sub bank_get_balance {
	my $player = $_[0];

	my $file = "$bank_data/$player";
	if (open(my $account_fh, "<", $file)) {
		my $in_bank = join("", <$account_fh>);
		$in_bank =~s/\D+//ig;
		if (!($in_bank=~/\d/)) {
			$in_bank = 0;
		};
		close($account_fh);
		return $in_bank;
	}
	return 0;
}

sub bank_set_amount {
	my $player = $_[0];
	my $amount = $_[1];

	if ($amount =~/\D+/) {
		return 0;
	};

	my $file = "$bank_data/$player";
	if (open(my $account_fh, ">", $file)) {
		print $account_fh $amount;
		close($account_fh);
		return 1;
	}
	return 0;
}


sub bank_add_amount {
	my $player = $_[0];
	my $amount = $_[1];
	
	my $in_bank = bank_get_balance($player);
	my $new_amount = $amount + $in_bank;

	return bank_set_amount($player, $new_amount);
}

sub get_player_credits {
	my $player = $_[0];
	
	my %player_info = %{stard_player_info($player)};
	return $player_info{credits};
}

1;
