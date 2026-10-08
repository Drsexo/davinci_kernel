#!/bin/bash

# Export nomount variables
export NOMOUNT_SETUP_VER="2.1.0"
export NOMOUNT_SETUP_ZIP="https://github.com/maxsteeel/nomount/archive/refs/tags/v$NOMOUNT_SETUP_VER.zip"
export NOMOUNT_SETUP_URI_BLEEDING_EDGE="https://raw.githubusercontent.com/maxsteeel/nomount/refs/heads/master/kernel/setup.sh"
export NOMOUNT_SETUP_BRANCH_BLEEDING_EDGE="dev"

# Download nomount
nomount_download() {
    echo "-- NoMount: Downloading source code..."
    wget $NOMOUNT_SETUP_ZIP -O v$NOMOUNT_SETUP_VER.zip &> /dev/null || { echo "Fatal: NoMount source code failed to download!"; exit 1; }
    if [ -f "$PWD/v$NOMOUNT_SETUP_VER.zip" ]; then
        echo "-- NoMount: Unzipping source code..."
        unzip $PWD/v$NOMOUNT_SETUP_VER.zip -d $PWD/ &> /dev/null
    else
        echo "-- NoMount: Cant find zipped source code!"
        ls -alhZ $PWD/
        exit 1
    fi
}

# Setup nomount
nomount_setup() {
    if [ -d "$PWD/nomount-$NOMOUNT_SETUP_VER" ]; then
        echo "-- NoMount: Setting up Kconfig and Makefile..."
        sed -i '/^endmenu/i source "fs/nomount/Kconfig"' fs/Kconfig
        echo 'obj-$(CONFIG_NOMOUNT) += nomount/' >> fs/Makefile
        echo "-- NoMount: Copying source code to fs/nomount..."
        mkdir -p $PWD/fs/nomount
        cp -r $PWD/nomount-$NOMOUNT_SETUP_VER/kernel/src/* $PWD/fs/nomount
        echo "-- NoMount: Enabling nomount config..."
        echo "CONFIG_NOMOUNT=y" >> "$FINAL_DEFCONFIG"
    else
        echo "-- NoMount: Can't find unzipped source code!"
        ls -alhZ $PWD/
        exit 1
    fi
}

# Setup nomount bleeding edge
nomount_setup_bleeding_edge() {
    echo "-- NoMount: Bleeding Edge! Running setup script..."
    curl -LSs --fail --retry 3 "$NOMOUNT_SETUP_URI_BLEEDING_EDGE" | bash -s "$NOMOUNT_SETUP_BRANCH_BLEEDING_EDGE" &> /dev/null || { echo "-- Fatal: NoMount setup script failed to download/run!"; exit 1; }
    echo "CONFIG_NOMOUNT=y" >> "$FINAL_DEFCONFIG"
}