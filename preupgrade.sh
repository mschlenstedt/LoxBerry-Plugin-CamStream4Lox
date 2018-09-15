#!/bin/bash

ARGV0=$0 # Zero argument is shell command
ARGV1=$1 # First argument is temp folder during install
ARGV2=$2 # Second argument is Plugin-Name for scipts etc.
ARGV3=$3 # Third argument is Plugin installation folder
ARGV4=$4 # Forth argument is Plugin version
ARGV5=$5 # Fifth argument is Base folder of LoxBerry

echo "<INFO> Creating temporary folders for upgrading"
mkdir -p /tmp/$ARGV1\_upgrade
mkdir -p /tmp/$ARGV1\_upgrade/config
mkdir -p /tmp/$ARGV1\_upgrade/log
#mkdir -p /tmp/$ARGV1\_upgrade/files

echo "<INFO> Backing up existing config files"
cp -p -v -r $ARGV5/config/plugins/$ARGV3/ /tmp/$ARGV1\_upgrade/config

# If we upgrade to 0.2.0, do not back up ffserver_feeddefaults.conf
if [[ $ARGV4 -eq "0.2.0" ]]; then
	echo "<INFO> ffserver_feeddefaults.conf has to be replaced. Do not back it up."
	rm /tmp/$ARGV1\_upgrade/config/ffserver_feeddefaults.conf
fi

echo "<INFO> Backing up existing log files"
cp -p -v -r $ARGV5/log/plugins/$ARGV3/ /tmp/$ARGV1\_upgrade/log

# Exit with Status 0
exit 0
