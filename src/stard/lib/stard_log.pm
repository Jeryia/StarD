package stard_log;
use strict;
use warnings;
use POSIX;


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

## Log libraries for stard.
# This provides stdout loggin capabilities to stard

our (@ISA, @EXPORT);

require Exporter;
@ISA = qw(Exporter);
my $loglevel = 0;

my @level_name;
$level_name[0] = "Emergency";
$level_name[1] = "Alert";
$level_name[2] = "Critical";
$level_name[3] = "Error";
$level_name[4] = "Warning";
$level_name[5] = "Notice";
$level_name[6] = "Info";
$level_name[7] = "Debug1";
$level_name[8] = "Debug2";


@EXPORT = qw(set_loglevel stdout_log gen_logmessage);

## set_loglevel
# Set the logging level to trigger on
# INPUT1: level to set logging
sub set_loglevel {
	my $level = $_[0];
	$loglevel = $level;
}

## stdout_log 
# log message to STDOUT appending date and time
# INPUT1: messages to log
# INPUT2: level of priority for the message
sub stdout_log {
	my $message = $_[0];
	my $level = $_[1];

	if (! (defined $level)) {
		$level = 6;
	};

	if ($level <= $loglevel) {
		print gen_logmessage($message, $level_name[$level]);
	}
}

## gen_logmessage 
# Generate the text for a log message and return it
# INPUT1: message
# OUTPUT: log text
sub gen_logmessage {
	my $message = $_[0];
	my $type = $_[1];
	
	my $log = '[' . strftime("%F %T", localtime time) . '] ';
	$log .= "[$type] ";
	$log .= $message . "\n";
	return $log;
}




1;
