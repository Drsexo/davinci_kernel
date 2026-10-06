#!/bin/bash
echo "- Loading functions for goodies..."

# Default exports
export BBG_SETUP_URI="https://github.com/vc-teahouse/Baseband-guard/raw/main/setup.sh"
export DROIDSPACES_XT_QTAGUID="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/01.fix_kernel_panic_in_xt_qtaguid.patch"
export DROIDSPACES_CGROUP="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/02.fix_restore%20cgroup%20file%20prefix%20handling%20.patch"
export SUSFS_PATCH="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"
export KSU_SETUP_URI="https://github.com/ReSukiSU/ReSukiSU/raw/refs/heads/main/kernel/setup.sh"
export KSU_SETUP_BRANCH="main"
export NOMOUNT_SETUP_VER="2.1.0"
export NOMOUNT_SETUP_ZIP="https://github.com/maxsteeel/nomount/archive/refs/tags/v$NOMOUNT_SETUP_VER.zip"
export NOMOUNT_SETUP_URI_BLEEDING_EDGE="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/setup.sh"
export NOMOUNT_SETUP_BRANCH_BLEEDING_EDGE="master"
export REKERNEL_PATCH="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Rekernel/rekernel_patches.sh"
export REKERNEL_EXTRA="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Rekernel/rekernel_extra.patch"

# Baseband Guard
bbg_setup() {
    curl -LSs --fail --retry 3 "$BBG_SETUP_URI" | bash &> /dev/null || { echo "Fatal: BBG setup failed!"; exit 1; }
    echo "CONFIG_BBG=y" >> "$MAIN_DEFCONFIG"
}
bbg_lsmhooks() {
    if grep -q "#define DEFINE_LSM(lsm)" "include/linux/lsm_hooks.h" 2>/dev/null; then
        if grep -q "^CONFIG_LSM=" "$MAIN_DEFCONFIG"; then
            sed -i 's/^\(CONFIG_LSM=".*\)"/\1,baseband_guard"/' "$MAIN_DEFCONFIG"
            echo "-- Appended baseband_guard to existing CONFIG_LSM."
        else
            echo 'CONFIG_LSM="lockdown,yama,loadpin,safesetid,integrity,selinux,smack,tomoyo,apparmor,bpf,baseband_guard"' >> "$MAIN_DEFCONFIG"
            echo "-- Added default CONFIG_LSM with baseband_guard."
        fi
    fi
}
bbg_remove_duplicate() {
    if grep -q "struct[[:space:]]\+task_security_struct[[:space:]]\+\*selinux_cred" "security/selinux/include/objsec.h" 2>/dev/null; then
        echo "-- Removing duplicate task_security_struct definition..."
        sed -i '/static inline struct task_security_struct \*selinux_cred/,/[[:space:]]*}/d' security/baseband-guard/tracing/tracing.c
    fi
}

