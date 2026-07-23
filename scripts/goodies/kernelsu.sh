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

# Apply KSU Hooks
echo "-- Applying KernelSU hooks..."
curl -LSs --fail --retry 3 "$KSU_HOOK" | bash &> /dev/null || { echo "Fatal: KSU hook script failed to download/run!"; exit 1; }

# SUSFS Logic
echo "-- Setting up SUSFS support for KernelSU..."
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