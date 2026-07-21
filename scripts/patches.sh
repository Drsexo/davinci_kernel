#!/bin/bash
echo "- Applying device specific patches for $DEVICE_IMPORT..."

# Patcher helper - 1.5
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Applying patch: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_patch.patch
        if [ -s /tmp/temp_patch.patch ]; then
            patch -s -p1 --fuzz=5 < /tmp/temp_patch.patch || { echo "Fatal: Failed to apply patch!"; exit 1; }
        else
            echo "Fatal: Failed to download patch from $patch_url"
            exit 1
        fi
    done
}

# Shared patches for 4.14
LTO_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/fix_lto.patch"
KPATCH_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"

# Apply LTO and kpatch patches for 4.14
echo "-- Applying LTO patches..."
apply_patches "$LTO_PATCH"

echo "-- Applying KPATCH patches..."
apply_patches "$KPATCH_PATCH"

# Common configs for 4.14
echo "-- Tuning default configs..."
echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG

# Off: CONFIG_LTO_CLANG makes Makefile.build pipe objdump into grep -q,
# which SIGPIPEs llvm-objdump ("LLVM ERROR: Broken pipe" log spam, harmless
# but noisy). Not needed here, nothing loads prebuilt modules against this.
echo "CONFIG_MODVERSIONS=n" >> $MAIN_DEFCONFIG
echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_COMPRESSION=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_LZ4=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_LZO=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_ZSTD=y" >> $MAIN_DEFCONFIG