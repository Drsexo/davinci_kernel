#!/bin/bash

case "$BBG_SELECTOR" in
    bbg)
        # Start of baseband guard integration
        echo "-- Baseband Guard: Setting up Baseband Guard..."
        bbg_setup

        # Check and configure LSM Hooks
        echo "-- Baseband Guard: Configuring LSM Hooks..."
        bbg_lsmhooks
        
        # Check and remove duplicate task_security_struct
        echo "-- Baseband Guard: Checking task_security_struct definition..."
        bbg_remove_duplicate
        ;;
    none|"")
        echo "-- Baseband Guard is not selected."
        ;;
    *)
        echo "- Invalid BBG_SELECTOR: $BBG_SELECTOR. Valid options: bbg, none."
        exit 1
        ;;
esac