# Droidspaces
droidspaces_patches() {
    if [[ ! -f "net/netfilter/xt_qtaguid.c" ]]; then
        echo "-- Droidspaces: xt_qtaguid module not found in kernel source."
        XT_QTAGUID_CHECK="false"
    else
        XT_QTAGUID_CHECK="true"
    fi
    if [[ "$XT_QTAGUID_CHECK" == "true" ]]; then
        echo "-- Droidspaces: net/netfilter/xt_qtaguid.c exist, applying patch..."
        wget -qO- $DROIDSPACES_XT_QTAGUID | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces xt_qtaguid patch!"; exit 1; }
    fi
    echo "-- Droidspaces: Applying cgroup patch..."
    wget -qO- $DROIDSPACES_CGROUP | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces cgroup patch!"; exit 1; }
}
droidspaces_quirks() {
    if [[ "$KERNEL_VERSION" == "4.14" ]]; then
        echo "-- Droidspaces: Kernel is 4.14, changing id..."
        sed -i 's/css->cgroup->id/css->cgroup->kn->id/g' include/net/netprio_cgroup.h
        sed -i 's/css->cgroup->id/css->cgroup->kn->id/g' net/core/netprio_cgroup.c
    fi
}
droidspaces_configs() {
        # IPC mechanisms
        echo "CONFIG_SYSCTL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SYSVIPC=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_POSIX_MQUEUE=y" >> $MAIN_DEFCONFIG
        # Core namespace support
        echo "CONFIG_NAMESPACES=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_PID_NS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_UTS_NS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IPC_NS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_USER_NS=y" >> $MAIN_DEFCONFIG
        # Seccomp support
        echo "CONFIG_SECCOMP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECCOMP_FILTER=y" >> $MAIN_DEFCONFIG
        # Control groups support
        echo "CONFIG_CGROUPS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_DEVICE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_SCHED=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_FAIR_GROUP_SCHED=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_FREEZER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_NET_PRIO=y" >> $MAIN_DEFCONFIG
        # Resource limits
        echo "CONFIG_MEMCG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CFS_BANDWIDTH=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_PIDS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CGROUP_CPUACCT=y" >> $MAIN_DEFCONFIG
        # Device filesystem support
        echo "CONFIG_DEVTMPFS=y" >> $MAIN_DEFCONFIG
        # Overlay filesystem support
        echo "CONFIG_OVERLAY_FS=y" >> $MAIN_DEFCONFIG
        # Enable xattr, posix acl support on tmpfs
        echo "CONFIG_TMPFS_POSIX_ACL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_TMPFS_XATTR=y" >> $MAIN_DEFCONFIG
        # Firmware loading support
        echo "CONFIG_FW_LOADER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_FW_LOADER_USER_HELPER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_FW_LOADER_COMPRESS=y" >> $MAIN_DEFCONFIG
        # Droidspaces Network Isolation Support - NAT/none modes
        echo "CONFIG_NET_NS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_VETH=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_BRIDGE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_BRIDGE_NETFILTER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_ADVANCED=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_CONNTRACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_IPTABLES=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_FILTER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_NAT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_TABLES=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_TARGET_MASQUERADE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_MASQUERADE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_TCPMSS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_CONNTRACK_NETLINK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_NAT_REDIRECT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_ADVANCED_ROUTER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_MULTIPLE_TABLES=y" >> $MAIN_DEFCONFIG
        # legacy compat
        echo "CONFIG_NF_CONNTRACK_IPV4=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_NAT_IPV4=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_NAT=y" >> $MAIN_DEFCONFIG
        # IPv6 in NAT mode (NAT66).
        echo "CONFIG_IPV6=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IPV6_MULTIPLE_TABLES=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP6_NF_IPTABLES=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP6_NF_FILTER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP6_NF_MANGLE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP6_NF_NAT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP6_NF_TARGET_MASQUERADE=y" >> $MAIN_DEFCONFIG
        # legacy compat
        echo "CONFIG_NF_CONNTRACK_IPV6=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NF_NAT_IPV6=y" >> $MAIN_DEFCONFIG
        # Disable this on older kernels to make internet work
        echo "CONFIG_ANDROID_PARANOID_NETWORK=n" >> $MAIN_DEFCONFIG
        # Fix for docker unsafe procfs error
        echo "CONFIG_USER_NS=y" >> $MAIN_DEFCONFIG
        # UFW & FAIL2BAN CORE
        echo "CONFIG_NETFILTER_XT_MATCH_COMMENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_STATE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_HL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_REJECT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_TARGET_REJECT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_LOG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_NF_TARGET_ULOG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_RECENT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_LIMIT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_HASHLIMIT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_OWNER=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_PKTTYPE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_MATCH_MARK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_MARK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_SET=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_SET_HASH_IP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_IP_SET_HASH_NET=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_SET=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_NETLINK_QUEUE=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_NETLINK_LOG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_NETFILTER_XT_TARGET_NFLOG=y" >> $MAIN_DEFCONFIG
}

