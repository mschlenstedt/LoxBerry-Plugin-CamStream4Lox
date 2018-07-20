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

##########################################################################
# Modules
##########################################################################

use LoxBerry::System;
use LoxBerry::Log;
use Getopt::Long;

##########################################################################
# Read Settings
##########################################################################

# Version of this script
my $version = "0.0.1";

my $pcfg     = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");
my $httpport     = $pcfg->param("FFSERVER.HTTPPORT");

# Create a logging object
my $log = LoxBerry::Log->new ( 	name => 'buildconfig',
			filename => "$lbplogdir/buildconfig.log",
			append => 1,
);

# Commandline options
my $verbose = '';

GetOptions ('verbose' => \$verbose,
            'quiet'   => sub { $verbose = 0 });

# Due to a bug in the Logging routine, set the loglevel fix to 3
if ($verbose) {
	$log->stdout(1);
	$log->loglevel(7);
}

LOGSTART "CamStream4Lox Build Config process started";
LOGDEB "This is $0 Version $version";

if (-e "$lbpconfigdir/ffserver.conf") {

	LOGINF "Backing up existing FFServer Configuration $lbpconfigdir/ffserver.conf";
	system ("cp $lbpconfigdir/ffserver.conf $lbpconfigdir/ffserver.conf.bkp");

}

LOGINF "Building $lbpconfigdir/ffserver.conf";
open(F,">$lbpconfigdir/ffserver.conf") or $error = 1;
if ($error) {
	LOGCRIT "Cannot open $lbpconfigdir/ffserver.conf for writing.";
	LOGEND "Exit.";
	exit 2;
}

LOGINF "HTTPPort $httpport";
print F "HTTPPort $httpport\n";

if (-e "$lbpconfigdir/ffserver_serverdefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_serverdefaults.conf";

	open(F1,"<$lbpconfigdir/ffserver_serverdefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_serverdefaults.conf. Skipping";
		$error = 0;
	} else {
		my @ffserverdefaults = <F1>;
		foreach (@ffserverdefaults){
			s/[\n\r]//g;
			LOGINF "$_";
			print F "$_\n";
		}
	}
}

# Exit
LOGEND "Exit.";
exit;
