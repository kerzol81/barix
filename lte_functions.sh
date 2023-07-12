#!/bin/sh

sim_card_state=$(qmicli --device=/dev/cdc-wdm0 --device-open-proxy --uim-get-card-status | grep 'Card state' | awk '{ print $3}' | sed "s/'//g")

