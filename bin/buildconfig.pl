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
my $error;
my @ffserverdefaults;

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

# Create a logging object
my $log = LoxBerry::Log->new ( 	name => 'buildconfig',
			filename => "$lbplogdir/buildconfig.log",
			append => 1,
);

# Commandline options
my $verbose = '';

GetOptions ('verbose' => \$verbose,
            'quiet'   => sub { $verbose = 0 });

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

LOGINF "Checking if Path is writable";

my $path = $pcfg->param("FFSERVER.PATH");
open(F,">$path/writetest") or $error = 1;
if ($error) {
	LOGCRIT "Cannot open $path for writing. Falling back to plugin's data-folder.";
	$path = "$lbpdatadir/tmp";
}
unlink ("$path/writetest");

#
# Server section
#

LOGINF "Adding Server section";
LOGINF "HTTPPort " . $pcfg->param('FFSERVER.HTTPPORT');
print F "HTTPPort " . $pcfg->param('FFSERVER.HTTPPORT') . "\n";

if (-e "$lbpconfigdir/ffserver_serverdefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_serverdefaults.conf";

	open(F1,"<$lbpconfigdir/ffserver_serverdefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_serverdefaults.conf. Skipping";
		$error = 0;
	} else {
		@ffserverdefaults = <F1>;
		foreach (@ffserverdefaults){
			s/[\n\r]//g;
			LOGINF "$_";
			print F "$_\n";
		}
	}
	close (F1);
}

#
# Feed sections
#

LOGINF "Adding Feed section(s)";
@ffserverdefaults = "";
if (-e "$lbpconfigdir/ffserver_feeddefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_feeddefaults.conf";
	open(F1,"<$lbpconfigdir/ffserver_feeddefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_feeddefaults.conf. Skipping";
	$error = 0;
	} else {
		@ffserverdefaults = <F1>;
	}
	close (F1);
}

for (my $i=1;$i<=10;$i++) {
	if ($pcfg->param("CAM$i.ACTIVE")) {
		LOGINF "Adding Feed for Cam $i";
		print F "<Feed cam$i.ffm>\n";
		LOGINF "File " . $path . "/cam$i.ffm";
		print F "File " . $path . "/cam$i.ffm\n";
		LOGINF "Launch ffmpeg -i \"" . $pcfg->param("CAM$i.URL") . "\"";
		print F "Launch ffmpeg -i \"" . $pcfg->param("CAM$i.URL") . "\"\n";
		foreach (split(/,/,$pcfg->param("CAM$i.EXTRAS_FEED"))){
			if ($_) {
				LOGINF $_;
		                print F $_ . "\n";
			}
		}
		if (@ffserverdefaults) {
			foreach (@ffserverdefaults){
				s/[\n\r]//g;
				LOGINF "$_";
				print F "$_\n";
			}
		}
		print F "</Feed>\n";
	}
}

#
# Stream sections (Video)
#

LOGINF "Adding Video Stream section(s)";
@ffserverdefaults = "";
if (-e "$lbpconfigdir/ffserver_streamdefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_streamdefaults.conf";
	open(F1,"<$lbpconfigdir/ffserver_streamdefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_streamdefaults.conf. Skipping";
	$error = 0;
	} else {
		@ffserverdefaults = <F1>;
	}
	close (F1);
}

