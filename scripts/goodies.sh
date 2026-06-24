#!/bin/bash
echo "- Setting up additional goodies..."

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
