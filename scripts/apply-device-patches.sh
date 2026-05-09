#!/bin/bash
echo "- Applying device specific patches for $DEVICE_IMPORT..."

# Patcher helper - 1.5
apply_patches() {
    for patch_url in "$@"; do
        echo "-- Downloading patch: $(basename "$patch_url")"
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
DTBO_PATCHES=(
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/e517bc363a19951ead919025a560f843c2c03ad3.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/a62a3b05d0f29aab9c4bf8d15fe786a8c8a32c98.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/4b89948ec7d610f997dd1dab813897f11f403a06.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/fade7df36b01f2b170c78c63eb8fe0d11c613c4a.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/2628183db0d96be8dae38a21f2b09cb10978f423.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/31f4577af3f8255ae503a5b30d8f68906edde85f.patch"
)
LTO_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/fix_lto.patch"
KPATCH_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"

# Patcher - 1.0
case "$DEVICE_IMPORT" in
    sweet|davinci|tucana|violet|ginkgo|laurel_sprout|sweet-pixelos|sweet-miui)
        # Device specific for 4.14
        if [[ "$DEVICE_IMPORT" == "sweet" ]] || [[ "$DEVICE_IMPORT" == "sweet-pixelos" ]]; then
            echo "-- Applying LN8K patches..."
            LN8K_PATCHES=(
                "https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/7b73f853977d2c016e30319dffb1f49957d30b40.patch"
                "https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/63dddc108d57dc43e1cd0da0f1445875f760cf97.patch"
                "https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/95816dff2ecc7ddd907a56537946b5cf1e864953.patch"
                "https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/330c60abc13530bd05287f9e5395d283ebfd6d0b.patch"
                "https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/0477c7006b41a1763b3314af9eb300491b91fc25.patch"
            )
            if [[ "$DEVICE_IMPORT" != "sweet-pixelos" ]]; then
                LN8K_PATCHES+=(
                    "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/aa5ddad5be03aa7436e7ce6e84d46b280849acae.patch"
                    "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/857638b0da6f80830122b8d1b45c7842970e76c3.patch"
                    "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/3a68adff14cbedd09ce2a735d575c3bf92dd696f.patch"
                    "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/30fcc15d5dcf2cfc3b83a5a7d4a77e2880639fa5.patch"
                    "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/1a17a6fbbf59d901c4b3aec66c06a1c96cd89c7e.patch"
                )
            fi
            apply_patches "${LN8K_PATCHES[@]}"
            echo "CONFIG_CHARGER_LN8000=y" >> $MAIN_DEFCONFIG
        elif [[ "$DEVICE_IMPORT" == "ginkgo" ]] || [[ "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
            echo "-- Applying DTC patches..."
            apply_patches \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch" \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
        fi
        # DTBO patches for 4.14
        if [[ "$DEVICE_IMPORT" != "sweet-pixelos" ]]; then
            echo "-- Applying DTBO & LTO patches..."
            apply_patches "${DTBO_PATCHES[@]}" "$LTO_PATCH"
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        fi
        # Specific patches for sweet-miui
        if [[ "$DEVICE_IMPORT" == "sweet-miui" ]]; then
            echo "-- reverting some commits for sweet-miui..."
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/1c11ea4f8b8b0b0c7ae0ed106ff28893c7a7a12e.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/2b611d2835e5d258edacdaef2a1b6ad5ba60c3e9.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/ef37930c349076b13903dcfa9db72677060e1eed.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/51a7e49fd8273935779105310efa1c9845963811.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/1759fb3df25b760b567f1633a39d99164decbbac.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/b1ea3a2d183015389d00537cdd48b5d69e98312c.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/4bdfb496b0e6debee10d35bdf62b6f2cfa10845a.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/da831854a80d63914b32f3dec286065f8ee00998.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/e2b3c607add77513068e3d917efb7f4786004a61.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/f9d16e866c476d902120531bb9c710eb9e7d4e6c.patch"
            revert_commit "https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/3b5ce8d2647ca26976f878220ea33f9d78f8c109.patch"
        fi
        # Shared patches for 4.14
        echo "-- Applying shared patches (KPATCH)..."
        apply_patches "$KPATCH_PATCH"
        # Common configs for 4.14
        echo "-- Tuning default configs..."
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        ;;
    alioth|lmi|munch|mi89x7|mi89x7-community)
        # Device specific for 4.19
        if [[ "$DEVICE_IMPORT" == "alioth" ]] || [[ "$DEVICE_IMPORT" == "lmi" ]] || [[ "$DEVICE_IMPORT" == "munch" ]]; then
            # Shared patches for 4.14
            echo "-- Applying shared patches (DTBO)..."
            apply_patches "${DTBO_PATCHES[@]}"
        fi
        if [[ "$DEVICE_IMPORT" == "mi89x7-community" ]]; then
            # Revert KSU commit for mi89x7-community
            echo "-- Reverting KSU commit for mi89x7-community..."
            revert_commit "https://github.com/Mi-Thorium/kernel_msm-4.19/commit/624875e8edc36ae280b1f8efc1d3c48a28da64ea.patch"
        fi
        # Common configs for 4.19
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        ;;
    a9y18qlte)
        echo "-- Reverting KSU commit for a9y18qlte..."
        revert_commit "https://github.com/riarumoda/kernel_samsung_a9y18qlte/commit/6e44d53debc1395d80589eed7657b77f52522c27.patch"
        revert_commit "https://github.com/riarumoda/kernel_samsung_a9y18qlte/commit/ab4abe439587577c1f4cf594fb5179bdb6bd59a6.patch"
        ;;
    a52s)
        echo "-- STUB Entry for a52s. Nothing added yet."
        ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
        ;;
esac