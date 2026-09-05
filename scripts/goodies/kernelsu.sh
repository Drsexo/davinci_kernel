#!/bin/bash

# Default exports
export SUSFS_PATCH="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/Patch/susfs_patch_to_${KERNEL_VERSION}.patch"

echo "-- Setting up KernelSU integration: ReSukiSU SusFS"

KSU_SETUP_URI="https://github.com/ReSukiSU/ReSukiSU/raw/refs/heads/main/kernel/setup.sh"
KSU_SETUP_BRANCH="main"
KSU_HOOK="https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd/raw/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh"

# Resolve ReSukiSU's version same moment setup.sh below fetches it.
AUTH_HEADER=()
[ -n "$GH_TOKEN" ] && AUTH_HEADER=(-H "Authorization: token $GH_TOKEN")
KSU_SHA=$(curl -fsSL "${AUTH_HEADER[@]}" "https://api.github.com/repos/ReSukiSU/ReSukiSU/commits/${KSU_SETUP_BRANCH}" | jq -r '.sha // empty' | cut -c1-8)
KSU_TAG=$(curl -fsSL "${AUTH_HEADER[@]}" "https://api.github.com/repos/ReSukiSU/ReSukiSU/tags?per_page=1" | jq -r '.[0].name // "unknown"')
rm -rf /tmp/ksu_src
KSU_CODE="unknown"
if git clone --filter=blob:none --depth=1 "https://github.com/ReSukiSU/ReSukiSU.git" /tmp/ksu_src 2>/dev/null; then
    git -C /tmp/ksu_src fetch --unshallow --filter=blob:none 2>/dev/null \
      || git -C /tmp/ksu_src fetch --filter=blob:none 2>/dev/null || true
    COUNT=$(git -C /tmp/ksu_src rev-list --count HEAD 2>/dev/null)
    [ -n "$COUNT" ] && KSU_CODE=$((30000 + COUNT + 700))
fi
cat > /tmp/ksu_resolved.env << RESOLVEDEOF
KSU_RESOLVED_SHA=${KSU_SHA:-unknown}
KSU_RESOLVED_TAG=${KSU_TAG:-unknown}
KSU_RESOLVED_CODE=${KSU_CODE}
RESOLVEDEOF

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
echo "-- Setting up SUSFS support for KernelSU..."
echo "-- Applying SUSFS patch to the kernel source..."
wget -qO- "$SUSFS_PATCH" | patch -s -p1 --fuzz=5
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

# SUSFS patch workaround
# Check if the patch is already present in path_openat's opening lines
if ! grep -A 20 "static struct file \*path_openat(" fs/namei.c | grep -q "old_dfd"; then
    echo "-- Patching fs/namei.c for susfs_open_redirect..."
    sed -i '/static struct file \*path_openat(/,/^{/ {/^{/a \
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT\n\tint old_dfd __maybe_unused = nd->dfd;\n\tstruct filename *fake_filename __maybe_unused = NULL;\n#endif
}' fs/namei.c
fi
# Check if the susfs_spoof_uname hook is already present in kernel/sys.c
if ! grep -q "susfs_is_uname_spoof_buffer_set" kernel/sys.c; then
    echo "-- Patching kernel/sys.c for susfs_spoof_uname..."
    sed -i 's/^SYSCALL_DEFINE1(newuname/#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\nextern struct static_key_false susfs_is_uname_spoof_buffer_set;\nextern void susfs_spoof_uname(struct new_utsname* tmp);\n#endif\nSYSCALL_DEFINE1(newuname/' kernel/sys.c
    sed -i 's/memcpy(&tmp, utsname(), sizeof(tmp));/&\n#ifdef CONFIG_KSU_SUSFS_SPOOF_UNAME\n\tif (static_branch_likely(\&susfs_is_uname_spoof_buffer_set))\n\t\tsusfs_spoof_uname(\&tmp);\n#endif/' kernel/sys.c
fi

# Check for a SusFS block misplaced by patch fuzz in fs/namespace.c
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

# Normalize return statements in SusFS SUS_MAP blocks in fs/proc/task_mmu.c
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

# Apply KSU Hooks
echo "-- Applying KernelSU hooks..."
curl -LSs --fail --retry 3 "$KSU_HOOK" | bash &> /dev/null || { echo "Fatal: KSU hook script failed to download/run!"; exit 1; }

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
