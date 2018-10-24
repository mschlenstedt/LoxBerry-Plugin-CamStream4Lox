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

#
# Actions to perform
# 
my $do;

# Form 1: FFServer
if ( $cgi->param('do') && ( $cgi->param('form') eq "1" || !$cgi->param('form') ) ) { 
	$do = $cgi->param('do'); 
	if ( $do eq "start") {
		system ("$lbpbindir/ffserver.sh start > /dev/null 2>&1");
		#sleep (3); # Give ffmpeg time to come up...
		for (my $i;$i<=10;$i++) {
			qx{pidof ffserver};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		for (my $i;$i<=10;$i++) {
			qx{pidof ffmpeg};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("rm $lbplogdir/manualstopped");
	}
	if ( $do eq "stop") {
		system ("touch $lbplogdir/manualstopped");
		system ("$lbpbindir/ffserver.sh stop > /dev/null 2>&1");
		#sleep (3); # Give ffmpeg time to go down...
		for (my $i;$i<=10;$i++) {
			qx{pidof ffserver};
			if ($? ne "0") {
				last;
			} else {
				sleep (1);
			}
		}
		for (my $i;$i<=10;$i++) {
			qx{pidof ffmpeg};
			if ($? ne "0") {
				last;
			} else {
				sleep (1);
			}
		}
	}
	if ( $do eq "restart") {
		system ("touch $lbplogdir/manualstopped");
		system ("$lbpbindir/ffserver.sh stop > /dev/null 2>&1");
		for (my $i;$i<=10;$i++) {
			qx{pidof ffserver};
			if ($? ne "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("$lbpbindir/ffserver.sh start > /dev/null 2>&1");
		#sleep (3); # Give ffmpeg time to go down...
		for (my $i;$i<=10;$i++) {
			qx{pidof ffserver};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		for (my $i;$i<=10;$i++) {
			qx{pidof ffmpeg};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("rm $lbplogdir/manualstopped");
	}
}

# Form2: VLC
if ( $cgi->param('do') && ( $cgi->param('form') eq "2" ) ) { 
	$do = $cgi->param('do'); 
	if ( $do eq "start") {
		system ("$lbpbindir/vlc.sh start > /dev/null 2>&1");
		for (my $i;$i<=10;$i++) {
			qx{pidof vlc};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("rm $lbplogdir/vlcmanualstopped");
	}
	if ( $do eq "stop") {
		system ("touch $lbplogdir/vlcmanualstopped");
		system ("$lbpbindir/vlc.sh stop > /dev/null 2>&1");
		for (my $i;$i<=10;$i++) {
			qx{pidof vlc};
			if ($? ne "0") {
				last;
			} else {
				sleep (1);
			}
		}
	}
	if ( $do eq "restart") {
		system ("touch $lbplogdir/manualstoppedvlc");
		system ("$lbpbindir/vlc.sh stop > /dev/null 2>&1");
		for (my $i;$i<=10;$i++) {
			qx{pidof vlc};
			if ($? ne "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("$lbpbindir/vlc.sh start > /dev/null 2>&1");
		for (my $i;$i<=10;$i++) {
			qx{pidof vlc};
			if ($? eq "0") {
				last;
			} else {
				sleep (1);
			}
		}
		system ("rm $lbplogdir/manualstoppedvlc");
	}
}

#
# Save forms
#

# Form1: FFServer
if ($R::saveformdata1) {
	
	# Write configuration file(s)
	if ( $R::startffserver ) {
		$cfg->param("FFSERVER.START", "1");
	} else {
		$cfg->param("FFSERVER.START", "0");
	}
	if ( $R::cronffserver ) {
		$cfg->param("FFSERVER.CRON", "1");
	} else {
		$cfg->param("FFSERVER.CRON", "0");
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
			$cfg->param("CAM$i.VIDEOQMIN", ${"R::cam$i" . "videoqmin"});
		} else {
			$cfg->param("CAM$i.VIDEOQMIN", "5");
		}
		if ( ${"R::cam$i" . "videoqmax"} ) {
			$cfg->param("CAM$i.VIDEOQMAX", ${"R::cam$i" . "videoqmax"});
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
	system ("$lbpbindir/buildmultiview.pl > /dev/null 2>&1");
	
	# Template output
	$maintemplate->param( "FORM", 1);
	&save;
	exit;

}

# Form2: VLC
if ($R::saveformdata2) {
	
	# Write configuration file(s)
	if ( $R::cronvlc ) {
		$cfg->param("VLC.CRON", "1");
	} else {
		$cfg->param("VLC.CRON", "0");
	}
	if ( $R::httpport ) {
		$cfg->param("VLC.HTTPPORT", "$R::httpport");
	} else {
		$cfg->param("VLC.HTTPPORT", "4000");
	}
	for (my $i=1;$i<=10;$i++) {
		if ( ${"R::cam$i" . "active"} ) {
			$cfg->param("CAM$i.VLCACTIVE", "1");
		} else {
			$cfg->param("CAM$i.VLCACTIVE", "0");
		}
		if ( ${"R::cam$i" . "url"} ) {
			$cfg->param("CAM$i.VLCURL", ${"R::cam$i" . "url"});
		} else {
			$cfg->param("CAM$i.VLCURL", "");
		}
	}
	
	# Save all
	$cfg->save();

	system ("$lbpbindir/buildconfig.pl > /dev/null 2>&1");
	
	# Template output
	$maintemplate->param( "FORM", 2);
	&save;
	exit;

}

#
# Navbar
#
our %navbar;
$navbar{1}{Name} = "$L{'SETTINGS.LABEL_FFSERVER'}";
$navbar{1}{URL} = 'index.cgi?form=1';

$navbar{2}{Name} = "$L{'SETTINGS.LABEL_VLC'}";
$navbar{2}{URL} = 'index.cgi?form=2';

$navbar{3}{Name} = "$L{'SETTINGS.LABEL_MULTIVIEW'}";
$navbar{3}{URL} = '/plugins/$lbpplugindir/index.html';
$navbar{3}{target} = '_blank';

$navbar{99}{Name} = "$L{'SETTINGS.LABEL_LOGFILES'}";
$navbar{99}{URL} = LoxBerry::Web::loglist_url();
$navbar{99}{target} = '_blank';

#
# Menu forms
#

# Menu: FFServer
if ($R::form eq "1" || !$R::form) {

	$navbar{1}{active} = 1;
	$maintemplate->param( "FORM1", 1);

	# Process PIDs
	my $pidofffserver=`pidof ffserver`;
	my $inst; 
	$inst++ while $pidofffserver =~ /\S+/g;
	if (!$inst) {
		$inst = "$L{'SETTINGS.MESSAGE_NOTRUNNING'}";
	} else {
		$inst = $inst . " $L{'SETTINGS.MESSAGE_INSTANCES'}";
	}
	$maintemplate->param( STATEFFSERVER => $inst);
	chomp($pidofffserver);
	if (!$pidofffserver) {
		$pidofffserver = "-";
	}
	$maintemplate->param( PIDOFFFSERVER => $pidofffserver);

	my $pidofffmpeg=`pidof ffmpeg`;
	my $inst; 
	$inst++ while $pidofffmpeg =~ /\S+/g;
	if (!$inst) {
		$inst = "$L{'SETTINGS.MESSAGE_NOTRUNNING'}";
	} else {
		$inst = $inst . " $L{'SETTINGS.MESSAGE_INSTANCES'}";
	}
	$maintemplate->param( STATEFFMPEG => $inst);
	chomp($pidofffmpeg);
	if (!$pidofffmpeg) {
		$pidofffmpeg = "-";
	}
	$maintemplate->param( PIDOFFFMPEG => $pidofffmpeg);

	# Status page
	my $statusurl = "http://" . $ENV{SERVER_ADDR} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/status.html";
	$maintemplate->param( STATUSURL => $statusurl);

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
	
	# Cron FFserver
	my @values = ('0', '1' );
	my %labels = (
		'0' => $L{'SETTINGS.LABEL_OFF'},
		'1' => $L{'SETTINGS.LABEL_ON'},
	);
	my $form = $cgi->popup_menu(
		-name => 'cronffserver',
		-id => 'cronffserver',
		-values	=> \@values,
		-labels	=> \%labels,
		-default => $cfg->param('FFSERVER.CRON'),
	);
	$maintemplate->param( CRONFFSERVER => $form );

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

}

# Menu: VLC
if ($R::form eq "2") {

	$navbar{2}{active} = 1;
	$maintemplate->param( "FORM2", 1);

	# Process PIDs
	my $pidofvlc=`pidof vlc`;
	my $inst; 
	$inst++ while $pidofvlc =~ /\S+/g;
	if (!$inst) {
		$inst = "$L{'SETTINGS.MESSAGE_NOTRUNNING'}";
	} else {
		$inst = $inst . " $L{'SETTINGS.MESSAGE_INSTANCES'}";
	}
	$maintemplate->param( STATEVLC => $inst);
	chomp($pidofvlc);
	if (!$pidofvlc) {
		$pidofvlc = "-";
	}
	$maintemplate->param( PIDOFVLC => $pidofvlc);

	# Form
	# Cron VLC
	my @values = ('0', '1' );
	my %labels = (
		'0' => $L{'SETTINGS.LABEL_OFF'},
		'1' => $L{'SETTINGS.LABEL_ON'},
	);
	my $form = $cgi->popup_menu(
		-name => 'cronvlc',
		-id => 'cronvlc',
		-values	=> \@values,
		-labels	=> \%labels,
		-default => $cfg->param('VLC.CRON'),
	);
	$maintemplate->param( CRONVLC => $form );

	# Cams active, URLs
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
			-default => $cfg->param( "CAM$i" . ".VLCACTIVE"),
		);
		if ( $cfg->param( "CAM$i" . ".VLCACTIVE") ) {
				$maintemplate->param( "CAM$i" . "COLLAPSED" => "data-collapsed='false'" );
		}
		$maintemplate->param( "CAM$i" . "ACTIVE" => $form );
		my $httpport = $cfg->param("VLC.HTTPPORT")+$i-1;
		my $videourl = "http://" . $ENV{SERVER_ADDR} . ":$httpport/cam" . $i . ".mjpg";
		$maintemplate->param( "CAM$i" . "VIDEOURL" => $videourl );
	}

}

#
# Print Template
#
LoxBerry::Web::lbheader($L{'SETTINGS.LABEL_PLUGINTITLE'} . " V$version", "https://www.loxwiki.eu/display/LOXBERRY/CamStream4Lox", "");
print $maintemplate->output;
LoxBerry::Web::lbfooter();

exit;

#
# Sub Save
#

sub save
{
	$maintemplate->param( "SAVE", 1);
	LoxBerry::Web::lbheader($L{'SETTINGS.LABEL_PLUGINTITLE'} . " V$version", "https://www.loxwiki.eu/display/LOXBERRY/CamStream4Lox", "");
	print $maintemplate->output();
	LoxBerry::Web::lbfooter();

	exit;
}
