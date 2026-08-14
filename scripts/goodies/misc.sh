#!/bin/bash
echo "- Setting up miscellaneous improvements..."

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

# Cache pressure reduction
echo "-- Reducing vfs cache pressure..."
sed -i 's/int sysctl_vfs_cache_pressure __read_mostly = 100;/int sysctl_vfs_cache_pressure __read_mostly = 50;/' fs/dcache.c

# Force deep sleep instead of s2idle
echo "-- Forcing deep sleep instead of s2idle..."
sed -i 's/suspend_state_t mem_sleep_current = PM_SUSPEND_TO_IDLE;/suspend_state_t mem_sleep_current = PM_SUSPEND_MEM;/' kernel/power/suspend.c

# Suppress overlayfs log spam
echo "-- Suppressing overlayfs log spam..."
sed -i 's/pr_err("overlayfs: upperdir is in-use/pr_debug_once("overlayfs: upperdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_warn("overlayfs: upperdir is in-use/pr_debug_once("overlayfs: upperdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_err("overlayfs: workdir is in-use/pr_debug_once("overlayfs: workdir is in-use/' fs/overlayfs/super.c
sed -i 's/pr_warn("overlayfs: workdir is in-use/pr_debug_once("overlayfs: workdir is-in-use/' fs/overlayfs/super.c