#!/bin/bash

# Default exports
export NOMOUNT_SETUP_VER="2.0.0"
export NOMOUNT_SETUP_ZIP="https://github.com/maxsteeel/nomount/archive/refs/tags/v$NOMOUNT_SETUP_VER.zip"

case "$NOMOUNT_SELECTOR" in
    nomount)
        # Download nomount
        echo "-- Downloading nomount source code version: $NOMOUNT_SETUP_VER..."
        wget $NOMOUNT_SETUP_ZIP || { echo "Fatal: Nomount source code failed to download!"; exit 1; }
        
        # Unzip nomount
        echo "-- Unzipping nomoount source code..."
        if [ -f "$PWD/v$NOMOUNT_SETUP_VER.zip" ]; then
            echo "-- Unzipping nomount source code..."
            unzip $PWD/v$NOMOUNT_SETUP_VER.zip -d $PWD/
        else
            echo "-- Cant find nomount zipped source code!"
            ls -alhZ $PWD/
            exit 1
        fi

        # Setup nomount
        if [ -d "$PWD/nomount-v$NOMOUNT_SETUP_VER" ]; then
            echo "-- Setting up nomount..."
            sed -i '/^endmenu/i source "fs/nomount/Kconfig"' fs/Kconfig
            sed -i '$ a\obj-$(CONFIG_NOMOUNT) += nomount/' fs/Makefile
            mkdir -p $PWD/fs/nomount
            cp -r $PWD/nomount-$NOMOUNT_SETUP_VER/kernel/src/* $PWD/fs/nomount
        else
            echo "-- Can't find unzipped nomount source code!"
            ls -alhZ $PWD/
            exit 1
        fi

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