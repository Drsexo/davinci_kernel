#!/bin/bash

# Default exports
export DROIDSPACES_XT_QTAGUID="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/01.fix_kernel_panic_in_xt_qtaguid.patch"
export DROIDSPACES_CGROUP="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/02.fix_restore%20cgroup%20file%20prefix%20handling%20.patch"
export DROIDSPACES_SYSVIPC="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kabi_6_7_8.patch"
export DROIDSPACES_MQUEUE="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/002.5.10_or_lower_use_android_abi_padding_for_posix_mqueue.patch"

case "$DROIDSPACES_SELECTOR" in
    droidspaces)
        # Start of droidspaces integration
        echo "-- Setting up Droidspaces..."
        
        # Apply patches for 4.x kernels
        if [[ "$KERNEL_VERSION" == "4.4" || "$KERNEL_VERSION" == "4.9" || "$KERNEL_VERSION" == "4.14" || "$KERNEL_VERSION" == "4.19" ]]; then
            echo "-- Droidspaces: Kernel is 4.x, applying patches..."
            # Check if kernel have xt_qtaguid
            if [[ ! -f "net/netfilter/xt_qtaguid.c" ]]; then
                echo "-- Droidspaces: xt_qtaguid module not found in kernel source."
                XT_QTAGUID_CHECK="false"
            else
                XT_QTAGUID_CHECK="true"
            fi
            # Apply xt_qtaguid patch if it exists
            if [[ "$XT_QTAGUID_CHECK" == "true" ]]; then
                echo "-- Droidspaces: net/netfilter/xt_qtaguid.c exist, applying patch..."
                wget -qO- $DROIDSPACES_XT_QTAGUID | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces xt_qtaguid patch!"; exit 1; }
            fi
            # Check if kernel version is 4.14
            if [[ "$KERNEL_VERSION" == "4.14" ]]; then
                echo "-- Droidspaces: Kernel is 4.14, changing id..."
                sed -i 's/css->cgroup->id/cgroup_id(css->cgroup)/g' include/net/netprio_cgroup.h
                sed -i 's/css->cgroup->id/cgroup_id(css->cgroup)/g' net/core/netprio_cgroup.c
            fi
            # Apply cgroup patch
            echo "-- Droidspaces: Applying cgroup patch..."
            wget -qO- $DROIDSPACES_CGROUP | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces cgroup patch!"; exit 1; }
            # IPC mechanisms
            echo "CONFIG_SYSCTL=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_SYSVIPC=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_POSIX_MQUEUE=y" >> $MAIN_DEFCONFIG
            # Core namespace support
            echo "CONFIG_NAMESPACES=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_PID_NS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_UTS_NS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_IPC_NS=y" >> $MAIN_DEFCONFIG
            # Seccomp support
            echo "CONFIG_SECCOMP=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_SECCOMP_FILTER=y" >> $MAIN_DEFCONFIG
            # Control groups support
            echo "CONFIG_CGROUPS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CGROUP_DEVICE=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CGROUP_PIDS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_MEMCG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CGROUP_SCHED=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_FAIR_GROUP_SCHED=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CGROUP_FREEZER=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CGROUP_NET_PRIO=y" >> $MAIN_DEFCONFIG
            # Device filesystem support
            echo "CONFIG_DEVTMPFS=y" >> $MAIN_DEFCONFIG
            # Overlay filesystem support (required for volatile mode)
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
            # Disable this on older kernels to make internet work
            echo "CONFIG_ANDROID_PARANOID_NETWORK=n" >> $MAIN_DEFCONFIG
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
        # Apply patches for 5.x kernels
        elif [[ "$KERNEL_VERSION" == "5.4" || "$KERNEL_VERSION" == "5.10" ]]; then
            echo "-- Droidspaces: Kernel is 5.x, applying patches..."
            # Apply sysvipc patch
            echo "-- Droidspaces: Applying sysvipc patch..."
            wget -qO- $DROIDSPACES_SYSVIPC | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces sysvipc patch!"; exit 1; }
            # Apply mqueue patch if kernel is 5.4
            if [[ "$KERNEL_VERSION" == "5.4" ]]; then
                echo "-- Droidspaces: Kernel is 5.4, applying mqueue patch..."
                wget -qO- $DROIDSPACES_MQUEUE | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces mqueue patch!"; exit 1; }
            fi
            # IPC
            echo "CONFIG_SYSVIPC=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_POSIX_MQUEUE=y" >> $MAIN_DEFCONFIG
            # Namespaces
            echo "CONFIG_IPC_NS=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_PID_NS=y" >> $MAIN_DEFCONFIG
            # HW Access Support
            echo "CONFIG_DEVTMPFS=y" >> $MAIN_DEFCONFIG
            # Networking (Enhanced NAT support)
            echo "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y" >> $MAIN_DEFCONFIG
            # UFW support
            echo "CONFIG_NETFILTER_XT_TARGET_REJECT=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_NETFILTER_XT_TARGET_LOG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_NETFILTER_XT_MATCH_RECENT=y" >> $MAIN_DEFCONFIG
            # Fail2ban support
            echo "CONFIG_IP_SET=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_IP_SET_HASH_IP=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_IP_SET_HASH_NET=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_NETFILTER_XT_SET=y" >> $MAIN_DEFCONFIG
            # Enable xattr, posix acl support on tmpfs
            echo "CONFIG_TMPFS_POSIX_ACL=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_TMPFS_XATTR=y" >> $MAIN_DEFCONFIG
        fi
        ;;
    none|"")
        echo "-- Droidspaces is not selected."
        ;;
    *)
        echo "- Invalid DROIDSPACES_SELECTOR: $DROIDSPACES_SELECTOR. Valid options: droidspaces, none."
        exit 1
        ;;
esac