for (my $i=1;$i<=10;$i++) {
	if ($pcfg->param("CAM$i.ACTIVE")) {
		LOGINF "Adding Video Stream for Cam $i";
		print F "<Stream cam$i.mjpg>\n";
		print F "Feed cam$i.ffm\n";
		LOGINF "VideoBitRate " . $pcfg->param("CAM$i.VIDEOBITRATE");
		print F "VideoBitRate " . $pcfg->param("CAM$i.VIDEOBITRATE") . "\n";
		LOGINF "VideoFrameRate " . $pcfg->param("CAM$i.VIDEOFRAMERATE");
		print F "VideoFrameRate " . $pcfg->param("CAM$i.VIDEOFRAMERATE") . "\n";
		LOGINF "VideoSize " . $pcfg->param("CAM$i.VIDEOSIZE");
		print F "VideoSize " . $pcfg->param("CAM$i.VIDEOSIZE") . "\n";
		LOGINF "VideoGopSize " . $pcfg->param("CAM$i.VIDEOGOPSIZE");
		print F "VideoGopSize " . $pcfg->param("CAM$i.VIDEOGOPSIZE") . "\n";
		LOGINF "VideoQMin " . $pcfg->param("CAM$i.VIDEOQMIN");
		print F "VideoQMin " . $pcfg->param("CAM$i.VIDEOQMIN") . "\n";
		LOGINF "VideoQMax " . $pcfg->param("CAM$i.VIDEOQMAX");
		print F "VideoQMax " . $pcfg->param("CAM$i.VIDEOQMAX") . "\n";
		LOGINF "Metadata title \"Cam$i\"";
		print F "Metadata title \"Cam$i\"\n";
		foreach (split(/,/,$pcfg->param("CAM$i.EXTRAS_STREAM"))){
			if ($_) {
				LOGINF $_;
		                print F $_ . "\n";
			}
		}
		if (@ffserverdefaults) {
			foreach (@ffserverdefaults){
				if ($_) {
					s/[\n\r]//g;
					LOGINF "$_";
					print F "$_\n";
				}
			}
		}
		print F "</Stream>\n";
	} else {
		LOGINF "Cam $i not active. Skipping.";
	}
	
}

#
# Stream sections (Image)
#

LOGINF "Adding Image Stream section(s)";
@ffserverdefaults = "";
if (-e "$lbpconfigdir/ffserver_imagedefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_imagedefaults.conf";
	open(F1,"<$lbpconfigdir/ffserver_imagedefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_imagedefaults.conf. Skipping";
	$error = 0;
	} else {
		@ffserverdefaults = <F1>;
	}
	close (F1);
}

for (my $i=1;$i<=10;$i++) {
	if ($pcfg->param("CAM$i.ACTIVE") && $pcfg->param("CAM$i.IMAGE")) {
		LOGINF "Adding still Image for Cam $i";
		print F "<Stream cam$i.jpg>\n";
		print F "Feed cam$i.ffm\n";
		LOGINF "VideoSize " . $pcfg->param("CAM$i.IMAGESIZE");
		print F "VideoSize " . $pcfg->param("CAM$i.IMAGESIZE") . "\n";
		LOGINF "Metadata title \"Cam$i\"";
		print F "Metadata title \"Cam$i\"\n";
		foreach (split(/,/,$pcfg->param("CAM$i.EXTRAS_IMAGE"))){
			if ($_) {
				LOGINF $_;
		                print F $_ . "\n";
			}
		}
		if (@ffserverdefaults) {
			foreach (@ffserverdefaults){
				if ($_) {
					s/[\n\r]//g;
					LOGINF "$_";
					print F "$_\n";
				}
			}
		}
		print F "</Stream>\n";
	} else {
		LOGINF "Cam $i not active or image not active. Skipping.";
	}
	
}

#
# Status section
#

LOGINF "Adding Status section";
print F "<Stream status.html>\n";
LOGINF "Format status";
print F "Format status\n";

if (-e "$lbpconfigdir/ffserver_statusdefaults.conf") {
	LOGINF "Found additional default options in $lbpconfigdir/ffserver_statusdefaults.conf";

	open(F1,"<$lbpconfigdir/ffserver_statusdefaults.conf") or $error = 1;
	if ($error) {
		LOGWARN "Cannot read $lbpconfigdir/ffserver_statusdefaults.conf. Skipping";
		$error = 0;
	} else {
		@ffserverdefaults = <F1>;
		foreach (@ffserverdefaults){
			s/[\n\r]//g;
			LOGINF "$_";
			print F "$_\n";
		}
	}
	close (F1);
}
print F "</Stream>\n";

# Exit
close (F);
LOGEND "Exit.";
exit;
