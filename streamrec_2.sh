#!/bin/bash

recording_path=$(uci get application.audio.recording_path)
recording_sample_rate=$(uci get application.audio.recording_sample)
recording_time=$(uci get application.audio.duration)			#seconds

streaming_port=4444
streaming_bit_rate=32			#libmp3lame
streaming_sample_rate=8000

ffserver_config="/etc/ffserver.conf"

if [ ! -e "$ffserver_config" ];then
	cat > "$ffserver_config" <<EOF
HTTPPort ${streaming_port}
HTTPBindAddress 0.0.0.0
MaxHTTPConnections 10
MaxClients 10
MaxBandwidth 2048
CustomLog /var/log/ffserver.log

<Feed audio.ffm>
	File /tmp/audio.ffm
	FileMaxSize 4096M
</Feed>

<Stream audio>
	Metadata title "Barix Live Audio"
	Feed audio.ffm
	Format mp2
	Audiocodec libmp3lame
	AudioBitRate ${streaming_bit_rate}
	AudioChannels 2
	AudioSampleRate ${streaming_sample_rate}
	NoVideo
	StartSendOnKey
</Stream>

<Stream stat.html>
	Format status
</Stream>
EOF
fi

sleep 1
ffserver -f "$ffserver_config" || exit 1 &
sleep 1

day=$(date '+%Y-%m-%d')
mkdir -p "$recording_path"/"$day"
cd "$recording_path"/"$day"
#ffmpeg -f alsa -re -i hw:0,0 -f wav -ar "$recording_sample_rate" -f segment -segment_time "$recording_time" -strftime 1 "%Y-%m-%d_%H-%M-%S.wav" -shortest http://localhost:"$streaming_port"/audio.ffm
ffmpeg -f alsa -re -i hw:0,0 -shortest http://localhost:"$streaming_port"/audio.ffm -f wav -ar "$recording_sample_rate" -f segment -segment_time "$recording_time" -strftime 1 "%Y-%m-%d_%H-%M-%S.wav"

exit 0
