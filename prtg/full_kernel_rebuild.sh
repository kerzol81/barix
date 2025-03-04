#!/bin/bash
# 03.03.2025 KZ - Yocto Kernel Rebuild Script
#set -x
set -e

YOCTO_DIR='/home/kerenyiz/oe-core'

source "$YOCTO_DIR/export" || exit 1

read -rp "Do you want to rebuild the kernel? (y/N): " CONFIRM_KERNEL
if [[ "$CONFIRM_KERNEL" =~ ^[Yy]$ ]]; then
    echo '[+] Rebuilding kernel...'

    bitbake -c cleanall virtual/kernel
    bitbake -c configure virtual/kernel
    bitbake -c compile virtual/kernel
    bitbake -c deploy virtual/kernel

    echo "[✓] Kernel rebuild complete."
else
    echo "[-] Kernel rebuild skipped."
fi


read -rp "Do you want to build core-image-barix-sdk? (y/N): " CONFIRM_IMAGE
if [[ "$CONFIRM_IMAGE" =~ ^[Yy]$ ]]; then
    echo '[+] Building core-image-barix-sdk...'
    bitbake core-image-barix-sdk
    echo "[✓] Image build complete."
else
    echo "[-] Image build skipped."
fi

exit 0
