#!/bin/bash

PLUGINNAME=camstream4lox
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

ENVIRONMENT=$(cat /etc/environment)
export $ENVIRONMENT

# Logfile
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=${PLUGINNAME}
NAME=ffserver
FILENAME=${LBPLOG}/${PLUGINNAME}/ffserver.log
APPEND=1

LOGSTART "${PLUGINNAME} Starting FFServer"

# Check if we should start FFServer at boottime
# Source the iniparser
. $LBHOMEDIR/libs/bashlib/iniparser.sh
iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "FFSERVER"

PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

case "$1" in
  start)
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
	LOGEND "";
	echo "Starting FFServer with Config ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf"
	# Clean
	killall ffserver > /dev/null 2>&1
	killall ffmpeg > /dev/null 2>&1
	rm $PATH/cam*.ffm > /dev/null 2>&1
	# Start as loxberry
	if [ $UID -eq 0 ]; then
		su loxberry -c "FFREPORT=file=${LBPLOG}/${PLUGINNAME}/ffserver.log:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf > ${LBPLOG}/${PLUGINNAME}/ffserver.log 2>&1 &"
	else
		FFREPORT=file=${LBPLOG}/${PLUGINNAME}/ffserver.log:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf > ${LBPLOG}/${PLUGINNAME}/ffserver.log 2>&1 &
	fi
        exit 0
        ;;
  stop)
	LOGEND "";
	echo "Stopping FFServer"
	# Clean
	killall ffserver > /dev/null 2>&1
	killall ffmpeg > /dev/null 2>&1
	rm $PATH/cam*.ffm > /dev/null 2>&1
        exit 0
        ;;
  *)
	LOGEND "";
        echo "Usage: $0 [start|stop]" >&2
        exit 3
  ;;

esac
