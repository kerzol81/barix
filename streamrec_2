#!/bin/bash
# BARIX streaming and recording

if [ ! -e $(uci get application.audio.ffserver_config) ];then
cat > $(uci get application.audio.ffserver_config) <<EOF

HTTPPort $(uci get application.audio.streaming_port)
HTTPBindAddress 0.0.0.0
MaxHTTPConnections $(uci get application.audio.max_http_conns)
MaxClients $(uci get application.audio.max_clients)
MaxBandwidth $(uci get application.audio.max_bandwidth)
CustomLog $(uci get application.audio.ffserver_log)

<Feed audio.ffm>
        File /tmp/audio.ffm
        FileMaxSize 32M
</Feed>

<Stream audio>
	Feed audio.ffm
        Format wav
        AudioCodec pcm_s16le
        AudioBitRate 256
        AudioChannels 2
        AudioSampleRate $(uci get application.audio.streaming_sample)
        NoVideo
        StartSendOnKey
</Stream>

<Stream stat.html>
        Format status
</Stream>
EOF
fi
#
ffserver -f $(uci get application.audio.ffserver_config) &
#
sleep 1

mkdir -p $(uci get application.audio.recording_path) || exit 1

mkdir -p $(uci get application.audio.recording_path)/$(date '+%Y-%m-%d') || exit 1

ffmpeg -f alsa -i hw:0,0 -acodec pcm_s16le -f segment -strftime 1 -segment_time $(uci get application.audio.duration) -segment_format wav -ar $(uci get application.audio.recording_sample) $(uci get application.audio.recording_path)/$(date '+%Y-%m-%d')/%Y-%m-%d__%H_%M_$(uci get application.audio.recording_sample)_$(sed 's/://g' /sys/class/net/eth0/address).wav -shortest http://localhost:$(uci get application.audio.streaming_port)/audio.ffm
