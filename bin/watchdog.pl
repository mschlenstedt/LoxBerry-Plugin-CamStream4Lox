#!/usr/bin/perl

# watchdog
# Restarts ffserver if a feed isn't reachable
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

use Getopt::Long;
#use strict;
#use warnings;

# Global vars
my $streamok;
my $restart;

##########################################################################
# Modules
##########################################################################

use LoxBerry::System;
use LoxBerry::Log;
use LWP::Simple;

##########################################################################
# Read Settings
##########################################################################

# Version of this script
my $version = "0.0.3";

my $pcfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

# Commandline options
my $verbose = '';
GetOptions ('verbose' => \$verbose,
            'quiet'   => sub { $verbose = 0 });

##########################################################################
# Check if we should run at all
##########################################################################

if (!$pcfg->param("FFSERVER.START")) {
	exit (0);
}

if (-e "$lbplogdir/manualstopped") {
	exit (0);
}

##########################################################################
# Read Settings
##########################################################################

# Create a logging object
my $log = LoxBerry::Log->new ( 	name => 'watchdog',
			package => 'camstream4lox',
			name => 'watchdog',
			logdir => "$lbplogdir",
			#filename => "$lbplogdir/watchdog.log",
			#append => 1,
);

if ($verbose) {
	$log->stdout(1);
	$log->loglevel(7);
}

LOGSTART "Watchdog for FFServer started.";

LOGDEB "This is $0 Version $version";

##########################################################################
# Main program
##########################################################################

my $port = $pcfg->param("FFSERVER.HTTPPORT");
my $status = "http://localhost:$port/status.html";

my $website_content = get($status);

# Check if status webpage is reachable
if (!$website_content){
	LOGWARN "Watchdog for FFServer found a problem: Status webpage of FFServer isn't reachable. (Re-)Start FFServer.";
	system ("$lbpbindir/ffserver.sh stop");
	sleep (5);
	system ("$lbpbindir/buildconfig.pl");
	sleep (5);
	system ("$lbpbindir/ffserver.sh start");
	qx{pidof ffserver};
	if ($? eq "0") {
		LOGOK "FFServer started successfully."
	} else {
		LOGERR "FFServer could not be started."
	}
}


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
	sleep (5);
	if ($verbose) {
		system ("$lbpbindir/buildconfig.pl -v");
	} else {
		system ("$lbpbindir/buildconfig.pl");
	}
	sleep (5);
	system ("$lbpbindir/ffserver.sh start");
	qx{pidof ffserver};
	if ($? eq "0") {
		LOGOK "FFServer started successfully."
	} else {
		LOGERR "FFServer could not be started."
	}
}

LOGEND;
exit 0;
