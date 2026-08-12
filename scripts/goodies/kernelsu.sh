#!/bin/bash

# Default exports
export SUSFS_PATCH="scripts/goodies/assets/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"

case "$KERNELSU_SELECTOR" in
    zako|zako-susfs)
        # Start of KernelSU integration
        echo "-- Setting up KernelSU integration: $KERNELSU_SELECTOR"
        KSU_SETUP_URI="https://github.com/ReSukiSU/ReSukiSU/raw/refs/heads/main/kernel/setup.sh"
        KSU_SETUP_BRANCH="main"

        # Check if susfs are used or not, and set the appropriate hook script URL
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            KSU_HOOK="scripts/goodies/assets/Patches/susfs_inline_hook_patches.sh"
        else
            KSU_HOOK="scripts/goodies/assets/Patches/syscall_hook_patches.sh"
        fi

        # Setup KernelSU
        echo "-- Running KernelSU setup script..."
        curl -LSs --fail --retry 3 "$KSU_SETUP_URI" | bash -s "$KSU_SETUP_BRANCH" &> /dev/null || { echo "Fatal: KSU setup script failed to download/run!"; exit 1; }

        # Enable the necessary KernelSU configs
        echo "-- Enabling KernelSU configs..."
        echo "CONFIG_KSU=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KPM=n" >> $MAIN_DEFCONFIG
        echo "CONFIG_KSU_MANUAL_HOOK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THREAD_INFO_IN_TASK=y" >> $MAIN_DEFCONFIG

        # SUSFS Logic
        if [[ "$KERNELSU_SELECTOR" == "zako-susfs" ]]; then
            echo "-- Setting up SUSFS support for KernelSU..."
            patch -s -p1 --fuzz=5 < "$SUSFS_PATCH"
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
            # Kernel 4.14 device specific fixes for SUSFS
            if [[ "$KERNEL_VERSION" == "4.14" ]]; then
                if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
                    echo "-- Applying KernelSU SUSFS fixes for 4.14..."
                    sed -i '/static struct file \*path_openat(/,/^{/ {/^{/a \
                    #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n\tint old_dfd __maybe_unused = nd->dfd;\n\tstruct filename *fake_filename __maybe_unused = NULL;\n#endif
                    }' fs/namei.c
                fi
            fi
            # kernel 4.9 device specific fixes for SUSFS
            if [[ "$KERNEL_VERSION" == "4.9" ]]; then
                if [[ "$DEVICE_IMPORT" == "tissot-playground-nontreble" || "$DEVICE_IMPORT" == "tissot-playground-treble" ]]; then
                    echo "-- Fixing broken fs/stat.c patch on tissot..."
                    git checkout fs/stat.c
                    sed -i '/#include <asm\/unistd.h>/a \
                    \
                    #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT\
                    extern void susfs_sus_kstat_spoof_generic_fillattr(struct inode *inode, struct kstat *stat);\
                    #endif' fs/stat.c
                    sed -i '/stat->blocks = inode->i_blocks;/a \
                    #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT\
                    \tsusfs_sus_kstat_spoof_generic_fillattr(inode, stat);\
                    #endif' fs/stat.c
                    sed -i '/return inode->i_op->getattr(path->mnt, path->dentry, stat);/c\
                    #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT\
                    \t{\
                    \t\tint err = inode->i_op->getattr(path->mnt, path->dentry, stat);\
                    \t\tif (!err)\
                    \t\t\tsusfs_sus_kstat_spoof_generic_fillattr(inode, stat);\
                    \t\treturn err;\
                    \t}\
                    #else\
                    \t\treturn inode->i_op->getattr(path->mnt, path->dentry, stat);\
                    #endif' fs/stat.c
                fi
            fi
        fi

        # Apply KSU Hooks
        echo "-- Applying KernelSU hooks..."
        bash "$KSU_HOOK" &> /dev/null || { echo "Fatal: KSU hook script failed to download/run!"; exit 1; }

        # Kernel 4.4 specific fixes
        if [[ "$KERNEL_VERSION" == "4.4" ]]; then
            echo "-- Re-tuning ksu_handle_devpts under 4.4..."
            sed -i '/static struct tty_struct \*pts_unix98_lookup/,/}/ s/ksu_handle_devpts((struct inode \*)file->f_path.dentry->d_inode);/ksu_handle_devpts(pts_inode);/' drivers/tty/pty.c
        fi

        # Export SELinux Symbols
        echo "-- Checking and exporting static SELinux symbols..."
        unstatic() {
            local file="$1" regex="$2"
            if [ -f "$file" ] && grep -q "static $regex" "$file" 2>/dev/null; then
                sed -i "s/static $regex/$regex/" "$file"
                echo "   -> Exported: $regex"
            fi
        }
        unstatic "security/selinux/selinuxfs.c" "ssize_t (\*write_op\[\])"
        unstatic "security/selinux/selinuxfs.c" "const struct file_operations sel_handle_status_ops"
        unstatic "security/selinux/selinuxfs.c" "DEFINE_MUTEX(sel_mutex);"
        unstatic "security/selinux/ss/services.c" "struct page \*selinux_status_page;"
        unstatic "security/selinux/ss/services.c" "DEFINE_MUTEX(selinux_status_lock);"
        unstatic "security/selinux/ss/services.c" "DEFINE_RWLOCK(policy_rwlock);"
        unstatic "security/selinux/hooks.c" "struct security_operations selinux_ops"
        ;;
    none|"")
        echo "-- KernelSU is not selected."
        ;;
    *)
        echo "- Invalid KERNELSU_SELECTOR: $KERNELSU_SELECTOR. Valid options: zako, zako-susfs, none."
        exit 1
        ;;
esac