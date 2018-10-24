#!/usr/bin/perl

# buildwebpage
# Creates overview webpage (Multiview)
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

##########################################################################
# Modules
##########################################################################

use LoxBerry::System;
use LoxBerry::Log;

##########################################################################
# Read Settings
##########################################################################

# Version of this script
my $version = "0.0.1";

my $pcfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

# Commandline options
my $verbose = '';
GetOptions ('verbose' => \$verbose,
            'quiet'   => sub { $verbose = 0 });

##########################################################################
# Check if we should run at all
##########################################################################

# Search for active VLC cams
my $vlcstart = 0;
for (my $i=1;$i<=10;$i++) {
	if ($pcfg->param("CAM$i.VLCACTIVE")) {
		$vlcstart =1;
		last;
	}
}

if ( !$pcfg->param("FFSERVER.START") && !$vlcstart ) {
	exit (0);
}

##########################################################################
# Read Settings
##########################################################################

# Create a logging object
my $log = LoxBerry::Log->new ( 	name => 'buildmultiview',
			package => 'camstream4lox',
			logdir => "$lbplogdir",
			#filename => "$lbplogdir/watchdog.log",
			#append => 1,
);

if ($verbose) {
	$log->stdout(1);
	$log->loglevel(7);
}

LOGSTART "buildmultiview started.";

LOGDEB "This is $0 Version $version";

##########################################################################
# Main program
##########################################################################

my $openerr = 0;
open(F,">$lbphtmldir/index.html") or ($openerr = 1);
if ($openerr) {
	LOGERR "Could not open index.html for writing. Giving up.";
	LOGEND;
	exit (1);
}

# Own IP Adress
my $ip = LoxBerry::System::get_localip();

print F <<EOF;
<html>
<head>
<title>CamStream4Lox</title>
<META content="text/html"; charset="UTF-8"; http-equiv=Content-Type>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
</head>
<body>
<center>
EOF

if ( $pcfg->param("FFSERVER.START") ) {

	my $ffserverport = $pcfg->param("FFSERVER.HTTPPORT");
	for (my $i=1;$i<=10;$i++) {
		if ($pcfg->param("CAM$i.ACTIVE")) {
			LOGINF "FFServer Cam$i is active - adding to multiview.";
			print F "<a href=\"./ffserver_cam$i.html\"><img src=\"http://$ip:$ffserverport/cam$i.mjpg\" width=\"320\"></a>\n";
			my $openerr = 0;
			open(F1,">$lbphtmldir/ffserver_cam$i.html") or ($openerr = 1);
			if ($openerr) {
			        LOGWARN "Could not open ffserver_cam$i.html for writing, but I will continue.";
			}
			print F1 <<EOF;
<html>
<head>
<title>CamStream4Lox</title>
<META content="text/html"; charset="UTF-8"; http-equiv=Content-Type>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
</head>
<body>
<center>
<a href="./index.html"><img src="http://$ip:$ffserverport/cam$i.mjpg"></a>
</center>
</body>
</html>
EOF
			close (F1);
		} else {
			LOGINF "FFserver Cam$i is not active. Skipping.";
		}
	}

}

my $vlcport = $pcfg->param("VLC.HTTPPORT");
for (my $i=1;$i<=10;$i++) {
	if ($pcfg->param("CAM$i.VLCACTIVE")) {
		LOGINF "VLC Cam$i is active - adding to multiview.";
		my $port = $vlcport+$i-1;
		print F "<a href=\"./vlc_cam$i.html\"><img src=\"http://$ip:$port/cam$i.mjpg\" width=\"320\"></a>\n";
		my $openerr = 0;
		open(F1,">$lbphtmldir/vlc_cam$i.html") or ($openerr = 1);
		if ($openerr) {
		        LOGWARN "Could not open vlc_cam$i.html for writing, but I will continue.";
		}
		print F1 <<EOF;
<html>
<head>
<title>CamStream4Lox</title>
<META content="text/html"; charset="UTF-8"; http-equiv=Content-Type>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
</head>
<body>
<center>
<a href="./index.html"><img src="http://$ip:$port/cam$i.mjpg"></a>
</center>
</body>
</html>
EOF
			close (F1);
	} else {
		LOGINF "VLC Cam$i is not active. Skipping.";
	}
}

print F <<EOF;
</center>
</body>
</html>
EOF

close (F);

LOGEND;
exit 0;
