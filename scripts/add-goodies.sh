#!/bin/bash
echo "- Setting up additional goodies..."

# Default Exports
export BBG_SETUP_URI="https://github.com/vc-teahouse/Baseband-guard/raw/main/setup.sh"
export SUSFS_PATCH="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"
export NOMOUNT_PATCH="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/patches/nomount_${KERNEL_VERSION}_kernel_integration.patch"
export NOMOUNT_CODE="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/src/nomount.c"
export NOMOUNT_HEADER="https://github.com/maxsteeel/nomount/raw/refs/heads/master/kernel/src/nomount.h"
export DROIDSPACES_XT_QTAGUID="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/01.fix_kernel_panic_in_xt_qtaguid.patch"
export DROIDSPACES_CGROUP="https://github.com/ravindu644/Droidspaces-OSS/raw/refs/heads/main/Documentation/resources/kernel-patches/non-GKI/02.fix_restore%20cgroup%20file%20prefix%20handling%20.patch"

# KernelSU setup
echo "-- Setting up KernelSU..."
case "$KERNELSU_SELECTOR" in
    zako|zako-susfs)
        # KernelSU Settings
        export KSU_SETUP_URI="https://github.com/ReSukiSU/ReSukiSU/raw/refs/heads/main/kernel/setup.sh"
        export KSU_SETUP_BRANCH="main"
        # SUSFS Settings
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            export KSU_SETUP_BRANCH="main"
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"
        else
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"
        fi
        # Setup KernelSU
        curl -LSs --fail --retry 3 "$KSU_SETUP_URI" | bash -s $KSU_SETUP_BRANCH &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }
        # Enable the necessary KernelSU configs
        echo "CONFIG_KSU=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KPM=n" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MANUAL_HOOK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THREAD_INFO_IN_TASK=y" >> $MAIN_DEFCONFIG
        # Apply backport and hooks
        echo "-- Applying KernelSU hooks..."
        curl -LSs "$KSU_HOOK" | bash &> /dev/null
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            if [[ "$KERNEL_VERSION" == "4.19" ]]; then
                sed -i '/#include <linux\/fs_context.h>/d' fs/namespace.c
                wget -qO- $SUSFS_PATCH | patch -s -p1 --fuzz=5
                sed -i '/#include "pnode.h"/i #include <linux/fs_context.h>' fs/namespace.c
            else
                wget -qO- $SUSFS_PATCH | patch -s -p1 --fuzz=5
            fi
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
        fi
        # Kernel 4.4 specific patches
        if [[ "$KERNEL_VERSION" == "4.4" ]]; then
            echo "-- Re-tuning ksu_handle_devpts under 4.4..."
            sed -i '/static struct tty_struct \*pts_unix98_lookup/,/}/ s/ksu_handle_devpts((struct inode \*)file->f_path.dentry->d_inode);/ksu_handle_devpts(pts_inode);/' drivers/tty/pty.c
        fi
        # Kernel 4.14.357 edge case, might remove later
        # if [[ "$KERNEL_VERSION" == "4.14" ]]; then
        #     SUBVERSION_357_CHECK=$(grep -q "SUBLEVEL = 357" "${PWD}/Makefile" && echo "true")
        #     if [[ "$SUBVERSION_357_CHECK" == "true" ]]; then
        #         echo "-- Forcing ksu_for_each_lsm_entry to use hlist_for_each_entry..."
        #         sed -i 's/define ksu_for_each_lsm_entry list_for_each_entry/define ksu_for_each_lsm_entry hlist_for_each_entry/g' drivers/kernelsu/feature/selinux_hide.c
        #     fi
        # fi
        ;;
    ksunext|ksunext-susfs)
        # KernelSU Settings
        export KSU_SETUP_URI="https://github.com/KernelSU-Next/KernelSU-Next/raw/refs/heads/dev/kernel/setup.sh"
        export KSU_SETUP_BRANCH="legacy"
        # SUSFS Settings
        if [[ "$KERNELSU_SELECTOR" == "ksunext-susfs" ]]; then
            export KSU_SETUP_BRANCH="legacy-susfs"
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"
        else
            KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/syscall_hook_patches.sh"
        fi
        # Setup KernelSU
        curl -LSs --fail --retry 3 "$KSU_SETUP_URI" | bash -s $KSU_SETUP_BRANCH &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }
        # Enable the necessary KernelSU configs
        echo "CONFIG_KSU=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MANUAL_HOOK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THREAD_INFO_IN_TASK=y" >> $MAIN_DEFCONFIG
        # Apply backport and hooks
        echo "-- Applying KernelSU hooks..."
        curl -LSs "$KSU_HOOK" | bash &> /dev/null
        if [[ "$KERNELSU_SELECTOR" == "ksunext-susfs" ]]; then
            if [[ "$KERNEL_VERSION" == "4.19" ]]; then
                sed -i '/#include <linux\/fs_context.h>/d' fs/namespace.c
                wget -qO- $SUSFS_PATCH | patch -s -p1 --fuzz=5
                sed -i '/#include "pnode.h"/i #include <linux/fs_context.h>' fs/namespace.c
            else
                wget -qO- $SUSFS_PATCH | patch -s -p1 --fuzz=5
            fi
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
        fi
        # Kernel 4.4 specific patches
        if [[ "$KERNEL_VERSION" == "4.4" ]]; then
            echo "-- Re-tuning ksu_handle_devpts under 4.4..."
            sed -i '/static struct tty_struct \*pts_unix98_lookup/,/}/ s/ksu_handle_devpts((struct inode \*)file->f_path.dentry->d_inode);/ksu_handle_devpts(pts_inode);/' drivers/tty/pty.c
        fi
        ;;
    none|"")
        echo "-- KernelSU is not selected."
        ;;
    *)
        echo "- Invalid KERNELSU_SELECTOR: $KERNELSU_SELECTOR. Valid options: zako, zako-susfs, ksunext, ksunext-susfs, none."
        exit 1
        ;;
