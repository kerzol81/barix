#!/bin/sh

sim_card_state=$(qmicli --device=/dev/cdc-wdm0 --device-open-proxy --uim-get-card-status | grep 'Card state' | awk '{ print $3}' | sed "s/'//g")

qmicli -d /dev/cdc-wdm0 --device-open-proxy --nas-get-signal-info

connection_status=$(qmicli --wds-get-packet-service-status -d /dev/cdc-wdm0 | grep 'Connection status' | awk '{print $4}' | sed "s/'//g")

imsi=$(qmicli --dms-uim-get-imsi -d /dev/cdc-wdm0 | grep 'IMSI:' | awk '{print $2}' | sed "s/'//g")

qmicli -d /dev/cdc-wdm0 --dms-get-band-capabilities
