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
my $url = $R::url;

# Create Image and print
if ( $url ) {
	my $output = qx ( ffprobe -hide_banner $url 2>&1 );
	print "Content-Type: text/plain\n\n";
	print $output;
	exit;
} else {
	print "Content-Type: text/plain\n\n";
	print "No stream url specified.";
}
exit;
