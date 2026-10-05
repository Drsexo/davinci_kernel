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
echo " Build Script 2.0 - by Riaru Moda"
echo " https://t.me/trrflex"
echo " "

# Validate input arguments
echo "- Validating input arguments..."
if [ $# -lt 2 ] || [ $# -gt 7 ]; then
    echo ""
    echo "-- Usage: $0 [device] [kernelsu_options] [bbg_options] [nomount_options] [droidspaces_options] [rekernel_options] [nethunter_options]"
    echo "-- Feature selectors default to the device JSON; optional arguments override them."
    echo "-- Example: $0 sweet zako-susfs"
    echo "-- Override example: $0 sweet zako-susfs bbg nomount droidspaces rekernel"
    echo ""
    exit 1
fi

# Export arguments so sourced scripts can access them
echo "- Exporting input arguments..."
export DEVICE_IMPORT="$1"
export KERNELSU_SELECTOR="$2"
if [ $# -ge 3 ]; then export BBG_SELECTOR="$3"; fi
if [ $# -ge 4 ]; then export NOMOUNT_SELECTOR="$4"; fi
if [ $# -ge 5 ]; then export DROIDSPACES_SELECTOR="$5"; fi
if [ $# -ge 6 ]; then export REKERNEL_SELECTOR="$6"; fi
if [ $# -ge 7 ]; then export NETHUNTER_SELECTOR="$7"; fi

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
    echo "==============================================="
    ls -alhZ out/arch/arm64/boot/
    echo "==============================================="
    ls -alhZ drivers/
    echo "==============================================="
fi
