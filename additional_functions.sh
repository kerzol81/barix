#!/bin/bash
set -x

function print_streaming_url(){	
	local config_file='/etc/ffserver.conf'
	if [ ! -e $config_file ];then
		echo "no config file"
	else
		local port=$(grep 'HTTPPort' $config_file | awk '{ print $2 }')
		local url_end=$(grep '<Feed' /etc/audio.conf | awk '{ print $2 }' | awk -F '.ffm' '{ print $1 }')
		local ip=$(print_ip_addr) #already implemented function on device
		echo "http://$ip:$port/$url_end"
	fi
}

function print_streaming_url_href(){	
	echo "$(print_streaming_url) target="_blank">Listen</a>"
}

function print_recording_path(){
	echo "/media/data"
}
