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
        # Set drivers as built-in for 4.14
        if [[ "$DEVICE_IMPORT" == "ginkgo" ]] || [[ "$DEVICE_IMPORT" == "laurel_sprout" ]]; then
            echo "-- Setting up drivers as built-in..."
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
            sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
        fi
        # disable ton of drivers for 4.14
        echo "-- Disabling unnecessary drivers..."
        sed -i 's/CONFIG_INPUT_TABLET=y/CONFIG_INPUT_TABLET=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_ACECAD=y/CONFIG_TABLET_USB_ACECAD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_AIPTEK=y/CONFIG_TABLET_USB_AIPTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_GTCO=y/CONFIG_TABLET_USB_GTCO=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_HANWANG=y/CONFIG_TABLET_USB_HANWANG=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_KBTAB=y/CONFIG_TABLET_USB_KBTAB=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_A4TECH=y/CONFIG_HID_A4TECH=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ACRUX=y/CONFIG_HID_ACRUX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_BELKIN=y/CONFIG_HID_BELKIN=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CHERRY=y/CONFIG_HID_CHERRY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CHICONY=y/CONFIG_HID_CHICONY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PRODIKEYS=y/CONFIG_HID_PRODIKEYS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CYPRESS=y/CONFIG_HID_CYPRESS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_DRAGONRISE=y/CONFIG_HID_DRAGONRISE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ELECOM=y/CONFIG_HID_ELECOM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_EZKEY=y/CONFIG_HID_EZKEY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_HOLTEK=y/CONFIG_HID_HOLTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KEYTOUCH=y/CONFIG_HID_KEYTOUCH=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KYE=y/CONFIG_HID_KYE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_UCLOGIC=y/CONFIG_HID_UCLOGIC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WALTOP=y/CONFIG_HID_WALTOP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_GYRATION=y/CONFIG_HID_GYRATION=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TWINHAN=y/CONFIG_HID_TWINHAN=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KENSINGTON=y/CONFIG_HID_KENSINGTON=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_LCPOWER=y/CONFIG_HID_LCPOWER=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_MAGICMOUSE=y/CONFIG_HID_MAGICMOUSE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_MONTEREY=y/CONFIG_HID_MONTEREY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ORTEK=y/CONFIG_HID_ORTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PANTHERLORD=y/CONFIG_HID_PANTHERLORD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PETALYNX=y/CONFIG_HID_PETALYNX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PICOLCD=y/CONFIG_HID_PICOLCD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PLANTRONICS=y/CONFIG_HID_PLANTRONICS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PRIMAX=y/CONFIG_HID_PRIMAX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ROCCAT=y/CONFIG_HID_ROCCAT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SAITEK=y/CONFIG_HID_SAITEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SPEEDLINK=y/CONFIG_HID_SPEEDLINK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SUNPLUS=y/CONFIG_HID_SUNPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_GREENASIA=y/CONFIG_HID_GREENASIA=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SMARTJOYPLUS=y/CONFIG_HID_SMARTJOYPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TIVO=y/CONFIG_HID_TIVO=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TOPSEED=y/CONFIG_HID_TOPSEED=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_THRUSTMASTER=y/CONFIG_HID_THRUSTMASTER=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WACOM=y/CONFIG_HID_WACOM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WIIMOTE=y/CONFIG_HID_WIIMOTE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ZEROPLUS=y/CONFIG_HID_ZEROPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ZYDACRON=y/CONFIG_HID_ZYDACRON=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SKY2=y/CONFIG_SKY2=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SMSC911X=y/CONFIG_SMSC911X=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_AT803X_PHY=y/CONFIG_AT803X_PHY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MICREL_PHY=y/CONFIG_MICREL_PHY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_POWER_RESET_XGENE=y/CONFIG_POWER_RESET_XGENE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SPMI_SIMULATOR=y/CONFIG_SPMI_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150_PMIC_SIMULATOR=y/CONFIG_PM8150_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150B_PMIC_SIMULATOR=y/CONFIG_PM8150B_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150L_PMIC_SIMULATOR=y/CONFIG_PM8150L_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_EHSET_TEST_FIXTURE=y/CONFIG_USB_EHSET_TEST_FIXTURE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_LINK_LAYER_TEST=y/CONFIG_USB_LINK_LAYER_TEST=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_QCOM_DCC_V2=y/CONFIG_QCOM_DCC_V2=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MEDIA_DIGITAL_TV_SUPPORT=y/CONFIG_MEDIA_DIGITAL_TV_SUPPORT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_DRM_ANALOGIX_ANX7625=y/CONFIG_DRM_ANALOGIX_ANX7625=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_DRM_LT_LT9611=y/CONFIG_DRM_LT_LT9611=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_ISP1760=y/CONFIG_USB_ISP1760=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOE=y/CONFIG_PPPOE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPTP=y/CONFIG_PPTP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOL2TP=y/CONFIG_PPPOL2TP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOLAC=y/CONFIG_PPPOLAC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOPNS=y/CONFIG_PPPOPNS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPP_ASYNC=y/CONFIG_PPP_ASYNC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPP_SYNC_TTY=y/CONFIG_PPP_SYNC_TTY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_IP_PNP=y/CONFIG_IP_PNP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_IP_PNP_DHCP=y/CONFIG_IP_PNP_DHCP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD=y/CONFIG_JOYSTICK_XPAD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD_FF=y/CONFIG_JOYSTICK_XPAD_FF=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD_LEDS=y/CONFIG_JOYSTICK_XPAD_LEDS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT=y/CONFIG_CORESIGHT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_LINK_AND_SINK_TMC=y/CONFIG_CORESIGHT_LINK_AND_SINK_TMC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_DYNAMIC_REPLICATOR=y/CONFIG_CORESIGHT_DYNAMIC_REPLICATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_STM=y/CONFIG_CORESIGHT_STM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TPDA=y/CONFIG_CORESIGHT_TPDA=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TPDM=y/CONFIG_CORESIGHT_TPDM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_HWEVENT=y/CONFIG_CORESIGHT_HWEVENT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_DUMMY=y/CONFIG_CORESIGHT_DUMMY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_REMOTE_ETM=y/CONFIG_CORESIGHT_REMOTE_ETM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TGU=y/CONFIG_CORESIGHT_TGU=n/g' $MAIN_DEFCONFIG
        echo "CONFIG_NEW_LEDS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LEDS_CLASS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LEDS_TRIGGERS=y" >> $MAIN_DEFCONFIG
        # Common configs for 4.14
        echo "-- Tuning default configs..."
        if [[ "$DEVICE_IMPORT" != "sweet-playground" ]]; then
            echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
            echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        fi
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CC_OPTIMIZE_FOR_SIZE=y" >> $MAIN_DEFCONFIG
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
        # disable ton of drivers for 4.19
        echo "-- Disabling unnecessary drivers..."
        sed -i 's/CONFIG_INPUT_TABLET=y/CONFIG_INPUT_TABLET=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_ACECAD=y/CONFIG_TABLET_USB_ACECAD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_AIPTEK=y/CONFIG_TABLET_USB_AIPTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_GTCO=y/CONFIG_TABLET_USB_GTCO=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_HANWANG=y/CONFIG_TABLET_USB_HANWANG=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_TABLET_USB_KBTAB=y/CONFIG_TABLET_USB_KBTAB=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_A4TECH=y/CONFIG_HID_A4TECH=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ACRUX=y/CONFIG_HID_ACRUX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_BELKIN=y/CONFIG_HID_BELKIN=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CHERRY=y/CONFIG_HID_CHERRY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CHICONY=y/CONFIG_HID_CHICONY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PRODIKEYS=y/CONFIG_HID_PRODIKEYS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_CYPRESS=y/CONFIG_HID_CYPRESS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_DRAGONRISE=y/CONFIG_HID_DRAGONRISE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ELECOM=y/CONFIG_HID_ELECOM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_EZKEY=y/CONFIG_HID_EZKEY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_HOLTEK=y/CONFIG_HID_HOLTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KEYTOUCH=y/CONFIG_HID_KEYTOUCH=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KYE=y/CONFIG_HID_KYE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_UCLOGIC=y/CONFIG_HID_UCLOGIC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WALTOP=y/CONFIG_HID_WALTOP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_GYRATION=y/CONFIG_HID_GYRATION=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TWINHAN=y/CONFIG_HID_TWINHAN=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_KENSINGTON=y/CONFIG_HID_KENSINGTON=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_LCPOWER=y/CONFIG_HID_LCPOWER=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_MAGICMOUSE=y/CONFIG_HID_MAGICMOUSE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_MONTEREY=y/CONFIG_HID_MONTEREY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ORTEK=y/CONFIG_HID_ORTEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PANTHERLORD=y/CONFIG_HID_PANTHERLORD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PETALYNX=y/CONFIG_HID_PETALYNX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PICOLCD=y/CONFIG_HID_PICOLCD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PLANTRONICS=y/CONFIG_HID_PLANTRONICS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_PRIMAX=y/CONFIG_HID_PRIMAX=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ROCCAT=y/CONFIG_HID_ROCCAT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SAITEK=y/CONFIG_HID_SAITEK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SPEEDLINK=y/CONFIG_HID_SPEEDLINK=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SUNPLUS=y/CONFIG_HID_SUNPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_GREENASIA=y/CONFIG_HID_GREENASIA=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_SMARTJOYPLUS=y/CONFIG_HID_SMARTJOYPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TIVO=y/CONFIG_HID_TIVO=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_TOPSEED=y/CONFIG_HID_TOPSEED=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_THRUSTMASTER=y/CONFIG_HID_THRUSTMASTER=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WACOM=y/CONFIG_HID_WACOM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_WIIMOTE=y/CONFIG_HID_WIIMOTE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ZEROPLUS=y/CONFIG_HID_ZEROPLUS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_HID_ZYDACRON=y/CONFIG_HID_ZYDACRON=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SKY2=y/CONFIG_SKY2=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SMSC911X=y/CONFIG_SMSC911X=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_AT803X_PHY=y/CONFIG_AT803X_PHY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MICREL_PHY=y/CONFIG_MICREL_PHY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_POWER_RESET_XGENE=y/CONFIG_POWER_RESET_XGENE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_SPMI_SIMULATOR=y/CONFIG_SPMI_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150_PMIC_SIMULATOR=y/CONFIG_PM8150_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150B_PMIC_SIMULATOR=y/CONFIG_PM8150B_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PM8150L_PMIC_SIMULATOR=y/CONFIG_PM8150L_PMIC_SIMULATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_EHSET_TEST_FIXTURE=y/CONFIG_USB_EHSET_TEST_FIXTURE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_LINK_LAYER_TEST=y/CONFIG_USB_LINK_LAYER_TEST=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_QCOM_DCC_V2=y/CONFIG_QCOM_DCC_V2=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_MEDIA_DIGITAL_TV_SUPPORT=y/CONFIG_MEDIA_DIGITAL_TV_SUPPORT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_DRM_ANALOGIX_ANX7625=y/CONFIG_DRM_ANALOGIX_ANX7625=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_DRM_LT_LT9611=y/CONFIG_DRM_LT_LT9611=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_USB_ISP1760=y/CONFIG_USB_ISP1760=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOE=y/CONFIG_PPPOE=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPTP=y/CONFIG_PPTP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOL2TP=y/CONFIG_PPPOL2TP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOLAC=y/CONFIG_PPPOLAC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPPOPNS=y/CONFIG_PPPOPNS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPP_ASYNC=y/CONFIG_PPP_ASYNC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_PPP_SYNC_TTY=y/CONFIG_PPP_SYNC_TTY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_IP_PNP=y/CONFIG_IP_PNP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_IP_PNP_DHCP=y/CONFIG_IP_PNP_DHCP=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD=y/CONFIG_JOYSTICK_XPAD=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD_FF=y/CONFIG_JOYSTICK_XPAD_FF=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_JOYSTICK_XPAD_LEDS=y/CONFIG_JOYSTICK_XPAD_LEDS=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT=y/CONFIG_CORESIGHT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_LINK_AND_SINK_TMC=y/CONFIG_CORESIGHT_LINK_AND_SINK_TMC=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_DYNAMIC_REPLICATOR=y/CONFIG_CORESIGHT_DYNAMIC_REPLICATOR=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_STM=y/CONFIG_CORESIGHT_STM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TPDA=y/CONFIG_CORESIGHT_TPDA=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TPDM=y/CONFIG_CORESIGHT_TPDM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_HWEVENT=y/CONFIG_CORESIGHT_HWEVENT=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_DUMMY=y/CONFIG_CORESIGHT_DUMMY=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_REMOTE_ETM=y/CONFIG_CORESIGHT_REMOTE_ETM=n/g' $MAIN_DEFCONFIG
        sed -i 's/CONFIG_CORESIGHT_TGU=y/CONFIG_CORESIGHT_TGU=n/g' $MAIN_DEFCONFIG
        echo "CONFIG_NEW_LEDS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LEDS_CLASS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LEDS_TRIGGERS=y" >> $MAIN_DEFCONFIG
        # Common configs for 4.19
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CC_OPTIMIZE_FOR_SIZE=y" >> $MAIN_DEFCONFIG
        ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
        ;;
esac