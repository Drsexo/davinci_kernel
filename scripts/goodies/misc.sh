#!/bin/bash
echo "- Setting up miscellaneous improvements..."

# LZ4 1.10 upgrade
# Source: SOVIET-ANDROID/kernel_xiaomi_raphael 
# Commit: ce31fef3ea2e6ca2a9349641ea0829397b255a69
# Author: Juhyung Park <qkrwngud825@gmail.com>
if [ -f lib/lz4/lz4.c ]; then
    echo "-- LZ4 1.10 already present, skipping."
else
    echo "-- Upgrading LZ4 to v1.10.0..."

    LZ4_SRC="scripts/goodies/patches/lz4"

    rm -f lib/lz4/lz4_compress.c lib/lz4/lz4_decompress.c lib/lz4/lz4defs.h lib/lz4/lz4hc_compress.c
    rm -rf lib/lz4/lz4armv8

    for f in lz4.c lz4.h lz4hc.c lz4hc.h; do
        cp "$LZ4_SRC/$f" "lib/lz4/$f" \
            || { echo "Fatal: Failed to copy lib/lz4/$f"; exit 1; }
    done

    cat > lib/lz4/Makefile << 'EOF'
ccflags-y += -O3 \
    -DLZ4_FREESTANDING=1

obj-$(CONFIG_LZ4_COMPRESS) += lz4.o
obj-$(CONFIG_LZ4_DECOMPRESS) += lz4.o
obj-$(CONFIG_LZ4HC_COMPRESS) += lz4hc.o
EOF

    cp "$LZ4_SRC/lz4_wrapper.h" include/linux/lz4.h \
        || { echo "Fatal: Failed to copy include/linux/lz4.h"; exit 1; }

    sed -i '/#include "lz4armv8\/lz4accel.h"/d' lib/lz4/lz4.h

    echo "-- LZ4 upgraded to v1.10.0."
fi

# ZRAM lz4
echo "-- Setting zram default compressor to lz4..."
sed -i 's/default_compressor = "lzo"/default_compressor = "lz4"/' drivers/block/zram/zram_drv.c 2>/dev/null || true
echo "CONFIG_ZRAM_DEF_COMP_LZ4=y" >> $MAIN_DEFCONFIG

# ZRAM size override: 3GB
echo "-- Setting zram size to 3GB..."
if grep -q "ZRAM_SIZE_OVERRIDE" drivers/block/zram/Kconfig; then
    echo "-- ZRAM_SIZE_OVERRIDE already in Kconfig, setting config only."
else
    echo "-- Porting ZRAM_SIZE_OVERRIDE to Kconfig and zram_drv.c..."

    if grep -q "CONFIG_ZRAM_SIZE_OVERRIDE" drivers/block/zram/zram_drv.c; then
        echo "-- zram_drv.c already patched, skipping."
    else
        awk '
        /disksize = memparse\(buf, NULL\);/ {
            in_disksize = 1
            print "#ifndef CONFIG_ZRAM_SIZE_OVERRIDE"
            print
            next
        }
        /return -EINVAL;/ && in_disksize && !done {
            print
            print "#else"
            print "\tdisksize = (u64)(1ULL << 30) * CONFIG_ZRAM_SIZE_OVERRIDE;"
            print "\tpr_info(\"zram: overriding disksize to %llu bytes\\n\", disksize);"
            print "#endif"
            done = 1
            in_disksize = 0
            next
        }
        { print }
        ' drivers/block/zram/zram_drv.c > /tmp/zram_drv_patched.c && mv /tmp/zram_drv_patched.c drivers/block/zram/zram_drv.c

        if ! grep -q "CONFIG_ZRAM_SIZE_OVERRIDE" drivers/block/zram/zram_drv.c; then
            echo "Fatal: Failed to patch zram_drv.c"
            exit 1
        fi
    fi

    cat >> drivers/block/zram/Kconfig << 'EOF'

config ZRAM_SIZE_OVERRIDE
    int "zram size to set from kernel (in GB)"
    range 1 8
    default 2
    help
      Override zram disk size in GB. When set, the kernel forces this
      size regardless of userspace disksize_store() calls.
EOF
fi
echo "CONFIG_ZRAM_SIZE_OVERRIDE=3" >> $MAIN_DEFCONFIG

# Swappiness
echo "-- Reducing vm swappiness to 30..."
sed -i 's/^int vm_swappiness = [0-9]*;/int vm_swappiness = 30;/' mm/vmscan.c

# Suppress overlayfs log spam
echo "-- Suppressing overlayfs log spam..."
sed -i 's/pr_err("overlayfs: upperdir is in-use/pr_debug_once("overlayfs: upperdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_warn("overlayfs: upperdir is in-use/pr_debug_once("overlayfs: upperdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_err("overlayfs: workdir is in-use/pr_debug_once("overlayfs: workdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_warn("overlayfs: workdir is in-use/pr_debug_once("overlayfs: workdir is in-use/' fs/overlayfs/super.c