# NetHunter
nethunter_fouronefour_configs() {
    echo "-- Enabling general config for NetHunter..."
    echo "CONFIG_SYSVIPC=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MODULES=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MODULE_UNLOAD=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MODULE_FORCE_UNLOAD=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MODVERSIONS=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling network config for NetHunter..."
    echo "CONFIG_BT_HCIBTUSB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIBTUSB_BCM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIBTUSB_RTL=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIUART=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIUART_H4=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIBCM203X=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIBPA10X=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIBFUSB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_BT_HCIVHCI=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_ANDROID_BINDER_IPC=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CFG80211_WEXT=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MAC80211=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MAC80211_MESH=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_RTL8150=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_RTL8152=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling wifi config for NetHunter..."
    echo "CONFIG_WLAN_VENDOR_ATH=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_ATH9K_HTC=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CARL9170=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_ATH6KL=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_ATH6KL_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_WLAN_VENDOR_MEDIATEK=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MT7601U=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_WLAN_VENDOR_RALINK=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2X00=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2500USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT73USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_RT33XX=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_RT35XX=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_RT3573=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_RT53XX=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_RT55XX=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RT2800USB_UNKNOWN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_WLAN_VENDOR_REALTEK=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RTL8187=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RTL_CARDS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RTL8192CU=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_RTL8XXXU_UNTESTED=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_WLAN_VENDOR_ZYDAS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_ZD1201=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_ZD1211RW=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_NET_RNDIS_WLAN=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling SDR config for NetHunter..."
    echo "CONFIG_MEDIA_DIGITAL_TV_SUPPORT=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MEDIA_SDR_SUPPORT=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_AIRSPY=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_HACKRF=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_MSI2500=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_MEDIA_SUBDRV_AUTOSELECT=n" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_DVB_RTL2830=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_DVB_RTL2832=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_DVB_RTL2832_SDR=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_DVB_SI2168=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_DVB_ZD1301_DEMOD=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling USB config for NetHunter..."
    echo "CONFIG_USB_ACM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_SERIAL=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_ACM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_OBEX=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_NCM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_ECM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_ECM_SUBSET=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_RNDIS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_EEM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_MASS_STORAGE=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_CONFIGFS_F_HID=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling NFS config for NetHunter..."
    echo "CONFIG_NETWORK_FILESYSTEMS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFS_V2=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFS_V3=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFS_V4=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFSD=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFSD_V3=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NFSD_V4=y" >> "$MAIN_DEFCONFIG"
    echo "-- Enabling CAN config for NetHunter..."
    echo "CONFIG_CAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NET_DEVLINK=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_RAW=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_BCM=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_GW=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_VCAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_SLCAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_DEV=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_CALC_BITTIMING=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_LEDS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_GRCAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_XILINXCAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_C_CAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_CC770=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_IFI_CANFD=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_M_CAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_SJA1000=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_SOFTING=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_HI311X=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_MCP251X=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_EMS_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_ESD_USB2=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_GS_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_KVASER_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_PEAK_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_8DEV_USB=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_VSOCKETS=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NETLINK_DIAG=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_NET_EMATCH_CANID=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_SERIAL_CONSOLE=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_SERIAL_GENERIC=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_SERIAL_CH341=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_USB_SERIAL_FTDI_SIO=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_HLCAN=y" >> "$MAIN_DEFCONFIG"
    echo "CONFIG_CAN_ISOTP=y" >> "$MAIN_DEFCONFIG"
}
nethunter_fouronefour_patches() {
    local rtl88xxau_driver="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel-builder/-/raw/main/patches/4.14/add-rtl88xxau-5.6.4.2-drivers.patch"
    local rtw88_driver="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel-builder/-/raw/main/patches/4.14/add-rtw88-drivers-4.14.patch"
    local ub500_patch="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel-builder/-/raw/main/patches/4.04/add-ub500-to-btusb.patch"
    echo "-- Patching rtl88xxau..."
    apply_patches "$rtl88xxau_driver"
    sed -i 's/__attribute__ ((fallthrough));/fallthrough;/g' drivers/net/wireless/realtek/rtl8812au/core/rtw_mlme_ext.c
    sed -i 's/sec->owe_ie && sec->owe_ie_len > 0/sec->owe_ie_len > 0/g' drivers/net/wireless/realtek/rtl8812au/core/rtw_mlme_ext.c
    echo "CONFIG_88XXAU=y" >> "$MAIN_DEFCONFIG"
    echo "-- Patching rtw88..."
    apply_patches "$rtw88_driver"
    echo "CONFIG_RTW88=y" >> "$MAIN_DEFCONFIG"
    echo "-- Patching ub500..."
    apply_patches "$ub500_patch"
    echo "-- Patching ath9k..."
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_start\b/ath9k_htc_start/g' {} +
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_stop\b/ath9k_htc_stop/g' {} +
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_connect_service\b/ath9k_htc_connect_service/g' {} +
    sed -i -E 's/static int ath9k_htc_start\(struct ieee80211_hw/static int ath9k_mac80211_start(struct ieee80211_hw/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/static void ath9k_htc_stop\(struct ieee80211_hw/static void ath9k_mac80211_stop(struct ieee80211_hw/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/\.start[[:space:]]*=[[:space:]]*ath9k_htc_start,/.start = ath9k_mac80211_start,/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/\.stop[[:space:]]*=[[:space:]]*ath9k_htc_stop,/.stop = ath9k_mac80211_stop,/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
}
nethunter_fouronenine_patches() {
    local rtw88_driver="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel-builder/-/raw/main/patches/4.19/add-rtw88-drivers-4.19.patch"
    local ub500_patch="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernel-builder/-/raw/main/patches/4.04/add-ub500-to-btusb.patch"
    echo "-- Patching rtw88..."
    apply_patches "$rtw88_driver"
    echo "CONFIG_RTW88=y" >> "$MAIN_DEFCONFIG"
    echo "-- Patching ub500..."
    apply_patches "$ub500_patch"
    echo "-- Patching ath9k..."
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_start\b/ath9k_htc_start/g' {} +
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_stop\b/ath9k_htc_stop/g' {} +
    find drivers/net/wireless/ath/ath9k -type f -name "*.[ch]" -exec sed -i 's/\bhtc_connect_service\b/ath9k_htc_connect_service/g' {} +
    sed -i -E 's/static int ath9k_htc_start\(struct ieee80211_hw/static int ath9k_mac80211_start(struct ieee80211_hw/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/static void ath9k_htc_stop\(struct ieee80211_hw/static void ath9k_mac80211_stop(struct ieee80211_hw/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/\.start[[:space:]]*=[[:space:]]*ath9k_htc_start,/.start = ath9k_mac80211_start,/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
    sed -i -E 's/\.stop[[:space:]]*=[[:space:]]*ath9k_htc_stop,/.stop = ath9k_mac80211_stop,/g' drivers/net/wireless/ath/ath9k/htc_drv_main.c
}

