#!/bin/bash

FOLDER=$(uci get application.audio.recording_path)
MAC_ADDRESS=$(sed 's/://g' /sys/class/net/eth0/address)

while true; do
	mkdir -p "$FOLDER"
	RATE=$(uci get application.audio.recording_sample)
	DURATION=$(uci get application.audio.duration)	
	DAY=$(date +%Y-%m-%d)
	mkdir -p "$FOLDER/$DAY"
	FILENAME=$(date +%Y-%m-%d__%H_%M_%S_"$RATE"_"$MAC_ADDRESS")
	arecord -f cd -r "$RATE" -d "$DURATION" "$FOLDER"/"$DAY"/"$FILENAME".wav
done

#END
