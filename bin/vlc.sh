#!/bin/bash

PLUGINNAME=REPLACELBPPLUGINDIR
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

ENVIRONMENT=$(cat /etc/environment)
export $ENVIRONMENT

# Logfile
. $LBHOMEDIR/libs/bashlib/loxberry_log.sh
PACKAGE=${PLUGINNAME}
NAME=vlc
LOGDIR=$LBPLOG/${PLUGINNAME}
STDERR=1

LOGSTART

# Debug output for VLC
if [ ${LOGLEVEL} -eq "7" ]; then
	DEBUG="vvv"
fi

# Check if we should start FFServer at boottime
# Source the iniparser
. $LBHOMEDIR/libs/bashlib/iniparser.sh
iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "VLC"

# Oups, not a very clever name for the temppath in our config, when using bash...
TMPPATH=$PATH
PATH="/sbin:/bin:/usr/sbin:/usr/bin:$LBHOMEDIR/bin:$LBHOMEDIR/sbin"

case "$1" in
  start)

	if [ "$(pidof vlc)" ]; then
		LOGERR "VLC already running."
		LOGEND
		exit 1
	fi

	# VLC
	LOGINF "Starting VLC..."

	COUNTER=1
	LOGSCOUNT=1

	while [  $COUNTER -lt 11 ]; do

		iniparser $LBPCONFIG/$PLUGINNAME/camstream4lox.cfg "CAM$COUNTER"
		CAMACTIVE="CAM$COUNTER""VLCACTIVE"
		TRANSCODE="CAM$COUNTER""VLCTRANSCODE"
		CAMURL="CAM$COUNTER""VLCURL"
         	let HTTPPORT=${VLCHTTPPORT}+$COUNTER-1
		if [ ${!CAMACTIVE} -eq "1" ]; then
			ACTIVELOG=1
			LOGINF "Cam $COUNTER is active. Starting VLC instance..."

			# Logfile for output from vlc
         		let LOGSCOUNT=LOGSCOUNT+1 
			PACKAGE=${PLUGINNAME}
			NAME=vlc${COUNTER}_run
			LOGDIR=$LBPLOG/${PLUGINNAME}

			LOGSTART
			ACTIVELOG=${LOGSCOUNT}
			LOGINF "This is the log from VLC instance CAM$COUNTER"

			if [ ${VLCUSERNAME} ] && [ ${VLCPASSWORD} ]; then
				LOGINF "MJPEG Streams will be protected with Username/Password..."
				MJPEGAUTH="user=${VLCUSERNAME},pwd=${VLCPASSWORD},"
				MJPEGAUTHLOG="user=<USERNAME>,pwd=<PASSWORD>,"
			else
				MJPEGAUTH=""
				MJPEGAUTHLOG=""
			fi


			if [[ ${!TRANSCODE} -eq "1" ]]; then
				LOGINF "Stream will be transcoded."
				VB="CAM$COUNTER""VIDEOBITRATE"
				FPS="CAM$COUNTER""VIDEOFRAMERATE"
				EXTRASFEED=",""CAM$COUNTER""EXTRAS_FEED"
				WIDTH="CAM$COUNTER""VIDEOWIDTH"
				if [ ! ${!WIDTH} ]; then
					WIDTH=""
				else
					WIDTH=",width=${!WIDTH}"
				fi
				HEIGHT="CAM$COUNTER""VIDEOHEIGHT"
				if [ ! ${!HEIGHT} ]; then
					HEIGHT=""
				else
					HEIGHT=",height=${!HEIGHT}"
				fi
				TRANSCODEOPTIONS="transcode{threads=2,acodec=none,vcodec=MJPG,vb=${!VB},scale=1${WIDTH}${HEIGHT},fps=${!FPS}}:"
				LOGINF "Transcode Options are: ${TRANSCODEOPTIONS}"
			fi
			if [ $UID -eq 0 ]; then
				chown -R loxberry:loxberry $LOGDIR/*
				LOGINF "CMD: su loxberry -c \"cvlc -I dummy -v${DEBUG} -R ${!CAMURL} --sout='#${TRANSCODEOPTIONS}std{access=http{${MJPEGAUTHLOG}mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=:${HTTPPORT}/cam${COUNTER}.mjpg}' --sout-keep >> ${FILENAME} 2>&1 &\""
				su loxberry -c "cvlc -I dummy -v${DEBUG} -R ${!CAMURL} --sout='#${TRANSCODEOPTIONS}std{access=http{${MJPEGAUTH}mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=:${HTTPPORT}/cam${COUNTER}.mjpg}' --sout-keep >> ${FILENAME} 2>&1 &"
			else
				LOGINF "cvlc -I dummy -v${DEBUG} -R ${!CAMURL} --sout='#${TRANSCODEOPTIONS}std{access=http{${MJPEGAUTHLOG}mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=:${HTTPPORT}/cam${COUNTER}.mjpg}' --sout-keep >> ${FILENAME} 2>&1 &"
				cvlc -I dummy -v${DEBUG} -R ${!CAMURL} --sout="#${TRANSCODEOPTIONS}std{access=http{${MJPEGAUTH}mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=:${HTTPPORT}/cam${COUNTER}.mjpg}" --sout-keep >> ${FILENAME} 2>&1 &
			fi
		fi
         	let COUNTER=COUNTER+1 
	done

	ACTIVELOG=1
	sleep 2s
	if [ "$(pgrep -f /usr/bin/vlc)" ]; then
		LOGOK "VLC started successfully."
	else
		LOGERR "VLC could not be started."
	fi

	LOGEND
	chown -R loxberry:loxberry $LOGDIR/*
        exit 0
        ;;

  stop)

	# Clean VLC
	LOGINF "Stopping any running VLC processes..."
	killall vlc >> ${FILENAME} 2>&1
	COUNTER=0
	while [  $COUNTER -lt 10 ]; do
		if [ "$(pgrep -f /usr/bin/vlc)" ]; then
			sleep 1s
			if [ $COUNTER -lt 5 ]; then
				pkill -f /usr/bin/vlc >> ${FILENAME} 2>&1
			else
				pkill -9 -f /usr/bin/vlc >> ${FILENAME} 2>&1
			fi
         		let COUNTER=COUNTER+1 
		else
         		let COUNTER=10
		fi
	done

	if [ "$(pgrep -f /usr/bin/vlc)" ]; then
		LOGERR "VLC could not be stopped."
	else
		LOGOK "VLC stopped successfully."
	fi

	LOGEND
	chown -R loxberry:loxberry $LOGDIR/*
        exit 0
        ;;

  *)
        echo "Usage: $0 [start|stop]" >&2
        exit 3
  ;;

esac
