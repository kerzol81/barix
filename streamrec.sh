#!/bin/bash
# streaming and recording at the same time
set -x

recording_folder="/home/$USER/recordings"
recording_sec=60
recording_sample_rate=44100

streaming_port=4444
streaming_sample_rate=128
ffserver_config="$recording_folder/audio.conf"

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
	Metadata Title "Live"
	Feed audio.ffm
	Format mp2
	Audiocodec libmp3lame
	AudioBitRate ${streaming_sample_rate}
	AudioChannels 2
	AudioSampleRate 16000
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
sleep 2

mkdir -p "$recording_folder"
fifo1="analog_audio"
while true;do
	if [ -e ${fifo1} ];then
		rm ${fifo1}
	fi
	mkfifo ${fifo1} 2>/dev/null
	day=$(date '+%Y-%m-%d')
	mkdir -p "$recording_folder"/"$day" || exit 3
	ffmpeg -f alsa -re -i hw:0,0 -acodec pcm_s16le -shortest http://localhost:"$streaming_port"/audio.ffm -f wav -ar "$recording_sample_rate" pipe:1 > ${fifo1} || exit 4 &
	ffmpeg -i ${fifo1} -ss 0 -t "$recording_sec" -ar "$recording_sample_rate" "$recording_folder"/"$day"/"$(date '+%Y-%m-%d__%H_%M_%S')".wav || exit 5
done

exit 0
