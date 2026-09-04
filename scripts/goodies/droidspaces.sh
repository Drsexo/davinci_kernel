#!/bin/bash

case "$DROIDSPACES_SELECTOR" in
    droidspaces)
        # Start of droidspaces integration
        echo "-- Setting up Droidspaces..."

        # Patch the kernel
        echo "-- Droidspaces: Applying patches..."
        droidspaces_patches

        # Execute droidspaces quirks on 4.14
        echo "-- Droidspaces: Checking any quirks..."
        droidspaces_quirks

        # Add droidspaces configs to defconfig
        echo "-- Droidspaces: Adding configs to defconfig..."
        droidspaces_configs
        ;;
    none|"")
        echo "-- Droidspaces is not selected."
        ;;
    *)
        echo "- Invalid DROIDSPACES_SELECTOR: $DROIDSPACES_SELECTOR. Valid options: droidspaces, none."
        exit 1
        ;;
esac