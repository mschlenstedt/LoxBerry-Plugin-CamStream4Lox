#!/usr/bin/perl

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


##########################################################################
# Modules
##########################################################################

use Config::Simple '-strict';
use LoxBerry::System;
use LoxBerry::Storage;
use LoxBerry::Web;
use CGI;
#use warnings;
#use strict;

##########################################################################
# Variables
##########################################################################

##########################################################################
# Read Settings
##########################################################################

# Version of this script
my $version = LoxBerry::System::pluginversion();

my $cfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

##########################################################################
# Main program
##########################################################################

# Get CGI
our $cgi = CGI->new;
$cgi->import_names('R');

my $maintemplate = HTML::Template->new(
                filename => "$lbptemplatedir/settings.html",
                global_vars => 1,
                loop_context_vars => 1,
                die_on_bad_params=> 0,
                associate => $cfg,
                debug => 0,
                );

my %L = LoxBerry::System::readlanguage($maintemplate, "language.ini");

# Actions to perform
my $do;
if ( $cgi->param('do') ) { 
	$do = $cgi->param('do'); 
	if ( $do eq "start") {
		system ("rm $lbplogdir/manualstoppped");
		system ("$lbpbindir/ffserver.sh start > /dev/null 2>&1");
		sleep (3); # Give ffmpeg time to come up...
	}
	if ( $do eq "stop") {
		system ("$lbpbindir/ffserver.sh stop > /dev/null 2>&1");
		system ("touch $lbplogdir/manualstoppped");
		sleep (3); # Give ffmpeg time to go down...
	}
	if ( $do eq "restart") {
		system ("$lbpbindir/ffserver.sh stop > /dev/null 2>&1");
		system ("$lbpbindir/ffserver.sh start > /dev/null 2>&1");
		sleep (3); # Give ffmpeg time to go down...
	}
}

# Save Form
if ($R::saveformdata) {
	
	# Write configuration file(s)
	if ( $R::startffserver ) {
		$cfg->param("FFSERVER.START", "1");
	} else {
		$cfg->param("FFSERVER.START", "0");
	}
	if ( $R::httpport ) {
		$cfg->param("FFSERVER.HTTPPORT", "$R::httpport");
	} else {
		$cfg->param("FFSERVER.HTTPPORT", "8090");
	}
	if ( $R::path ) {
		$cfg->param("FFSERVER.PATH", "$R::path");
	} else {
		$cfg->param("FFSERVER.PATH", "$lbpdatadir/tmp");
	}
	if ( $R::buffersize ) {
		$cfg->param("FFSERVER.BUFFERSIZE", "$R::buffersize");
	} else {
		$cfg->param("FFSERVER.BUFFERSIZE", "200");
	}

	for (my $i=1;$i<=10;$i++) {
		if ( ${"R::cam$i" . "active"} ) {
			$cfg->param("CAM$i.ACTIVE", "1");
		} else {
			$cfg->param("CAM$i.ACTIVE", "0");
		}
		if ( ${"R::cam$i" . "url"} ) {
			$cfg->param("CAM$i.URL", ${"R::cam$i" . "url"});
		} else {
			$cfg->param("CAM$i.URL", "");
		}
		if ( ${"R::cam$i" . "videobitrate"} ) {
			$cfg->param("CAM$i.VIDEOBITRATE", ${"R::cam$i" . "videobitrate"});
		} else {
			$cfg->param("CAM$i.VIDEOBITRATE", "4048");
		}
		if ( ${"R::cam$i" . "videoframerate"} ) {
			$cfg->param("CAM$i.VIDEOFRAMERATE", ${"R::cam$i" . "videoframerate"});
		} else {
			$cfg->param("CAM$i.VIDEOFRAMERATE", "10");
		}
		if ( ${"R::cam$i" . "videosize"} ) {
			$cfg->param("CAM$i.VIDEOSIZE", ${"R::cam$i" . "videosize"});
		} else {
			$cfg->param("CAM$i.VIDEOSIZE", "640x480");
		}
		if ( ${"R::cam$i" . "videogopsize"} ) {
			$cfg->param("CAM$i.VIDEOGOPSIZE", ${"R::cam$i" . "videogopsize"});
		} else {
			$cfg->param("CAM$i.VIDEOGOPSIZE", "5");
		}
		if ( ${"R::cam$i" . "videoqmin"} ) {
			$cfg->param("CAM$i.VIDEOYMIN", ${"R::cam$i" . "videoqmin"});
		} else {
			$cfg->param("CAM$i.VIDEOQMIN", "5");
		}
		if ( ${"R::cam$i" . "videoqmax"} ) {
			$cfg->param("CAM$i.VIDEOYMAX", ${"R::cam$i" . "videoqmax"});
		} else {
			$cfg->param("CAM$i.VIDEOQMAX", "51");
		}
		if ( ${"R::cam$i" . "extrasfeed"} ) {
			$cfg->param("CAM$i.EXTRAS_FEED", ${"R::cam$i" . "extrasfeed"});
		} else {
			$cfg->param("CAM$i.EXTRAS_FEED", "");
		}
		if ( ${"R::cam$i" . "extrasstream"} ) {
			$cfg->param("CAM$i.EXTRAS_STREAM", ${"R::cam$i" . "extrasstream"});
		} else {
			$cfg->param("CAM$i.EXTRAS_STREAM", "");
		}
		if ( ${"R::cam$i" . "picactive"} ) {
			$cfg->param("CAM$i.PICACTIVE", "1");
		} else {
			$cfg->param("CAM$i.PICACTIVE", "0");
		}
		if ( ${"R::cam$i" . "imagesize"} ) {
			$cfg->param("CAM$i.IMAGESIZE", ${"R::cam$i" . "imagesize"});
		} else {
			$cfg->param("CAM$i.IMAGESIZE", "640x480");
		}
		if ( ${"R::cam$i" . "extrasimage"} ) {
			$cfg->param("CAM$i.EXTRAS_IMAGE", ${"R::cam$i" . "extrasimage"});
		} else {
			$cfg->param("CAM$i.EXTRAS_IMAGE", "");
		}
	}
	
	# Save all
	$cfg->save();

	system ("$lbpbindir/buildconfig.pl > /dev/null 2>&1");
	
	# Template output
	&save;

	exit;

}


