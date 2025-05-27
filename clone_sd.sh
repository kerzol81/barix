#!/bin/bash

IMAGE_NAME="unicorn.img"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Detecting removable devices..."

SD_DEV_INFO=$(lsblk -b -d -o NAME,RM,SIZE,MODEL | awk '$2 == 1 && $3 > 1000000000 {print $1, $3, $4}' | head -n 1)

if [ -z "$SD_DEV_INFO" ]; then
  echo -e "${RED}No suitable removable SD card device found.${NC}"
  exit 1
fi

# Parse the info
SD_NAME=$(echo "$SD_DEV_INFO" | awk '{print $1}')
SD_SIZE_BYTES=$(echo "$SD_DEV_INFO" | awk '{print $2}')
SD_MODEL=$(echo "$SD_DEV_INFO" | cut -d' ' -f3-)

SD_DEV="/dev/$SD_NAME"
SD_SIZE_GB=$(awk -v size=$SD_SIZE_BYTES 'BEGIN {printf "%.1f GB", size / (1024*1024*1024)}')

echo -e "${GREEN}Detected SD card: $SD_DEV ($SD_SIZE_GB, $SD_MODEL)${NC}"

read -p "This will clone $SD_DEV to $IMAGE_NAME. Are you sure? (yes/no): " confirm
if [[ ! "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${RED}Aborted.${NC}"
  exit 1
fi

if command -v pv &> /dev/null; then
  sudo dd if="$SD_DEV" bs=4M | pv | sudo dd of="$IMAGE_NAME" bs=4M status=none
else
  sudo dd if="$SD_DEV" of="$IMAGE_NAME" bs=4M status=progress
fi

sync
echo -e "${GREEN}SD card successfully cloned to $IMAGE_NAME.${NC}"
