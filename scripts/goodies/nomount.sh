#!/bin/bash

# Default exports
export NOMOUNT_PATCH="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/patches/nomount_${KERNEL_VERSION}_kernel_integration.patch"
export NOMOUNT_CODE="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/src/nomount.c"
export NOMOUNT_HEADER="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/src/nomount.h"

echo "-- Setting up nomount..."

# Download nomount patch, code, and header
wget -qO- $NOMOUNT_PATCH | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply nomount patch!"; exit 1; }
wget -qO- $NOMOUNT_CODE > "${PWD}/fs/nomount.c" || { echo "-- Fatal: Failed to download nomount.c!"; exit 1; }
wget -qO- $NOMOUNT_HEADER > "${PWD}/fs/nomount.h" || { echo "-- Fatal: Failed to download nomount.h!"; exit 1; }

# Enable the necessary Nomount configs
echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG