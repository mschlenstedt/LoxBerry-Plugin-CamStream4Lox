#!/bin/bash

PLUGINNAME=REPLACELBPPLUGINDIR
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

ENVIRONMENT=$(cat /etc/environment)
export $ENVIRONMENT

# Logfile
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=${PLUGINNAME}
NAME=ffserver
LOGDIR=$LBPLOG/${PLUGINNAME}
STDERR=1

LOGSTART

# Check if we should start FFServer at boottime
# Source the iniparser
#. $LBHOMEDIR/libs/bashlib/iniparser.sh
#iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "FFSERVER"

# Oups, not a very clever name for the temppath in our config, when using bash...
TMPPATH=$PATH
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

case "$1" in
  start)

	if [ "$(pidof ffserver)" ]; then
		LOGERR "FFServer already running."
		LOGEND
		exit 1
	fi

	if [ "$(pidof ffmpeg)" ]; then
		LOGERR "FFmpeg already running."
		LOGEND
		exit 1
	fi

	if [ $LOGLEVEL -eq 0 ]; then
		FFSERVERLOGLEVEL=0
	elif [ $LOGLEVEL -eq 1 ]; then
		FFSERVERLOGLEVEL=8
	elif [ $LOGLEVEL -eq 2 ]; then
		FFSERVERLOGLEVEL=8
	elif [ $LOGLEVEL -eq 3 ]; then
		FFSERVERLOGLEVEL=8
	elif [ $LOGLEVEL -eq 4 ]; then
		FFSERVERLOGLEVEL=16
	elif [ $LOGLEVEL -eq 5 ]; then
		FFSERVERLOGLEVEL=24
	elif [ $LOGLEVEL -eq 6 ]; then
		FFSERVERLOGLEVEL=32
	elif [ $LOGLEVEL -eq 7 ]; then
		FFSERVERLOGLEVEL=32
	fi

	# Start FFServer
	LOGINF "Starting FFServer with Config ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf"

	# Logfile for output from FFServer
	PACKAGE=${PLUGINNAME}
	NAME=ffserver_run
	#LOGDIR=$LBPLOG/${PLUGINNAME}
	FILENAME=${LBPLOG}/${PLUGINNAME}/ffserver_run.log

	LOGSTART
	ACTIVELOG=2

	if [ $UID -eq 0 ]; then
		su loxberry -c "FFREPORT=file=${FILENAME}:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}/ffserverrun.conf >> ${FILENAME} 2>&1 &"
	else
		FFREPORT=file=${FILENAME}:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf >> ${FILENAME} 2>&1 &
	fi

	LOGEND

	ACTIVELOG=1
	if [ "$(pidof ffserver)" ]; then
		LOGOK "FFServer startet successfully."
	else
		LOGERR "FFServer could not be started."
	fi

	LOGEND

        exit 0
        ;;

  stop)

	# Clean FFServer
	LOGINF "Stopping any running FFServer processes..."
	killall ffserver >> ${FILENAME} 2>&1
	COUNTER=0
	while [  $COUNTER -lt 10 ]; do
		if [ "$(pidof ffserver)" ]; then
			sleep 1s
			if [ $COUNTER -lt 5 ]; then
				killall ffserver >> ${FILENAME} 2>&1
			else
				killall -9 ffserver >> ${FILENAME} 2>&1
			fi
         		let COUNTER=COUNTER+1 
		else
         		let COUNTER=10
		fi
	done

	# Clean FFMpeg
	LOGINF "Stopping any running FFMPEG processes..."
	killall ffmpeg >> ${FILENAME} 2>&1
	COUNTER=0
	while [  $COUNTER -lt 10 ]; do
		if [ "$(pidof ffmpeg)" ]; then
			sleep 1s
			if [ $COUNTER -lt 5 ]; then
				killall ffmpeg >> ${FILENAME} 2>&1
			else
				killall -9 ffmpeg >> ${FILENAME} 2>&1
			fi
         		let COUNTER=COUNTER+1 
		else
         		let COUNTER=10
		fi
	done

	# Clean Temp-Files
	LOGINF "Cleaning temporary files in $TMPPATH..."
	rm -f $TMPPATH/cam*.ffm >> ${FILENAME} 2>&1

	if [ "$(pidof ffserver)" ]; then
		LOGERR "FFServer could not be stopped."
	else
		LOGOK "FFServer stopped successfully."
	fi

	LOGEND
        exit 0
        ;;

  *)
        echo "Usage: $0 [start|stop]" >&2
        exit 3
  ;;

esac