# KernelSU
ksu_import_hook_script() {
    if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
        KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"
    else
        KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"
    fi
}
ksu_run_setup() {
    echo "-- KernelSU: Running setup script..."
    curl -LSs --fail --retry 3 "$KSU_SETUP_URI" | bash -s "$KSU_SETUP_BRANCH" &> /dev/null || { echo "-- Fatal: KSU setup script failed to download/run!"; exit 1; }
}
ksu_common_configs() {
    echo "-- KernelSU: Enabling configs..."
    echo "CONFIG_KSU=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KPM=n" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_MANUAL_HOOK=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_THREAD_INFO_IN_TASK=y" >> $MAIN_DEFCONFIG
}
ksu_setup_susfs() {
    echo "-- KernelSU: Applying SUSFS patch..."
    echo " "
    echo "==================================================================="
    wget -qO- $SUSFS_PATCH | patch -p1 --fuzz=5
    echo "==================================================================="
    echo " "
    echo "-- KernelSU: Enabling SUSFS configs..."
    echo "CONFIG_KSU_SUSFS=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> $MAIN_DEFCONFIG
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> $MAIN_DEFCONFIG
}
ksu_fix_susfs_fouronefour() {
    if [[ "$KERNEL_VERSION" == "4.14" ]]; then
        if ! grep -A 20 "static struct file \*path_openat(" fs/namei.c | grep -q "old_dfd"; then
            echo "-- KernelSU: Patching fs/namei.c for susfs_open_redirect..."
            sed -i '/static struct file \*path_openat(/,/^{/ {/^{/a \
            #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n\tint old_dfd __maybe_unused = nd->dfd;\n\tstruct filename *fake_filename __maybe_unused = NULL;\n#endif
            }' fs/namei.c
        fi
        if ! grep -q "susfs_is_uname_spoof_buffer_set" kernel/sys.c; then
            echo "-- KernelSU: Patching kernel/sys.c for susfs_spoof_uname..."
            sed -i 's/^SYSCALL_DEFINE1(newuname/#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\nextern struct static_key_false susfs_is_uname_spoof_buffer_set;\nextern void susfs_spoof_uname(struct new_utsname* tmp);\n#endif\nSYSCALL_DEFINE1(newuname/' kernel/sys.c
            sed -i 's/memcpy(&tmp, utsname(), sizeof(tmp));/&\n#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\n\tif (static_branch_likely(\&susfs_is_uname_spoof_buffer_set))\n\t\tsusfs_spoof_uname(\&tmp);\n#endif/' kernel/sys.c
        fi
        echo "-- KernelSU: Checking for patch fuzzing in fs/namespace.c..."
        ALLOC_LINE=$(awk '/^static int mnt_alloc_group_id/{print NR; exit}' fs/namespace.c)
        if [ -n "$ALLOC_LINE" ]; then
            if awk "NR > $ALLOC_LINE && NR < $ALLOC_LINE + 25 && /^[[:space:]]*return;/" fs/namespace.c | grep -q "return;"; then
                echo "-- KernelSU: Detected misplaced SusFS patch in mnt_alloc_group_id. Fixing..."
                START_LINE=$(awk "NR > $ALLOC_LINE && /#ifdef CONFIG_KSU_SUSFS/ {print NR; exit}" fs/namespace.c)
                END_LINE=$(awk "NR > $START_LINE && /#endif/ {print NR; exit}" fs/namespace.c)
                if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
                    sed -n "${START_LINE},${END_LINE}p" fs/namespace.c > /tmp/susfs_misplaced_block.c
                    sed -i "${START_LINE},${END_LINE}d" fs/namespace.c
                    FREE_LINE=$(awk '/^static void mnt_free_id/{print NR; exit}' fs/namespace.c)
                    WORK_LINE=$(awk "NR > $FREE_LINE && /(ida_remove|ida_free|spin_lock)/ {print NR; exit}" fs/namespace.c)
                    if [ -n "$WORK_LINE" ]; then
                        sed -i "$((WORK_LINE - 1))r /tmp/susfs_misplaced_block.c" fs/namespace.c
                        echo "-- KernelSU: Successfully moved the SusFS block back to mnt_free_id."
                    else
                        echo "-- KernelSU: Failed to find injection point in mnt_free_id."
                    fi
                else
                    echo "-- KernelSU: Could not determine the boundaries of the misplaced block."
                fi
            else
                echo "-- KernelSU: fs/namespace.c is clean, no fix needed."
            fi
        fi
        echo "-- KernelSU: Checking for patch fuzzing in fs/proc/task_mmu.c..."
        awk '
        /^[a-zA-Z_][a-zA-Z0-9_*[:space:]]+[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(/ {
            func_name = $0
        }
        in_sus_map && /return/ {
            if (func_name ~ /show_smap/) {
                sub(/return[^;]*;/, "return 0;")
            } else {
                sub(/return[^;]*;/, "return;")
            }
        }
        /#ifdef CONFIG_KSU_SUSFS_SUS_MAP/ { in_sus_map = 1 }
        /#endif/ { in_sus_map = 0 }
        { print }
        ' fs/proc/task_mmu.c > fs/proc/task_mmu.c.tmp && mv fs/proc/task_mmu.c.tmp fs/proc/task_mmu.c
        echo "-- KernelSU: Checking for undeclared identifier on fs/stat.c..."
        sed -i '/struct filename \*fname;/d' fs/stat.c
        sed -i '/fname = getname_flags/i \	struct filename *fname;' fs/stat.c
    fi
}
ksu_fix_susfs_fouronenine() {
    if [[ "$KERNEL_VERSION" == "4.19" ]]; then
        echo "-- KernelSU: Patching fs/namespace.c for susfs_sus_mount..."
        sed -i 's|^[[:space:]]*mnt = alloc_vfsmnt(fc->source ?: "none");|#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n\t// - We will just stop checking for ksu process if /sdcard/Android is accessible,\n\t//   for the sake of performance\n\tif (static_branch_unlikely(\&susfs_is_sdcard_android_data_not_decrypted)) {\n\t\tif (susfs_is_current_ksu_domain()) {\n\t\t\tmnt = susfs_alloc_non_unshare_ksu_vfsmnt(fc->source ?:"none");\n\t\t\tgoto bypass_orig_flow;\n\t\t}\n\t}\n#endif\n\tmnt = alloc_vfsmnt(fc->source ?: "none");\n#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\nbypass_orig_flow:\n#endif|' fs/namespace.c
        echo "-- KernelSU: Checking for undeclared identifier on fs/stat.c..."
        sed -i '/struct filename \*fname;/d' fs/stat.c
        sed -i '/fname = getname_flags/i \	struct filename *fname;' fs/stat.c
    fi
}
ksu_fix_susfs_fourpointfour() {
    if [[ "$KERNEL_VERSION" == "4.4" ]]; then
        echo "-- KernelSU: Fixing fs/stat.c for SusFS on 4.4..."
        if ! grep -q "linux/susfs_def.h" fs/stat.c; then
            sed -i '/#include <asm\/unistd\.h>/a #include <linux/susfs_def.h>' fs/stat.c
        fi
        if ! grep -q "u32 sus_kstat_mask" fs/stat.c; then
            sed -i '/struct inode \*inode = d_backing_inode(path->dentry);/a \	u32 sus_kstat_mask = 0;' fs/stat.c
        fi
        sed -i 's/stat->result_mask/sus_kstat_mask/g' fs/stat.c
        echo "-- KernelSU: fs/stat.c patch applied successfully."
    fi
}
ksu_apply_hooks() {
    if [[ "$KERNEL_VERSION" == "4.4" ]]; then
        echo "-- KernelSU: Downloading hook script..."
        curl -LSs --fail --retry 3 "$KSU_HOOK" -o ksu-hooks.sh
        echo "-- KernelSU: Skipping patch for fs/stat.c on 4.4..."
        sed -i '/fs\/stat\.c)/a \        [[ "$KERNEL_VERSION" == "4.4" ]] && { echo "Skipping fs/stat.c on 4.4"; continue; }' ksu-hooks.sh
        echo "-- KernelSU: Applying hooks..."
        bash ksu-hooks.sh &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }
    else
        echo "-- KernelSU: Applying hooks..."
        curl -LSs --fail --retry 3 "$KSU_HOOK" | bash &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }
    fi
    if [[ "$KERNEL_VERSION" == "4.4" ]]; then
        echo "-- KernelSU: Tuning drivers/tty/pty.c under 4.4..."
        sed -i '/static struct tty_struct \*pts_unix98_lookup/,/}/ s/ksu_handle_devpts((struct inode \*)file->f_path.dentry->d_inode);/ksu_handle_devpts(pts_inode);/' drivers/tty/pty.c
        echo "-- KernelSU: Applying manual fs/stat.c hooks for 4.4..."
        sed -i '/SYSCALL_DEFINE4(newfstatat/i \
        #ifdef CONFIG_KSU_MANUAL_HOOK\n\
            __attribute__((hot))\n\
            extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);\n\
            extern void ksu_handle_newfstat_ret(unsigned int *fd, struct stat __user **statbuf_ptr);\n\
            #if defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_COMPAT_STAT64)\n\
                extern void ksu_handle_fstat64_ret(unsigned long *fd, struct stat64 __user **statbuf_ptr);\n\
            #endif\n\
        #endif\n' fs/stat.c
        sed -i '/error = vfs_fstatat(dfd, filename, &stat, flag);/i \
        #ifdef CONFIG_KSU_MANUAL_HOOK\n\
            \tksu_handle_stat(&dfd, &filename, &flag);\n\
        #endif' fs/stat.c
        sed -i '/SYSCALL_DEFINE2(newfstat,/,/^}/ s/return error;/#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_newfstat_ret(\&fd, \&statbuf);\n#endif\n\treturn error;/' fs/stat.c
        sed -i '/SYSCALL_DEFINE2(fstat64,/,/^}/ s/return error;/#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_fstat64_ret(\&fd, \&statbuf);\n#endif\n\treturn error;/' fs/stat.c
    fi
}
ksu_fix_hooks_fouronefour() {
    if [[ "$KERNEL_VERSION" == "4.14" ]]; then
        echo "-- KernelSU: Fixing typos on fs/stat.c hooks..."
        sed -i 's/ksu_handle_stat(&dfd, &fname, &flag);/ksu_handle_stat(\&dfd, \&fname, \&flags);/g' fs/stat.c
    fi
}
ksu_fix_hooks_fouronenine() {
    if [[ "$KERNEL_VERSION" == "4.19" ]]; then
        echo "-- KernelSU: Fixing typos on fs/stat.c hooks..."
        sed -i 's/ksu_handle_stat(&dfd, &fname, &flag);/ksu_handle_stat(\&dfd, \&fname, \&flags);/g' fs/stat.c
    fi
}
ksu_export_selinux_symbols() {
    echo "-- KernelSU: Checking and exporting static SELinux symbols..."
    unstatic() {
        local file="$1" regex="$2"
        if [ -f "$file" ] && grep -q "static $regex" "$file" 2>/dev/null; then
            sed -i "s/static $regex/$regex/" "$file"
            echo "   -> Exported: $regex"
        fi
    }
    unstatic "security/selinux/selinuxfs.c" "ssize_t (\*write_op\[\])"
    unstatic "security/selinux/selinuxfs.c" "ssize_t (\*const write_op\[\])"
    unstatic "security/selinux/selinuxfs.c" "const struct file_operations sel_handle_status_ops"
    unstatic "security/selinux/selinuxfs.c" "DEFINE_MUTEX(sel_mutex);"
    unstatic "security/selinux/ss/services.c" "struct page \*selinux_status_page;"
    unstatic "security/selinux/ss/services.c" "DEFINE_MUTEX(selinux_status_lock);"
    unstatic "security/selinux/ss/services.c" "DEFINE_RWLOCK(policy_rwlock);"
    unstatic "security/selinux/hooks.c" "struct security_operations selinux_ops"
}

