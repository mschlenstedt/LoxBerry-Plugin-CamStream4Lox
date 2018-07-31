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

use LoxBerry::System;
use LoxBerry::Web;
use CGI;
#use Config::Simple;
use warnings;
use strict;

##########################################################################
# Variables
##########################################################################

##########################################################################
# Read Settings
##########################################################################

# Version of this script
my $version = "0.0.1";

my $cfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

##########################################################################
# Main program
##########################################################################

# Get CGI
our $cgi = CGI->new;

my $maintemplate = HTML::Template->new(
                filename => "$lbptemplatedir/settings.html",
                global_vars => 1,
                loop_context_vars => 1,
                die_on_bad_params=> 0,
                associate => $cfg,
                debug => 1,
                );

my %L = LoxBerry::System::readlanguage($maintemplate, "language.ini");

# Actions to perform
my $do;
if ( $cgi->param('do') ) { 
	$do = $cgi->param('do'); 
	if ( $do eq "start") {
		system ("sudo $lbpbindir/lms_wrapper.sh start > /dev/null 2>&1");
	}
	if ( $do eq "stop") {
		system ("sudo $lbpbindir/lms_wrapper.sh stop > /dev/null 2>&1");
	}
	if ( $do eq "restart") {
		system ("sudo $lbpbindir/lms_wrapper.sh restart > /dev/null 2>&1");
	}
	if ( $do eq "enable") {
		system ("sudo $lbpbindir/lms_wrapper.sh enable > /dev/null 2>&1");
	}
	if ( $do eq "disable") {
		system ("sudo $lbpbindir/lms_wrapper.sh disable > /dev/null 2>&1");
	}
}

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
my $statusurl = "http://" . $ENV{HTTP_HOST} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/status.html";
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
		-default => $cfg->param( "CAM$i" . ".IMAGE"),
	);
	$maintemplate->param( "CAM$i" . "PICACTIVE" => $form );
	my $videourl = "http://" . $ENV{HTTP_HOST} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/cam" . $i . ".mjpg";
	my $pictureurl = "http://" . $ENV{HTTP_HOST} . ":" . $cfg->param("FFSERVER.HTTPPORT") . "/cam" . $i . ".jpg";
	$maintemplate->param( "CAM$i" . "VIDEOURL" => $videourl );
	$maintemplate->param( "CAM$i" . "PICTUREURL" => $pictureurl );
}

# Print Template
LoxBerry::Web::lbheader("CamStream4Lox", "http://www.loxwiki.eu:80");
print $maintemplate->output;
LoxBerry::Web::lbfooter();

exit;

