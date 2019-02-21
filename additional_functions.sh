# Additional functions

# print device MAC address in colon-separated format, capital letters
function print_mac_addr()
{
        cat /sys/class/net/eth0/address | tr "[a-z]" "[A-Z]"
}

# print device IP  address
# optional parameter $1 defines the interface, default is eth0
function print_ip_addr()
{
        if [ $# -lt 1 ] ; then interface=eth0
        else interface="$1"
        fi

	ifconfig "$interface" | sed -n 's/.*inet addr:\([0-9.]\+\).*/\1/p' | tr -d "\\n"
}

function print_streaming_url(){
        config_file='/etc/ffserver.conf'
        if [ ! -e $config_file ];then
                echo "no config file"
        else
            	port=$(grep 'HTTPPort' $config_file | awk '{ print $2 }')
                end=$(grep '<Feed' ${config_file} | awk '{ print $2 }' | awk -F '.ffm' '{ print $1 }')
                ip=$(print_ip_addr)
                echo "http://${ip}:${port}/${end}"
        fi
}

function print_recording_path(){
        echo "/media/data"
}

function print_board_temperature(){
	local t='/sys/class/thermal/thermal_zone0/temp'
	if [ ! -e $t ];then
		echo "no data from sensor"
	else
		echo -n $(( $(cat $t) / 1000 ))
		echo -n "."
		echo -n $(( $(cat $t) )) | cut -c 3
	fi
}