# NoMount
nomount_download() {
    echo "-- NoMount: Downloading source code..."
    wget $NOMOUNT_SETUP_ZIP -O v$NOMOUNT_SETUP_VER.zip &> /dev/null || { echo "Fatal: NoMount source code failed to download!"; exit 1; }
    if [ -f "$PWD/v$NOMOUNT_SETUP_VER.zip" ]; then
        echo "-- NoMount: Unzipping source code..."
        unzip $PWD/v$NOMOUNT_SETUP_VER.zip -d $PWD/ &> /dev/null
    else
        echo "-- NoMount: Cant find zipped source code!"
        ls -alhZ $PWD/
        exit 1
    fi
}
nomount_setup() {
    if [ -d "$PWD/nomount-$NOMOUNT_SETUP_VER" ]; then
        echo "-- NoMount: Setting up..."
        sed -i '/^endmenu/i source "fs/nomount/Kconfig"' fs/Kconfig
        sed -i '$ a\obj-$(CONFIG_NOMOUNT) += nomount/' fs/Makefile
        mkdir -p $PWD/fs/nomount
        cp -r $PWD/nomount-$NOMOUNT_SETUP_VER/kernel/src/* $PWD/fs/nomount
        echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG
        echo "ccflags-y += -Wno-declaration-after-statement" >> fs/nomount/Makefile
    else
        echo "-- NoMount: Can't find unzipped source code!"
        ls -alhZ $PWD/
        exit 1
    fi
}
nomount_setup_bleeding_edge() {
    echo "-- NoMount: Bleeding Edge! Running setup script..."
    curl -LSs --fail --retry 3 "$NOMOUNT_SETUP_URI_BLEEDING_EDGE" | bash -s "$NOMOUNT_SETUP_BRANCH_BLEEDING_EDGE" &> /dev/null || { echo "-- Fatal: NoMount setup script failed to download/run!"; exit 1; }
}

# ReKernel
rekernel_setup() {
    echo "-- ReKernel: Applying patches..."
    curl -LSs --fail --retry 3 "$REKERNEL_PATCH" | bash || { echo "-- Fatal: Failed to apply rekernel patch!"; exit 1; }
    wget -qO- $REKERNEL_EXTRA | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply rekernel extra patch!"; exit 1; }
    echo "CONFIG_REKERNEL=y" >> $MAIN_DEFCONFIG
}
