#!/bin/bash

case "$NETHUNTER_SELECTOR" in
    nethunter)
        echo "-- Setting up NetHunter..."
        case "$KERNEL_VERSION" in
            4.14)
                nethunter_fouronefour_configs
                nethunter_fouronefour_patches
                ;;
            4.19)
                nethunter_fouronenine_patches
                ;;
            *)
                echo "- NetHunter is not supported for kernel version $KERNEL_VERSION."
                exit 1
                ;;
        esac
        ;;
    none|"")
        echo "-- NetHunter is not selected."
        ;;
    *)
        echo "- Invalid NETHUNTER_SELECTOR: $NETHUNTER_SELECTOR. Valid options: nethunter, none."
        exit 1
        ;;
esac