# Standard form
$maintemplate->param( FORM => 1 );

# Process PIDs
my $pidofffserver=`pidof ffserver`;
if (!$pidofffserver) {
	$pidofffserver = "$L{'SETTINGS.MESSAGE_NOTRUNNING'}";
}
$maintemplate->param( PIDOFFFSERVER => $pidofffserver);

my $pidofffmpeg=`pidof ffmpeg`;
if (!$pidofffmpeg) {
	$pidofffmpeg = $L{'SETTINGS.MESSAGE_NOTRUNNING'};
}
$maintemplate->param( PIDOFFFMPEG => $pidofffmpeg);

# Status page
my $statusurl = "http://" . $ENV{SERVER_ADDR} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/status.html";
$maintemplate->param( STATUSURL => $statusurl);

# Logfiles
$maintemplate->param( LOGFILEBUTTON => LoxBerry::Web::loglist_button_html() );

# Form
# Start FFserver
my @values = ('0', '1' );
my %labels = (
	'0' => $L{'SETTINGS.LABEL_OFF'},
	'1' => $L{'SETTINGS.LABEL_ON'},
);
my $form = $cgi->popup_menu(
	-name => 'startffserver',
	-id => 'startffserver',
	-values	=> \@values,
	-labels	=> \%labels,
	-default => $cfg->param('FFSERVER.START'),
);
$maintemplate->param( STARTFFSERVER => $form );

# Path
$form = LoxBerry::Storage::get_storage_html(
	formid => 'path',
	custom_folder => 1,
	currentpath => $cfg->param("FFSERVER.PATH"),
	readwriteonly => 1,
	data_mini => 1);
$maintemplate->param( PATH => $form );

# Cams active, Image active, URLs
for (my $i=1;$i<=10;$i++) {
	@values = ('0', '1' );
	%labels = (
		'0' => $L{'SETTINGS.LABEL_OFF'},
		'1' => $L{'SETTINGS.LABEL_ON'},
	);
	$form = $cgi->popup_menu(
		-name => "cam" . $i . "active",
		-id => "cam" . $i . "active",
		-values	=> \@values,
		-labels	=> \%labels,
		-default => $cfg->param( "CAM$i" . ".ACTIVE"),
	);
	if ( $cfg->param( "CAM$i" . ".ACTIVE") ) {
			$maintemplate->param( "CAM$i" . "COLLAPSED" => "data-collapsed='false'" );
	}
	$maintemplate->param( "CAM$i" . "ACTIVE" => $form );
	$form = $cgi->popup_menu(
		-name => "cam" . $i . "picactive",
		-id => "cam" . $i . "picactive",
		-values	=> \@values,
		-labels	=> \%labels,
		-default => $cfg->param( "CAM$i" . ".PICACTIVE"),
	);
	$maintemplate->param( "CAM$i" . "PICACTIVE" => $form );
	my $videourl = "http://" . $ENV{SERVER_ADDR} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/cam" . $i . ".mjpg";
	my $pictureurl = "http://" . $ENV{SERVER_ADDR} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/cam" . $i . ".jpg";
	$maintemplate->param( "CAM$i" . "VIDEOURL" => $videourl );
	$maintemplate->param( "CAM$i" . "PICTUREURL" => $pictureurl );
}

# Print Template
LoxBerry::Web::lbheader($L{'SETTINGS.LABEL_PLUGINTITLE'} . " V$version", "https://www.loxwiki.eu/display/LOXBERRY/CamStream4Lox", "");
print $maintemplate->output;
LoxBerry::Web::lbfooter();

exit;

#####################################################
# Sub Save
#####################################################

sub save
{
	$maintemplate->param( "SAVE", 1);
	LoxBerry::Web::lbheader($L{'SETTINGS.LABEL_PLUGINTITLE'} . " V$version", "https://www.loxwiki.eu/display/LOXBERRY/CamStream4Lox", "");
	print $maintemplate->output();
	LoxBerry::Web::lbfooter();

	exit;
}
