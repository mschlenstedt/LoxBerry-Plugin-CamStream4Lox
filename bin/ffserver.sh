#!/bin/bash

PLUGINNAME=REPLACELBPPLUGINDIR

PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

ENVIRONMENT=$(cat /etc/environment)
export $ENVIRONMENT

# Logfile
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=${PLUGINNAME}
NAME=ffserver
FILENAME=${LBPLOG}/${PLUGINNAME}/ffserver.log
APPEND=1
ADDTIME=1

LOGSTART "${PLUGINNAME} Starting FFServer"

case "$1" in
  start)
	if [ $LOGLEVEL -eq 0 ]; then
		FFSERVERLOGLEVEL=0
	elif [ $LOGLEVEL -eq 1 ]; then
		FFSERVERLOGLEVEL=8
	elif [ $LOGLEVEL -eq 2 ]; then
		FFSERVERLOGLEVEL=8
	elif [ $LOGLEVEL -eq 3 ]; then
		FFSERVERLOGLEVEL=16
	elif [ $LOGLEVEL -eq 4 ]; then
		FFSERVERLOGLEVEL=24
	elif [ $LOGLEVEL -eq 5 ]; then
		FFSERVERLOGLEVEL=32
	elif [ $LOGLEVEL -eq 6 ]; then
		FFSERVERLOGLEVEL=40
	elif [ $LOGLEVEL -eq 7 ]; then
		FFSERVERLOGLEVEL=48
	fi
	# Start FFServer
	LOGEND "";
	echo "Starting FFServer with Config ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf"
	killall ffserver > /dev/null 2>&1
	FFREPORT=file=${FILENAME}:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}/ffserver.conf > /dev/null 2>&1  &
        exit 0
        ;;
  stop)
	LOGEND "";
	echo "Stopping FFServer"
	killall ffserver > /dev/null 2>&1
        exit 0
        ;;
  *)
	LOGEND "";
        echo "Usage: $0 [start|stop]" >&2
        exit 3
  ;;

esac
