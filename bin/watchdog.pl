#!/usr/bin/perl

# buildconfig.pl
# Creates the configfile for ffserver
#
# Copyright 2018 Michael Schlenstedt, michael@loxberry.de
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

# Global vars
my $streamok;
my $restart;
my $verbose = 0;

##########################################################################
# Modules
##########################################################################

use LoxBerry::System;
use LoxBerry::Log;
use LWP::Simple; 

##########################################################################
# Read Settings / Logging
##########################################################################

# Version of this script
my $version = "0.0.1";

my $pcfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

# Create a logging object
my $log = LoxBerry::Log->new ( 	name => 'watchdog',
			filename => "$lbplogdir/watchdog.log",
			append => 1,
);

LOGSTART "Watchdog for FFServer";

if ($verbose || $log->loglevel() eq "7") {
	$log->stdout(1);
	$log->loglevel(7);
}

##########################################################################
# Main program
##########################################################################

my $port = $pcfg->param("FFSERVER.HTTPPORT");
my $status = "http://localhost:$port/status.html";
my $website_content = get($status);

$restart = 0;
for (my $i=1;$i<=10;$i++) {
	$streamok = 0;
	if ($pcfg->param("CAM$i.ACTIVE")) {
		LOGINF "Cam$i is active - checking state.";
		while ($website_content =~ /<tr><td><b>(.*)<\/b><td>(.*)<td>(.*)<td>(.*)<td>(.*)<td align=right>(.*)<td align=right>(.*)<td align=right>(.*)/g) {
    			my($no, $file, $ip, $proto, $state, $targetbits, $actualbits, $transfered) = ($1, $2, $3, $4, $5, $6, $7, $8);
			if ($file eq "cam$i.ffm(input)" && $state eq "RECEIVE_DATA") {
				$streamok = 1;
			}
			#print "Number: $no\n";
			#print "File  : $file\n";
			#print "IP    : $ip\n";
			#print "Proto : $proto\n";
			#print "State : $state\n";
			#print "Target: $targetbits\n";
			#print "Actual: $actualbits\n";
			#print "Transf: $transfered\n";
		}
		if ($streamok) {
			LOGOK "Cam$i seems to be ok. Nothing to do.";
		} else {
			LOGWARN "Cam$i is NOT ok. FFServer has to be restarted.";
			$restart = 1;
		}
	} else {
		LOGINF "Cam$i is not active. Skipping.";
	}
}

if ($restart) {
	LOGINF "Restarting FFServer";
	system ("$lbpbindir/ffserver.sh stop");
	sleep (10);
	system ("$lbpbindir/ffserver.sh start");
}
