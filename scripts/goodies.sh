#!/bin/bash
echo "- Setting up additional goodies..."

# Clone goodies repository
git clone https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd.git scripts/goodies/assets &> /dev/null
# Reset goodies repository to a specific commit
# Latest commit have iissues so we need to revert it back the janky way.
# cd scripts/goodies/assets
# git reset --hard 75f1699a7f0a270ecae7ba696315e3d55d643101 &> /dev/null
# cd ../../../

# KernelSU
chmod +x scripts/goodies/kernelsu.sh
source scripts/goodies/kernelsu.sh

# Baseband Guard
chmod +x scripts/goodies/baseband.sh
source scripts/goodies/baseband.sh

# NoMount
chmod +x scripts/goodies/nomount.sh
source scripts/goodies/nomount.sh

# Droidspaces
chmod +x scripts/goodies/droidspaces.sh
source scripts/goodies/droidspaces.sh

# ReKernel
chmod +x scripts/goodies/rekernel.sh
source scripts/goodies/rekernel.sh