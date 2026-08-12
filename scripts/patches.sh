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
    sweet|davinci|tucana|violet|ginkgo|laurel_sprout|sweet-playground)
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
        # DTB Patches
        if [[ "$DEVICE_IMPORT" == "ginkgo" ]] || [[ "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
            echo "-- Applying DTC patches..."
            apply_patches \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch" \
                "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
        fi
        DTBO_PATCHES=(
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/e517bc363a19951ead919025a560f843c2c03ad3.patch"
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/a62a3b05d0f29aab9c4bf8d15fe786a8c8a32c98.patch"
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/4b89948ec7d610f997dd1dab813897f11f403a06.patch"
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/fade7df36b01f2b170c78c63eb8fe0d11c613c4a.patch"
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/2628183db0d96be8dae38a21f2b09cb10978f423.patch"
            "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/31f4577af3f8255ae503a5b30d8f68906edde85f.patch"
        )
         if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "-- Applying DTB patches..."
            apply_patches "${DTBO_PATCHES[@]}"
        fi
        # LTO and kpatch patches for 4.14
        if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "-- Applying LTO patches..."
            apply_patches "$LTO_PATCH"
            if [[ "$DEVICE_IMPORT" != "d2s" && "$DEVICE_IMPORT" != "d2x" ]]; then
                echo "-- Applying KPATCH patches..."
                apply_patches "$KPATCH_PATCH"
            fi
        fi
        # Allow kernel to compile under new clang versions
        if [[ "$CLANG_STRAT" == "1" ]]; then
            echo "-- Allowing to compile on new AOSP clang..."
            sed -i 's/-Wno-format-security/-Wno-format-security -Wno-enum-conversion -Wno-default-const-init-var-unsafe -Wno-default-const-init-field-unsafe -Wno-implicit-enum-enum-cast/g' Makefile
        fi
        # Compile kernel with -O3
        if [[ "$DEVICE_IMPORT" == "sweet-playground" ]]; then
            echo "-- Applying O3 flags..."
            sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
            sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        fi
        # Common configs for 4.14
        echo "-- Tuning default configs..."
        if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_CC_OPTIMIZE_FOR_SIZE=y" >> $MAIN_DEFCONFIG
            # Set cpu tuning for 4.19
            echo "-- Setting up CPU tuning..."
            if [[ "$DEVICE_IMPORT" == "ginkgo" || "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
                sed -i '$ a\
                KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
            elif [[ "$DEVICE_IMPORT" == "sweet" || "$DEVICE_IMPORT" == "davinci" || "$DEVICE_IMPORT" == "tucana" || "$DEVICE_IMPORT" == "violet" ]]; then
                sed -i '$ a\
                KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
            fi
        fi
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
            # Fix hw key buttons for riva - thx to roman
            sed -i 's/#define FTS_POINT_REPORT_CHECK_EN[[:space:]]*0/#define FTS_POINT_REPORT_CHECK_EN               1/g' techpack/xiaomi-msm8937/touchscreen/focaltech_touch/focaltech_common.h
            sed -i '/input_report_key(input_dev, BTN_TOUCH, 0);/a \
                if (ts_data->key_state) {\
                    struct fts_ts_platform_data *pdata = ts_data->pdata;\
                    int key_idx;\
                    int num_keys = 0;\
                    u32 *keycodes = NULL;\
            \
                if (pdata->key_is_vkeys && pdata->vkeys_pdata) {\
                        num_keys = pdata->vkeys_pdata->num_keys;\
                        keycodes = pdata->vkeys_pdata->keycodes;\
                } else if (!pdata->key_is_vkeys) {\
                        num_keys = pdata->key_number;\
                        keycodes = pdata->keys;\
                }\
            \
                if (keycodes) {\
                        for (key_idx = 0; key_idx < num_keys; key_idx++) {\
                                if (ts_data->key_state & (1 << key_idx))\
                                        input_report_key(input_dev, keycodes[key_idx], 0);\
                        }\
                }\
                ts_data->key_state = 0;\
            }' techpack/xiaomi-msm8937/touchscreen/focaltech_touch/focaltech_point_report_check.c
        fi
        # Set drivers as built-in for 4.19
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
        # Compile kernel with -O3
        if [[ "$DEVICE_IMPORT" == "mi89x7-playground" ]]; then
            echo "-- Applying O3 flags..."
            sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
            sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        fi
        # Set cpu tuning for 4.19
        echo "-- Setting up CPU tuning..."
        if [[ "$DEVICE_IMPORT" == "gta4l" || "$DEVICE_IMPORT" == "mi89x7-playground" ]]; then
            sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        elif [[ "$DEVICE_IMPORT" == "umi" || "$DEVICE_IMPORT" == "cmi" ]]; then
            sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        fi
        # Common configs for 4.19
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        if [[ "$DEVICE_IMPORT" != "mi89x7-playground" ]]; then
            echo "CONFIG_CC_OPTIMIZE_FOR_SIZE=y" >> $MAIN_DEFCONFIG
        fi
        ;;
    tissot-playground-treble|tissot-playground-nontreble)
        # remove hardcoded kernel build user and host on tissot
        if [[ "$DEVICE_IMPORT" == "tissot-playground-treble" || "$DEVICE_IMPORT" == "tissot-playground-nontreble" ]]; then
            echo "-- Removing hardcoded kernel build user and host..."
            sed -i '/LINUX_COMPILE_BY="romi"/d' scripts/mkcompile_h
            sed -i '/LINUX_COMPILE_HOST="build"/d' scripts/mkcompile_h
        fi
        # Set cpu tuning for 4.9
        echo "-- Setting up CPU tuning..."
        if [[ "$DEVICE_IMPORT" == "tissot-playground-nontreble" || "$DEVICE_IMPORT" == "tissot-playground-treble" ]]; then
            sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        fi
        # Common configs for 4.9
        echo "-- Tuning default configs..."
        if [[ "$DEVICE_IMPORT" != "tissot-playground-nontreble" && "$DEVICE_IMPORT" != "tissot-playground-treble" ]]; then
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        fi
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
        ;;
esac