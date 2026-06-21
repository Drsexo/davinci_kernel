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
    sweet|sweet-playground|davinci|tucana|violet|ginkgo|laurel_sprout|a52q|a72q|d2s|d2x)
        # Device specific for 4.14
        if [[ "$DEVICE_IMPORT" == "sweet" ]] || [[ "$DEVICE_IMPORT" == "sweet-playground" ]]; then
            echo "-- Applying LN8K patches..."
            LN8K_PATCHES=(
                "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/05d8eac3722dcf920b716908d910ee704a77950e.patch"
                "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/eb3509401751b1e90a9b42e2f51326f2ef943af3.patch"
                "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/785c8f7976798acfc5cf300a320a43b3f39bcb13.patch"
                "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/e26ba40f3fac0238e410f8a29fa72aac012d75d2.patch"
                "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/6e50130d7bc99d1cc64196541af7a1780a703253.patch"
            )
            apply_patches "${LN8K_PATCHES[@]}"
            echo "CONFIG_CHARGER_LN8000=y" >> $MAIN_DEFCONFIG
        fi
        if [[ "$DEVICE_IMPORT" == "ginkgo" ]] || [[ "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
            echo "-- Applying DTC patches..."
            apply_patches \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch" \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
        fi
        # LTO and kpatch patches for 4.14
        if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "-- Applying LTO patches..."
            apply_patches "$LTO_PATCH"
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
            if [[ "$DEVICE_IMPORT" != "d2s" && "$DEVICE_IMPORT" != "d2x" ]]; then
                echo "-- Applying KPATCH patches..."
                apply_patches "$KPATCH_PATCH"
            fi
        fi
        # Common configs for 4.14
        echo "-- Tuning default configs..."
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        ;;
    umi|cmi|mi89x7-playground|gta4l)
        # Device specific for 4.19
        if [[ "$DEVICE_IMPORT" == "mi89x7-playground" ]]; then
            # Revert KSU commit
            echo "-- Reverting KSU commit..."
            revert_commit "https://github.com/Mi-Thorium/kernel_msm-4.19/commit/624875e8edc36ae280b1f8efc1d3c48a28da64ea.patch"
        fi
        if [[ "$DEVICE_IMPORT" == "gta4l" ]]; then
            echo "-- Disabling a dtb..."
            sed -i '/P85946-qrd-overlay\.dtbo/s/^/# /' arch/arm64/boot/dts/vendor/qcom/Makefile
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