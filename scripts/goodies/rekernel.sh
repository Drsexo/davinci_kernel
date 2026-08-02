#!/bin/bash

# Default exports
export REKERNEL_PATCH="scripts/goodies/assets/Patches/Rekernel/rekernel_patches.sh"
export REKERNEL_EXTRA="scripts/goodies/assets/Patches/Rekernel/rekernel_extra.patch"

case "$REKERNEL_SELECTOR" in
    rekernel)
        # Start of rekernel integration
        echo "-- Setting up rekernel..."

        # Download rekernel patch and extra patch
        bash "$REKERNEL_PATCH" || { echo "-- Fatal: Failed to apply rekernel patch!"; exit 1; }
        patch -s -p1 --fuzz=5 < "$REKERNEL_EXTRA" || { echo "-- Fatal: Failed to apply rekernel extra patch!"; exit 1; }

        # Enable the necessary Rekernel configs
        echo "CONFIG_REKERNEL=y" >> $MAIN_DEFCONFIG
        ;;
    none|"")
        echo "-- Rekernel is not selected."
        ;;
    *)
        echo "- Invalid REKERNEL_SELECTOR: $REKERNEL_SELECTOR. Valid options: rekernel, none."
        exit 1
        ;;
esac