#!/bin/bash

IMAGE_NAME="unicorn.img"
GREEN='\033[0;32m'  # Bootstrap green
RED='\033[0;31m'    # Bootstrap red
NC='\033[0m'        # Reset color

echo "Detecting removable devices..."

# Find removable device with size > 1GB (in bytes)
SD_DEV_INFO=$(lsblk -b -d -o NAME,RM,SIZE,MODEL | awk '$2 == 1 && $3 > 1000000000 {print $1, $3, $4}' | head -n 1)

if [ -z "$SD_DEV_INFO" ]; then
  echo -e "${RED}No suitable removable SD card found.${NC}"
  exit 1
fi

# Parse info
SD_NAME=$(echo "$SD_DEV_INFO" | awk '{print $1}')
SD_SIZE_BYTES=$(echo "$SD_DEV_INFO" | awk '{print $2}')
SD_MODEL=$(echo "$SD_DEV_INFO" | cut -d' ' -f3-)
SD_DEV="/dev/$SD_NAME"
SD_SIZE_GB=$(awk -v size=$SD_SIZE_BYTES 'BEGIN {printf "%.1f GB", size / (1024*1024*1024)}')

echo -e "${GREEN}Detected SD card: $SD_DEV ($SD_SIZE_GB, $SD_MODEL)${NC}"

read -p "This will write ${IMAGE_NAME} to ${SD_DEV}. Are you sure? (yes/no): " confirm
if [[ ! "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${RED}Aborted.${NC}"
  exit 1
fi

# Write image
if command -v pv &> /dev/null; then
  pv "$IMAGE_NAME" | sudo dd of="$SD_DEV" bs=4M status=none
else
  sudo dd if="$IMAGE_NAME" of="$SD_DEV" bs=4M status=progress
fi

sync
echo -e "${GREEN}Image successfully written to ${SD_DEV}.${NC}"