esac

# Baseband Guard setup
case "$BBG_SELECTOR" in
    bbg)
        # Setup Baseband Guard
        echo "-- Setting up Baseband Guard..."
        curl -LSs --fail --retry 3 "$BBG_SETUP_URI" | bash &> /dev/null || { echo "-- Fatal: BBG setup script failed to download/run!"; exit 1; }
        # Enable the necessary Baseband Guard configs
        echo "CONFIG_BBG=y" >> $MAIN_DEFCONFIG
        # Check if kernel have DEFINE_LSM
        DEFINE_LSM_CHECK=$(grep -q "#define DEFINE_LSM(lsm)" "${PWD}/include/linux/lsm_hooks.h" && echo "true")
        # Check if kernel have task_security_struct
        TASK_SECURITY_STRUCT_CHECK=$(grep -q "struct[[:space:]]\+task_security_struct[[:space:]]\+\*selinux_cred" "${PWD}/security/selinux/include/objsec.h" && echo "true")
        # Kernel Settings for Baseband Guard
        if [[ "$DEFINE_LSM_CHECK" == "true" ]]; then
            LSM_FALLBACK='CONFIG_LSM="lockdown,yama,loadpin,safesetid,integrity,selinux,smack,tomoyo,apparmor,bpf,baseband_guard"'
            if grep -q "CONFIG_LSM=" "$MAIN_DEFCONFIG"; then
                sed -i '/CONFIG_LSM=/s/"$/ ,baseband_guard"/' "$MAIN_DEFCONFIG"
                echo "-- Appended baseband_guard to existing CONFIG_LSM."
            else
                echo "$LSM_FALLBACK" >> "$MAIN_DEFCONFIG"
                echo "-- Added default CONFIG_LSM with baseband_guard."
            fi
        fi
        # Remove duplicate on bbg if exist
        if [[ "$TASK_SECURITY_STRUCT_CHECK" == "true" ]]; then
            echo "-- Removing duplicate task_security_struct definition..."
            sed -i '/static inline struct task_security_struct \*selinux_cred/,/[[:space:]]*}/d' security/baseband-guard/tracing/tracing.c
        fi
        ;;
    none|"")
        echo "-- Baseband Guard is not selected."
        ;;
    *)
        echo "- Invalid BBG_SELECTOR: $BBG_SELECTOR. Valid options: bbg, none."
        exit 1
        ;;
esac

# Nomount setup
case "$NOMOUNT_SELECTOR" in
    nomount)
        echo "-- Setting up nomount..."
        # Download nomount patch, code, and header
        wget -qO- $NOMOUNT_PATCH | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply nomount patch!"; exit 1; }
        wget -qO- $NOMOUNT_CODE > "${PWD}/fs/nomount.c" || { echo "-- Fatal: Failed to download nomount.c!"; exit 1; }
        wget -qO- $NOMOUNT_HEADER > "${PWD}/fs/nomount.h" || { echo "-- Fatal: Failed to download nomount.h!"; exit 1; }
        # Enable the necessary Nomount configs
        echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG
        ;;
    none|"")
        echo "-- Nomount is not selected."
        ;;
    *)
        echo "- Invalid NOMOUNT_SELECTOR: $NOMOUNT_SELECTOR. Valid options: nomount, none."
        exit 1
        ;;
esac

# Droidspaces setup 
case "$DROIDSPACES_SELECTOR" in
    droidspaces)
        echo "-- Setting up Droidspaces..."
        # Check if kernel have xt_qtaguid
        if [[ ! -f "net/netfilter/xt_qtaguid.c" ]]; then
            echo "-- Droidspaces: xt_qtaguid module not found in kernel source."
            XT_QTAGUID_CHECK="false"
        else
            XT_QTAGUID_CHECK="true"
        fi
        # Apply patches
        if [[ "$XT_QTAGUID_CHECK" == "true" ]]; then
            echo "-- Droidspaces: net/netfilter/xt_qtaguid.c exist, applying patch..."
            wget -qO- $DROIDSPACES_XT_QTAGUID | patch -s -p1 --fuzz=5 || { echo "-- Fatal: Failed to apply Droidspaces xt_qtaguid patch!"; exit 1; }
        fi
        # Check if kernel version is 4.14
        if [[ "$KERNEL_VERSION" == "4.14" ]]; then
            echo "-- Droidspaces: Kernel is 4.14, changing id..."
            sed -i 's/css->cgroup->id/css->cgroup->kn->id/g' include/net/netprio_cgroup.h
            sed -i 's/css->cgroup->id/css->cgroup->kn->id/g' net/core/netprio_cgroup.c
        fi
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
        ;;
    none|"")
        echo "-- Droidspaces is not selected."
        ;;
    *)
        echo "- Invalid DROIDSPACES_SELECTOR: $DROIDSPACES_SELECTOR. Valid options: droidspaces, none."
        exit 1
        ;;
esac