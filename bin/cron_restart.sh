#!/bin/bash

PLUGINNAME=REPLACELBPPLUGINDIR
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

ENVIRONMENT=$(cat /etc/environment)
export $ENVIRONMENT

# Source iniparser
. $LBHOMEDIR/libs/bashlib/iniparser.sh
iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "VLC"
iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "FFSERVER"

# Logfile
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=${PLUGINNAME}
NAME=cron
LOGDIR=$LBPLOG/${PLUGINNAME}
STDERR=1

LOGSTART

# PATH
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

if [ $FFSERVERCRON -eq "1" ] && [ $FFSERVERSTART -eq "1" ]; then
	LOGINF "Restart FFSErver..."
	COUNTER=0
	while [  $COUNTER -lt 10 ]; do
		if [ "$(pidof watchdog.pl)" ]; then
			sleep 1s
         		let COUNTER=COUNTER+1 
		else
         		let COUNTER=10
		fi
	done
	$LBHOMEDIR/bin/plugins/$PLUGINNAME/ffserver.sh stop
	sleep 2s
	$LBHOMEDIR/bin/plugins/$PLUGINNAME/ffserver.sh start
fi

COUNTER=1
VLCSTART=0
while [  $COUNTER -lt 11 ]; do
	iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "CAM$COUNTER"
	CAMACTIVE="CAM$COUNTER""VLCACTIVE"
	if [ ${!CAMACTIVE} -eq "1" ]; then
		VLCSTART=1
	fi
        let COUNTER=COUNTER+1 
done

if [ $VLCCRON -eq "1" ] && [ $VLCSTART -eq "1" ]; then
	LOGINF "Restart VLC..."
	COUNTER=0
	while [  $COUNTER -lt 10 ]; do
		if [ "$(pidof watchdog.pl)" ]; then
			sleep 1s
         		let COUNTER=COUNTER+1 
		else
         		let COUNTER=10
		fi
	done
	$LBHOMEDIR/bin/plugins/$PLUGINNAME/vlc.sh stop
	sleep 2s
	$LBHOMEDIR/bin/plugins/$PLUGINNAME/vlc.sh start
fi

LOGEND
