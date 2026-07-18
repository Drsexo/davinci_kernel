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

# Commit reverter - 1.5
revert_commit() {
    for patch_url in "$@"; do
        echo "-- Reverting commit: $(basename "$patch_url")"
        curl -sL --fail --retry 3 "$patch_url" -o /tmp/temp_revert.patch
        if [ -s /tmp/temp_revert.patch ]; then
            patch -R -s -p1 < /tmp/temp_revert.patch || { echo "Fatal: Failed to revert commit!"; exit 1; }
        else
            echo "Fatal: Failed to download revert patch from $patch_url"
            exit 1
        fi
    done
}

# Shared patches for 4.14
LTO_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/fix_lto.patch"
KPATCH_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"

# Patcher - 1.0
case "$DEVICE_IMPORT" in
    sweet|sweet-playground|davinci|tucana|violet|ginkgo|laurel_sprout|a52q|a72q|d2s|d2x|miatoll|sweet-miui)
        # Device specific for 4.14
        if [[ "$DEVICE_IMPORT" == "sweet-playground" ]]; then
            echo "-- Applying LN8K patches..."
            LN8K_COMMON=(
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/b2098690243086601ca394b4bcd5fb4e94ce68ec.patch"
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/33214bb2481d3279764f14fbb4b84d329be95410.patch"
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/c6b5c9eff5fc9e07580ed8d75bd52caf396021aa.patch"
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/95d285024e700545e0d44d5683615b7285063f25.patch"
            )
            LN8K_EXTRA="https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/9e8d4be7a3e2868491486ac86c9e5aa52a5a0c53.patch"
            apply_patches "${LN8K_COMMON[@]}"
            if [[ "$DEVICE_IMPORT" == "sweet-playground" ]]; then
                echo "-- Applying LN8K extra patch with filterdiff..."
                wget -qO- "$LN8K_EXTRA" | filterdiff -x a/drivers/power/supply/qcom/smb5-lib.c | patch -s -p1
            else
                echo "-- Applying LN8K extra patch..."
                wget -qO- "$LN8K_EXTRA" | patch -s -p1
            fi
            echo "CONFIG_CHARGER_LN8000=y" >> $MAIN_DEFCONFIG
        fi
        if [[ "$DEVICE_IMPORT" == "ginkgo" ]] || [[ "$DEVICE_IMPORT" == "laurel_sprout" ]] || [[ "$DEVICE_IMPORT" == "miatoll" ]]; then
            echo "-- Applying DTC patches..."
            apply_patches \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch" \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
        fi
        # LTO and kpatch patches for 4.14
        if [[ "$DEVICE_IMPORT" != "sweet-playground" && "$DEVICE_IMPORT" != "miatoll" ]]; then
            echo "-- Applying LTO patches..."
            apply_patches "$LTO_PATCH"
            if [[ "$DEVICE_IMPORT" != "d2s" && "$DEVICE_IMPORT" != "d2x" ]]; then
                echo "-- Applying KPATCH patches..."
                apply_patches "$KPATCH_PATCH"
            fi
        fi
        # Set drivers as built-in for 4.14
        if [[ "$DEVICE_IMPORT" == "ginkgo" ]]; then
            echo "-- Setting up drivers as built-in..."
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
        fi
        # Common configs for 4.14
        echo "-- Tuning default configs..."
        if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        fi
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        if [[ "$DEVICE_IMPORT" == "sweet" || "$DEVICE_IMPORT" == "davinci" || "$DEVICE_IMPORT" == "tucana" || "$DEVICE_IMPORT" == "violet" || "$DEVICE_IMPORT" == "ginkgo" || "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
            echo "CONFIG_F2FS_FS_COMPRESSION=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_F2FS_FS_LZ4=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_F2FS_FS_LZO=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_F2FS_FS_ZSTD=y" >> $MAIN_DEFCONFIG
        fi
        ;;
    umi|cmi|mi89x7-playground|gta4l)
        # Device specific for 4.19
        if [[ "$DEVICE_IMPORT" == "mi89x7-playground" ]]; then
            # Revert KSU commit
            echo "-- Reverting KSU commit..."
            revert_commit "https://github.com/Mi-Thorium/kernel_msm-4.19/commit/624875e8edc36ae280b1f8efc1d3c48a28da64ea.patch"
        fi
        # Set drivers as built-in for 4.19
        if [[ "$DEVICE_IMPORT" == "gta4l" || "$DEVICE_IMPORT" == "umi" || "$DEVICE_IMPORT" == "cmi" || "$DEVICE_IMPORT" == "mi89x7-playground" ]]; then
            echo "-- Setting up drivers as built-in..."
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
            if [[ "$DEVICE_IMPORT" == "gta4l" ]]; then
                echo "-- Fixing scripts/dtc/livetree.c..."
                sed -i '/assert(generate_fixups);/d' scripts/dtc/livetree.c
                if [[ "$DEVICE_IMPORT" == "gta4l" ]]; then
                    echo "-- Setting up extra drivers as built-in for gta4l..."
                    sed -i 's/^CONFIG_QCA_CLD_WLAN=m$/CONFIG_QCA_CLD_WLAN=y/' arch/arm64/configs/$DEVICE_DEFCONFIG
                    find techpack/data -name "Makefile" -exec sed -i 's/obj-m/obj-y/g' {} +
                    find techpack/audio/config -name "*.conf" -exec sed -i 's/=m/=y/g' {} +
                    find techpack/audio -name "Makefile*" -exec sed -i 's/obj-m/obj-y/g' {} +
                    find techpack/audio -name "Kbuild*" -exec sed -i 's/obj-m/obj-y/g' {} +
                    echo "CONFIG_SENSORS_SSC=y" >> $MAIN_DEFCONFIG
                fi
            fi
        fi
        # Common configs for 4.19
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        ;;
    a9y18qlte)
        echo "-- Reverting KSU commit for a9y18qlte..."
        revert_commit "https://github.com/riarumoda/kernel_samsung_a9y18qlte/commit/6e44d53debc1395d80589eed7657b77f52522c27.patch"
        revert_commit "https://github.com/riarumoda/kernel_samsung_a9y18qlte/commit/ab4abe439587577c1f4cf594fb5179bdb6bd59a6.patch"
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
        ;;
esac