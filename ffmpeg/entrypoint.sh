#!/bin/sh

# set env vars to defaults if not already set
export FRAME_RATE="${FRAME_RATE:-25}"
export GOP_LENGTH="${GOP_LENGTH:-${FRAME_RATE}}"

if [ "${FRAME_RATE}" = "30000/1001" -o "${FRAME_RATE}" = "60000/1001" ]; then
  echo "drop frame"
  export FRAME_SEP="."
else
  export FRAME_SEP=":"
fi

export LOGO_OVERLAY="${LOGO_OVERLAY-https://raw.githubusercontent.com/unifiedstreaming/live-demo/master/ffmpeg/usp_logo_white.png}"

if [ -n "${LOGO_OVERLAY}" ]; then
  export LOGO_OVERLAY="-i ${LOGO_OVERLAY}"
  export OVERLAY_FILTER=", overlay=eval=init:x=W-15-w:y=15"
fi

# validate required variables are set
if [ -z "${PUB_POINT_URI}" ]; then
  echo >&2 "Error: PUB_POINT_URI environment variable is required but not set."
  exit 1
fi

timecode=$(date +%H\\:%M\\:%S).00
PUB_POINT=${PUB_POINT_URI}

set -x
exec ffmpeg -re -f lavfi -i smptehdbars=size=1280x960:rate=$FRAME_RATE -re \
	-f lavfi -i \
	sine=beep_factor=4:sample_rate=48000:duration=10000000000 \
       	-i  https://raw.githubusercontent.com/unifiedstreaming/live-demo/master/ffmpeg/usp_logo_white.png \
        -filter_complex "\
	[0:v]drawbox=y=25:\
       	x=iw/2-iw/7:\
       	c=0x00000000@1:\
       	w=iw/3.5: h=36:\
       	t=3,drawtext=timecode_rate=${FRAME_RATE}:\
       	timecode='$(date -u +%H\\:%M\\:%S)\\${FRAME_SEP}$(($(date +%3N)/$(($FRAME_RATE))))':\
       	tc24hmax=1: fontsize=32: x=(w-tw)/2+tw/2: y=30:\
       	fontcolor=white, drawtext=text='%{gmtime\:%Y-%m-%d}\ ':\
       	fontsize=32: x=(w-tw)/2-tw/2: y=30:\
       	fontcolor=white,overlay=eval=init:x=W-15-w:y=15" \
       	-map 0:v -s 1280x960 -b:v 1200k -an -g $GOP_LENGTH -r $FRAME_RATE -keyint_min $GOP_LENGTH \
	-c:v libx264 -profile:v main -preset ultrafast -tune zerolatency  -fflags +genpts \
        -movflags +frag_keyframe+empty_moov+separate_moof+default_base_moof \
	-f mp4 "$PUB_POINT/Streams(video2-1280-1000k.cmfv)" \
	-map 1:a -c:a aac -vn -b:a 64k -f mp4 -fflags +genpts -frag_duration 960000 -min_frag_duration 960000 \
        -movflags +empty_moov+separate_moof+default_base_moof  "$PUB_POINT/Streams(audio-aac-64k.cmfa)" 
