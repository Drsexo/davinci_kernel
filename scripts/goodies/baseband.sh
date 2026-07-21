#!/bin/bash

# Defaults exports
export BBG_SETUP_URI="https://github.com/vc-teahouse/Baseband-guard/raw/main/setup.sh"

echo "-- Setting up Baseband Guard..."
curl -LSs --fail --retry 3 "$BBG_SETUP_URI" | bash &> /dev/null || { echo "Fatal: BBG setup failed!"; exit 1; }
echo "CONFIG_BBG=y" >> "$MAIN_DEFCONFIG"

# Check and configure LSM Hooks
if grep -q "#define DEFINE_LSM(lsm)" "include/linux/lsm_hooks.h" 2>/dev/null; then
    if grep -q "^CONFIG_LSM=" "$MAIN_DEFCONFIG"; then
        sed -i 's/^\(CONFIG_LSM=".*\)"/\1,baseband_guard"/' "$MAIN_DEFCONFIG"
        echo "-- Appended baseband_guard to existing CONFIG_LSM."
    else
        echo 'CONFIG_LSM="lockdown,yama,loadpin,safesetid,integrity,selinux,smack,tomoyo,apparmor,bpf,baseband_guard"' >> "$MAIN_DEFCONFIG"
        echo "-- Added default CONFIG_LSM with baseband_guard."
    fi
fi

# Check and remove duplicate task_security_struct
if grep -q "struct[[:space:]]\+task_security_struct[[:space:]]\+\*selinux_cred" "security/selinux/include/objsec.h" 2>/dev/null; then
    echo "-- Removing duplicate task_security_struct definition..."
    sed -i '/static inline struct task_security_struct \*selinux_cred/,/[[:space:]]*}/d' security/baseband-guard/tracing/tracing.c
fi