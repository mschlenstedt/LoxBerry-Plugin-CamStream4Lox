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

case "$1" in
  start)
	LOGSTART "${PLUGINNAME} Starting FFServer."
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
	echo Using iLoglevel ${LOGLEVEL}, which is ${FFSERVERLOGLEVEL} for FFServer
	FFREPORT=file=${FILENAME}:level=${FFSERVERLOGLEVEL} ffserver -f ${LBPCONFIG}/${PLUGINNAME}ffserver.conf
        exit 0
        ;;
  stop)
        exit 0
        ;;
  *)
        echo "Usage: $0 [start|stop]" >&2
        exit 3
  ;;

esac
