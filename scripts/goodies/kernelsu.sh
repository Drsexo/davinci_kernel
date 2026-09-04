#!/bin/bash

case "$KERNELSU_SELECTOR" in
    zako)
        # Import hook script
        ksu_import_hook_script

        # Run KernelSU setup script
        ksu_run_setup

        # Enable the necessary KernelSU configs
        ksu_common_configs

        # Apply KSU Hooks
        ksu_apply_hooks

        # Export SELinux Symbols
        ksu_export_selinux_symbols
        ;;
    zako-susfs)
        # Import hook script
        ksu_import_hook_script

        # Run KernelSU setup script
        ksu_run_setup

        # Enable the necessary KernelSU configs
        ksu_common_configs

        # Setup SUSFS
        ksu_setup_susfs
        
        # Duct tape fixes for SUSFS
        ksu_fix_susfs_fouronefour
        ksu_fix_susfs_fouronenine

        # Apply KSU Hooks
        ksu_apply_hooks

        # Export SELinux Symbols
        ksu_export_selinux_symbols
        ;;
    none|"")
        echo "-- KernelSU is not selected."
        ;;
    *)
        echo "- Invalid KERNELSU_SELECTOR: $KERNELSU_SELECTOR. Valid options: zako, zako-susfs, none."
        exit 1
        ;;
esac