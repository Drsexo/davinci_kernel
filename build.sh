#!/bin/bash

# Banner
echo " "
echo "==============================================="
echo "  ____            __   _   _                   "
echo " |  _ \ ___ _ __ / _| | \ | | ___  ___  _ __   "
echo " | |_) / _ \ '__| |_  |  \| |/ _ \/ _ \| '_ \  "
echo " |  __/  __/ |  |  _| | |\  |  __/ (_) | | | | "
echo " |_|   \___|_|  |_|   |_| \_|\___|\___/|_| |_| "
echo "==============================================="
echo " Build Script 1.6 - by Riaru Moda"
echo " https://t.me/trrflex"
echo " "

# Validate input arguments
echo "- Validating input arguments..."
if [ $# -ne 6 ]; then
    echo ""
    echo "-- Usage: $0 [device] [kernelsu_options] [bbg_options] [nomount_options] [droidspaces_options] [rekernel_options]"
    echo "-- Example: $0 sweet zako bbg nomount droidspaces rekernel"
    echo ""
    exit 1
fi

# Export arguments so sourced scripts can access them
echo "- Exporting input arguments..."
export DEVICE_IMPORT="$1"
export KERNELSU_SELECTOR="$2"
export BBG_SELECTOR="$3"
export NOMOUNT_SELECTOR="$4"
export DROIDSPACES_SELECTOR="$5"
export REKERNEL_SELECTOR="$6"

# Setup Environment
chmod +x scripts/env.sh
source scripts/env.sh

# Setup patches
chmod +x scripts/patches.sh
source scripts/patches.sh

# Setup goodies
chmod +x scripts/goodies.sh
source scripts/goodies.sh

# Build process
chmod +x scripts/compile.sh
source scripts/compile.sh

# Finalize
if [ -d "out/arch/arm64/boot" ]; then
    echo "- Build process finished, listed below are the build artifacts:"
    echo "==============================================="
    ls -alhZ out/arch/arm64/boot/
    echo "==============================================="
else
    echo "- Build process either failed during pre-compile or during compile."
fi
