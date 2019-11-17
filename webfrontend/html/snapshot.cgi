#!/usr/bin/perl

# Copyright 2019 Michael Schlenstedt, michael@loxberry.de
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
#use LoxBerry::Storage;
#use LoxBerry::Web;
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
#my $version = LoxBerry::System::pluginversion();

my $cfg = new Config::Simple("$lbpconfigdir/camstream4lox.cfg");

##########################################################################
# Main program
##########################################################################

# Get CGI
our $cgi = CGI->new;
$cgi->import_names('R');
my $cam = $R::cam;

# Create Image and print
if ( $cam && $cfg->param("CAM$cam.VLCACTIVE") ) {
	my $camurl = $cfg->param("CAM$cam.VLCURL");
	my $width = $cfg->param("CAM$cam.IMAGEWIDTH");
	if ($R::width) {$width = $R::width;};
	if (!$width) {$width="-1";};
	my $height = $cfg->param("CAM$cam.IMAGEHEIGHT");
	if ($R::height) {$height = $R::height;};
	if (!$height) {$height="-1";};
	system ("yes | ffmpeg -loglevel fatal -i $camurl -f image2 -vframes 1 -pix_fmt yuvj420p -vframes 1 -r 1 -vf scale=$width:$height /tmp/camstream4lox_snapshot$cam.jpg > /dev/null 2>&1");
	if ( -e "/tmp/camstream4lox_snapshot$cam.jpg") {
		open IMAGE, "/tmp/camstream4lox_snapshot$cam.jpg";
		my ($image, $buff);
		while(read IMAGE, $buff, 1024) {
			$image .= $buff;
		}
		close IMAGE;
		print "Content-type: image/jpeg\n\n";
		print $image;
		unlink ("/tmp/camstream4lox_snapshot$cam.jpg");
		exit;
	} else {
		print "Content-Type: text/plain\n\n";
		print "Could not create snapshot of stream.";
		exit;
	}
} else {
	print "Content-Type: text/plain\n\n";
	print "No cam specified or cam not active.";
}
exit;
