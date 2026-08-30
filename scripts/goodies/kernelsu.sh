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
            # Enable SUSFS configs
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
            # Patch SUSFS to the kernel source
            echo "-- Applying SUSFS patch to the kernel source..."
            patch -s -p1 --fuzz=5 < "$SUSFS_PATCH"
            # Kernel 4.14 patchup failure fix for SUSFS
            if [[ "$KERNEL_VERSION" == "4.14" ]]; then
                # Check if the patch is already present in the file
                if ! grep -A 20 "static struct file \*path_openat(" fs/namei.c | grep -q "old_dfd"; then
                    echo "-- Patching fs/namei.c for susfs_open_redirect..."
                    sed -i '/static struct file \*path_openat(/,/^{/ {/^{/a \
                    #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n\tint old_dfd __maybe_unused = nd->dfd;\n\tstruct filename *fake_filename __maybe_unused = NULL;\n#endif
                    }' fs/namei.c
                fi
                if ! grep -q "susfs_is_uname_spoof_buffer_set" kernel/sys.c; then
                    echo "-- Patching kernel/sys.c for susfs_spoof_uname..."
                    sed -i 's/^SYSCALL_DEFINE1(newuname/#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\nextern struct static_key_false susfs_is_uname_spoof_buffer_set;\nextern void susfs_spoof_uname(struct new_utsname* tmp);\n#endif\nSYSCALL_DEFINE1(newuname/' kernel/sys.c
                    sed -i 's/memcpy(&tmp, utsname(), sizeof(tmp));/&\n#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\n\tif (static_branch_likely(\&susfs_is_uname_spoof_buffer_set))\n\t\tsusfs_spoof_uname(\&tmp);\n#endif/' kernel/sys.c
                fi
                # Complicated fs/namespace.c fixup on surya-crdroid
                echo "-- Checking for patch fuzzing in fs/namespace.c..."
                ALLOC_LINE=$(awk '/^static int mnt_alloc_group_id/{print NR; exit}' fs/namespace.c)
                if [ -n "$ALLOC_LINE" ]; then
                    if awk "NR > $ALLOC_LINE && NR < $ALLOC_LINE + 25 && /^[[:space:]]*return;/" fs/namespace.c | grep -q "return;"; then
                        echo "-- Detected misplaced SusFS patch in mnt_alloc_group_id. Fixing..."
                        START_LINE=$(awk "NR > $ALLOC_LINE && /#ifdef CONFIG_KSU_SUSFS/ {print NR; exit}" fs/namespace.c)
                        END_LINE=$(awk "NR > $START_LINE && /#endif/ {print NR; exit}" fs/namespace.c)
                        if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
                            sed -n "${START_LINE},${END_LINE}p" fs/namespace.c > /tmp/susfs_misplaced_block.c
                            sed -i "${START_LINE},${END_LINE}d" fs/namespace.c
                            FREE_LINE=$(awk '/^static void mnt_free_id/{print NR; exit}' fs/namespace.c)
                            WORK_LINE=$(awk "NR > $FREE_LINE && /(ida_remove|ida_free|spin_lock)/ {print NR; exit}" fs/namespace.c)
                            if [ -n "$WORK_LINE" ]; then
                                sed -i "$((WORK_LINE - 1))r /tmp/susfs_misplaced_block.c" fs/namespace.c
                                echo "-- Successfully moved the SusFS block back to mnt_free_id."
                            else
                                echo "-- Failed to find injection point in mnt_free_id."
                            fi
                        else
                            echo "-- Could not determine the boundaries of the misplaced block."
                        fi
                    else
                        echo "-- fs/namespace.c is clean, no fix needed."
                    fi
                fi
                # Complicated fs/proc/task_mmu.c ifxup in surya-crdroid
                echo "-- Checking for patch fuzzing in fs/proc/task_mmu.c..."
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
            fi
            # Kernel 4.19 patchup failure fix for SUSFS
            if [[ "$KERNEL_VERSION" == "4.19" ]]; then
                echo "-- Patching fs/namespace.c for susfs_sus_mount..."
                sed -i 's|^[[:space:]]*mnt = alloc_vfsmnt(fc->source ?: "none");|#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\n\t// - We will just stop checking for ksu process if /sdcard/Android is accessible,\n\t//   for the sake of performance\n\tif (static_branch_unlikely(\&susfs_is_sdcard_android_data_not_decrypted)) {\n\t\tif (susfs_is_current_ksu_domain()) {\n\t\t\tmnt = susfs_alloc_non_unshare_ksu_vfsmnt(fc->source ?:"none");\n\t\t\tgoto bypass_orig_flow;\n\t\t}\n\t}\n#endif\n\tmnt = alloc_vfsmnt(fc->source ?: "none");\n#ifdef CONFIG_KSU_SUSFS_SUS_MOUNT\nbypass_orig_flow:\n#endif|' fs/namespace.c
            fi
            # kernel 4.9 device specific fixes for SUSFS
            if [[ "$KERNEL_VERSION" == "4.9" ]]; then
                if [[ "$DEVICE_IMPORT" == "tissot-playground-nontreble" || "$DEVICE_IMPORT" == "tissot-playground-treble" ]]; then
                    # fs/stat.c
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
                    # fs/proc/cmdline.c
                    echo "-- Fixing broken fs/proc/cmdline.c patch on tissot..."
                    git checkout fs/proc/cmdline.c
                    sed -i '/#include <asm\/setup.h>/a \
                    \
                    #ifdef CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG\
                    extern struct static_key_false susfs_is_fake_cmdline_or_bootconfig_buffer_set;\
                    extern void susfs_spoof_cmdline_or_bootconfig(struct seq_file *m);\
                    #endif' fs/proc/cmdline.c
                    sed -i '/seq_printf(m,/i \
                    #ifdef CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG\
                    \tif (static_branch_likely(&susfs_is_fake_cmdline_or_bootconfig_buffer_set)) {\
                    \t\tsusfs_spoof_cmdline_or_bootconfig(m);\
                    \t\tseq_putc(m, '\''\\n'\'');\
                    \t\treturn 0;\
                    \t}\
                    #endif' fs/proc/cmdline.c
                    # fs/proc/task_mmu.c
                    echo "-- Fixing broken fs/proc/task_mmu.c patch on tissot..."
                    sed -i '/struct inode \*inode = file_inode(vma->vm_file);/a \
                    #ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\
                    \t\tif (SUSFS_IS_INODE_OPEN_REDIRECT(inode)) {\
                    \t\t\tchar *spoofed_redirected_name = NULL;\
                    \t\t\tint srcu_idx = srcu_read_lock(&susfs_srcu_open_redirect);\
                    \t\t\tint ret = susfs_open_redirect_spoof_show_map_vma_srcu(inode, &ino, &dev, &spoofed_redirected_name);\
                    \t\t\tif (!ret) {\
                    \t\t\t\tpgoff = ((loff_t)vma->vm_pgoff) << PAGE_SHIFT;\
                    \t\t\t\tstart = vma->vm_start;\
                    \t\t\t\tend = vma->vm_end;\
                    \t\t\t\tshow_vma_header_prefix(m, start, end, flags, pgoff, dev, ino);\
                    \t\t\t\tseq_pad(m, '\'' '\'');\
                    \t\t\t\tif (spoofed_redirected_name)\
                    \t\t\t\t\tseq_puts(m, spoofed_redirected_name);\
                    \t\t\t\tseq_putc(m, '\''\\n'\'');\
                    \t\t\t\tsrcu_read_unlock(&susfs_srcu_open_redirect, srcu_idx);\
                    \t\t\t\treturn;\
                    \t\t\t}\
                    \t\t\tsrcu_read_unlock(&susfs_srcu_open_redirect, srcu_idx);\
                    \t\t}\
                    #endif\
                    #ifdef CONFIG_KSU_SUSFS_SUS_MAP\
                    \t\tif (SUSFS_IS_INODE_SUS_MAP(inode))\
                    \t\t\treturn;\
                    #endif' fs/proc/task_mmu.c
                    sed -i '/pgoff = ((loff_t)vma->vm_pgoff) << PAGE_SHIFT;/a \
                    #ifdef CONFIG_KSU_SUSFS_SUS_KSTAT\
                    \t\tsusfs_sus_kstat_spoof_show_map_vma(inode, &dev, &ino);\
                    #endif' fs/proc/task_mmu.c
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

        # Kernel 4.9 specific fixes
        if [[ "$KERNEL_VERSION" == "4.9" ]]; then
            echo "-- Cleaning up broken KernelSU vfs_fstatat hook in fs/stat.c..."
            sed -i '/struct path \*path, struct path \*root);/d' fs/stat.c
            sed -i '/unsigned int lookup_flags = 0;/a \
            \tstruct filename *fname;' fs/stat.c
            sed -i 's/ksu_handle_stat(&dfd, &fname, &flags);/ksu_handle_stat(\&dfd, \&fname, \&flag);/g' fs/stat.c
            sed -i '/error = filename_lookup(dfd, fname, lookup_flags, &path, NULL);/a \
            \tif (likely(!IS_ERR(fname)))\n\t\tputname(fname);' fs/stat.c
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