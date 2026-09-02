#!/bin/bash
echo "- Applying device specific patches for $DEVICE_IMPORT..."

# Patcher helper - 1.6
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Applying patch: $(basename "$patch_url")"
        if [[ "$patch_url" == http://* || "$patch_url" == https://* ]]; then
            curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_patch.patch
        else
            cp "$patch_url" /tmp/temp_patch.patch
        fi
        if [ -s /tmp/temp_patch.patch ]; then
            if patch --dry-run -R -p1 --fuzz=5 < /tmp/temp_patch.patch > /dev/null 2>&1; then
                echo "-- Already applied upstream, skipping: $(basename "$patch_url")"
                continue
            fi
            patch -s -p1 --fuzz=5 < /tmp/temp_patch.patch || { echo "Fatal: Failed to apply patch!"; exit 1; }
        else
            echo "Fatal: Failed to fetch patch from $patch_url"
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

# BBR2 congestion control for 4.14
echo "-- Applying BBR2 patches..."
BBR2_DIR="scripts/goodies/patches/bbr2"
if [ "$ROM_IMPORT" = "pixelos" ]; then
    BBR2_PATCH="$BBR2_DIR/pixelos.patch"
else
    BBR2_PATCH="$BBR2_DIR/lineageos.patch"
fi
apply_patches "$BBR2_PATCH"

# Common configs for 4.14
echo "-- Tuning default configs..."
echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG

echo "CONFIG_MODVERSIONS=n" >> $MAIN_DEFCONFIG
echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_COMPRESSION=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_LZ4=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_LZO=y" >> $MAIN_DEFCONFIG
echo "CONFIG_F2FS_FS_ZSTD=y" >> $MAIN_DEFCONFIG

# Congestion control
echo "CONFIG_TCP_CONG_ADVANCED=y" >> $MAIN_DEFCONFIG
echo "CONFIG_TCP_CONG_BBR=y" >> $MAIN_DEFCONFIG
echo "CONFIG_TCP_CONG_BBR2=y" >> $MAIN_DEFCONFIG
echo "CONFIG_DEFAULT_BBR2=y" >> $MAIN_DEFCONFIG

# Checkpoint/restore
echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG

# CPU tuning
echo "-- Applying CPU tuning..."
sed -i '$ a\KBUILD_CFLAGS += -mcpu=cortex-a76+crc+crypto -mtune=cortex-a76 -march=armv8.2-a+crc+crypto' Makefile

# F2FS IO timeout
echo "-- Fixing F2FS IO timeout..."
sed -i 's/#define\tDEFAULT_IO_TIMEOUT\t(msecs_to_jiffies(1))/#define\tDEFAULT_IO_TIMEOUT\t(msecs_to_jiffies(6))/' fs/f2fs/f2fs.h