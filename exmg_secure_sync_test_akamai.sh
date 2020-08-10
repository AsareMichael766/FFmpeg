#!/bin/bash

# Bash setup (exit on error)
set -e

export stream_id=664379
export segment_size_in_seconds=1
export window_size_in_segments=20
export window_extra_segments=31536000
export frame_rate_num=30000
export frame_rate_den=1000
export input_width=640
export input_height=480
export video_bitrate="800k"
export audio_bitrate="128k"
export output_resolution="640x480"
export input="Spring.mp4"
export event_name="stephan"

sub_folder="$(date +%s)"

export output="https://p-ep$stream_id.i.akamaientrypoint.net/cmaf/$stream_id/$event_name"

#Stream can be watched with this MPD:
#https://exmachina-ull-demo.akamaized.net/cmaf/live/664379/stephan/out.mpd

export mpd_url="https://exmachina-ull-demo.akamaized.net/cmaf/live/$stream_id/$event_name/out.mpd"

export key_output="tmp"

rm -Rf $key_output
mkdir -p $key_output

export FF_EXMG_SECURE_SYNC_ON=""
#export FF_EXMG_SECURE_SYNC_DRY_RUN=""
#export FF_EXMG_SECURE_SYNC_NO_ENCRYPTION=""

export FF_EXMG_SECURE_SYNC_KEY_PUBLISH_DELAY="0" # seconds (float)
export FF_EXMG_SECURE_SYNC_KEY_INDEX_MAX_WINDOW="-1" # nb of key-scopes held in file-written index (int) (negative -> unlimited)
export FF_EXMG_SECURE_SYNC_FRAGMENTS_PER_KEY="30" # amount of fragments per key-scope (int)
export FF_EXMG_SECURE_SYNC_MQTT_PUB=1 # anything set will enable MQTT key-pub
export FF_EXMG_SECURE_SYNC_FS_PUB_BASEPATH=$output/ # ending slash is mandatory (or empty string "") / unset to disable fs key-pub 

echo "Publishing to: $output and sub-directory: $sub_folder"
echo "MPD available at: $mpd_url"
echo ""
echo "Key-pub fs-path: $key_output"
echo ""

export log_level="info" # quiet / error / debug / verbose

./ffmpeg \
       -loglevel repeat+level+$log_level \
       -re -stream_loop -1 -i $input \
       -flags +global_header \
       -r $frame_rate_num/$frame_rate_den \
       -af aresample=async=1 \
       -c:v libx264 \
       -preset medium \
       -vf "settb=AVTB,\
              setpts='trunc(PTS/1K)*1K+st(1,trunc(RTCTIME/1K))-1K*trunc(ld(1)/1K)', \
              drawtext=rate=30:text='%{localtime}.%{eif\:1M*t-1K*trunc(t*1K)\:d}:' \
              x=300:y=300:fontfile=./Linebeam.ttf:fontsize=48:fontcolor='white':boxcolor=0x00AAAAAA:box=1" \
       -b:v $video_bitrate \
       -s $output_resolution \
       -pix_fmt yuv420p \
       -sc_threshold 0 \
       -force_key_frames "expr:gte(t,n_forced*"$segment_size_in_seconds")" \
       -bf 0 \
       -x264opts scenecut=-1:rc_lookahead=0 \
       -c:a aac \
       -b:a $audio_bitrate \
       -seg_duration $segment_size_in_seconds \
       -use_timeline 0 \
       -http_user_agent Akamai_Broadcaster_v1.0 \
       -streaming 1 \
       -index_correction 1 \
       -http_persistent 1 \
       -ignore_io_errors 1\
       -media_seg_name  $sub_folder'/segment_$RepresentationID$-$Number%05d$.m4s' \
       -init_seg_name  $sub_folder'/init_$RepresentationID$.m4s' \
       -hls_playlist 1 \
       -window_size $window_size_in_segments \
       -extra_window_size $window_extra_segments \
       $output/out.mpd

