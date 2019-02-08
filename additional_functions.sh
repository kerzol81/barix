#!/bin/bash
set -x
config_file='/etc/audio.conf'

function print_streaming_url
{
  if [ ! -e $config_file ];then
	  echo "no config file"
	
else
	port=$(grep 'HTTPPort' $config_file | awk '{ print $2 }')
	url_end=$(grep '<Feed' /etc/audio.conf | awk '{ print $2 }' | awk -F '.ffm' '{ print $1 }')
	ip='10.0.0.10' --> implemented function on device
	echo "http://$ip:$port/$url_end"
fi
}
