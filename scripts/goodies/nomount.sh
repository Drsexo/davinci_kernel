#!/bin/bash

# Default exports
export NOMOUNT_SETUP_URI="https://github.com/maxsteeel/nomount/raw/refs/heads/dev/kernel/setup.sh"
export NOMOUNT_SETUP_BRANCH="dev"

case "$NOMOUNT_SELECTOR" in
    nomount)
        # Setup nomount
        echo "-- Running nomount setup script..."
        curl -LSs --fail --retry 3 "$NOMOUNT_SETUP_URI" | bash -s "$NOMOUNT_SETUP_BRANCH" &> /dev/null || { echo "Fatal: Nomount setup script failed to download/run!"; exit 1; }

        # Enable the necessary Nomount configs
        echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG

        # Allow nomount to compile on C89 environment
        echo "ccflags-y += -Wno-declaration-after-statement" >> fs/nomount/Makefile
        ;;
    none|"")
        echo "-- Nomount is not selected."
        ;;
    *)
        echo "- Invalid NOMOUNT_SELECTOR: $NOMOUNT_SELECTOR. Valid options: nomount, none."
        exit 1
        ;;
esac