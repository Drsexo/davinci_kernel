#!/bin/bash

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
DTBO_PATCHES=(
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/e517bc363a19951ead919025a560f843c2c03ad3.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/a62a3b05d0f29aab9c4bf8d15fe786a8c8a32c98.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/4b89948ec7d610f997dd1dab813897f11f403a06.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/fade7df36b01f2b170c78c63eb8fe0d11c613c4a.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/2628183db0d96be8dae38a21f2b09cb10978f423.patch"
    "https://github.com/xiaomi-sm6150/android_kernel_xiaomi_sm6150/commit/31f4577af3f8255ae503a5b30d8f68906edde85f.patch"
)
DTC_PATCHES=(
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/e207247aa4553fff7190dde5dabb50aec400b513.patch"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/ae58bbd8f7af4c3c290e63ddcd4112559c5fc240.patch"
)
LN8K_COMMON=(
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/b2098690243086601ca394b4bcd5fb4e94ce68ec.patch"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/33214bb2481d3279764f14fbb4b84d329be95410.patch"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/c6b5c9eff5fc9e07580ed8d75bd52caf396021aa.patch"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/95d285024e700545e0d44d5683615b7285063f25.patch"
)
LN8K_EXTRA="https://github.com/LineageOS/android_kernel_xiaomi_sm6150/commit/9e8d4be7a3e2868491486ac86c9e5aa52a5a0c53.patch"

# Patcher - 1.5
case "$DEVICE_IMPORT" in
    # LineageOS
    sweet-lineage|davinci-lineage|tucana-lineage|violet-lineage)
        echo "-- Applying DTB patches..."
        apply_patches "${DTBO_PATCHES[@]}"
        echo "-- Applying LTO patches..."
        apply_patches "$LTO_PATCH"
        echo "-- Applying KPATCH patches..."
        apply_patches "$KPATCH_PATCH"
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    ginkgo-lineage|laurel_sprout-lineage)
        echo "-- Applying DTC patches..."
        apply_patches "${DTC_PATCHES[@]}"
        echo "-- Applying DTB patches..."
        apply_patches "${DTBO_PATCHES[@]}"
        echo "-- Applying LTO patches..."
        apply_patches "$LTO_PATCH"
        echo "-- Applying KPATCH patches..."
        apply_patches "$KPATCH_PATCH"
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_EROFS_FS=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    gta4l-lineage)
        echo "-- Fixing scripts/dtc/livetree.c..."
        sed -i '/assert(generate_fixups);/d' scripts/dtc/livetree.c
        echo "-- Setting up extra drivers as built-in for gta4l..."
        sed -i 's/^CONFIG_QCA_CLD_WLAN=m$/CONFIG_QCA_CLD_WLAN=y/' arch/arm64/configs/$DEVICE_DEFCONFIG
        find techpack/data -name "Makefile" -exec sed -i 's/obj-m/obj-y/g' {} +
        find techpack/audio/config -name "*.conf" -exec sed -i 's/=m/=y/g' {} +
        find techpack/audio -name "Makefile*" -exec sed -i 's/obj-m/obj-y/g' {} +
        find techpack/audio -name "Kbuild*" -exec sed -i 's/obj-m/obj-y/g' {} +
        echo "CONFIG_SENSORS_SSC=y" >> $MAIN_DEFCONFIG
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    # CrDroid
    sweet-crdroid|davinci-crdroid|tucana-crdroid)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 78088ffb401b570b8de9408662c8fc931e9cf1a5 &> /dev/null
        if [[ "$DEVICE_IMPORT" == "tucana-crdroid" ]]; then
            echo "-- Fixing goodix driver..."
            sed -i 's/static void gtp_set_edge_filter_normal()/static void gtp_set_edge_filter_normal(void)/g' drivers/input/touchscreen/f4_goodix_driver_gt9886/goodix_ts_core.c
            sed -i 's/static int gtp_send_cur_cmd()/static int gtp_send_cur_cmd(void)/g' drivers/input/touchscreen/f4_goodix_driver_gt9886/goodix_ts_core.c
            echo "-- Fixing fts driver..."
            sed -i 's/"%100s %d %d"/"%99s %d %d"/g' drivers/input/touchscreen/fts_521/fts.c
            sed -i 's/"%100s"/"%99s"/g' drivers/input/touchscreen/fts_521/fts_proc.c
            sed -i 's/struct device \*getDev()/struct device \*getDev(void)/g' drivers/input/touchscreen/fts_521/fts_lib/ftsIO.c
            sed -i 's/struct i2c_client \*getClient()/struct i2c_client \*getClient(void)/g' drivers/input/touchscreen/fts_521/fts_lib/ftsIO.c
            echo "ccflags-y += -Wno-strict-prototypes" >> drivers/input/touchscreen/fts_521/Makefile
        fi
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    # PixelOS
    sweet-playground)
        echo "-- Applying LN8K patches..."
        apply_patches "${LN8K_COMMON[@]}"
        wget -qO- "$LN8K_EXTRA" | filterdiff -x a/drivers/power/supply/qcom/smb5-lib.c | patch -s -p1
        echo "CONFIG_CHARGER_LN8000=y" >> $MAIN_DEFCONFIG
        echo "-- Applying O3 flags..."
        sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
        sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
    ;;
    # Mi-Thorium
    mi89x7-playground)
        echo "-- Reverting KSU commit..."
        revert_commit "https://github.com/Mi-Thorium/kernel_msm-4.19/commit/624875e8edc36ae280b1f8efc1d3c48a28da64ea.patch"
        echo "-- Fixing HW key for riva..."
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
        echo "-- Applying O3 flags..."
        sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
        sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
    ;;
    # Other devices
    umi|cmi)
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    # Another Kernels
    tissot-playground-treble|tissot-playground-nontreble)
        echo "-- Removing hardcoded kernel build user and host..."
        sed -i '/LINUX_COMPILE_BY="romi"/d' scripts/mkcompile_h
        sed -i '/LINUX_COMPILE_HOST="build"/d' scripts/mkcompile_h
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
    ;;
    # Titanium
    mi8953-titanium-playground)
        echo "-- Reverting KSU Commits..."
        revert_commit "https://github.com/imren0x/msm-4.19/commit/054db634954f3ab6ffe1d7aea505c1d851eee24c.patch"
        revert_commit "https://github.com/imren0x/msm-4.19/commit/03cf4fbc3bb64353be356b143aacac9efe6c09a3.patch"
        revert_commit "https://github.com/imren0x/msm-4.19/commit/4c708b3ce7f7773b733c55ba2c9a587133d2ab7c.patch"
        echo "-- Fixing msm clk broken redifinition..."
        sed -i 's/static inline void clk_debug_print_hw.*/void clk_debug_print_hw(struct clk *clk, struct seq_file *f);/' include/linux/clk/msm-clk-provider.h
        sed -i '/static inline int clock_debug_register/,/}/c\int clock_debug_register(struct clk *clk);' drivers/clk/msm/clock.h
        sed -i '/static inline void clock_debug_print_enabled.*/c\void clock_debug_print_enabled(bool print_parent);' drivers/clk/msm/clock.h
        echo "-- Applying O3 flags..."
        sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
        sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a53' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_LTO_CLANG=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_THINLTO=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_SHADOW_CALL_STACK=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
    ;;
    # Spiteful MIUI Buildout
    spiteful-sweet-miui-buildout)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 1c950660849776c0105ae268270acb590d1df308 &> /dev/null
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        echo "-- Completely disabling LTO..."
        sed -i \
            -e 's/^CONFIG_LTO=y/# CONFIG_LTO is not set/' \
            -e 's/^CONFIG_THINLTO=y/# CONFIG_THINLTO is not set/' \
            -e 's/^CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/' \
            -e 's/^# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/' \
            $MAIN_DEFCONFIG
        echo "-- Applying O3 flags..."
        sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
        sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    # Spiteful AOSP Buildout
    spiteful-sweet-aosp-buildout)
        echo "-- Reverting hard to commits before KSU is being added..."
        git reset --hard 1b133f3054948bee6c59332c83699ff2b95d7978 &> /dev/null
        echo "-- Setting up mtune..."
        sed -i '$ a\
            KBUILD_CFLAGS += -mtune=cortex-a55' Makefile
        echo "-- Completely disabling LTO..."
        sed -i \
            -e 's/^CONFIG_LTO=y/# CONFIG_LTO is not set/' \
            -e 's/^CONFIG_THINLTO=y/# CONFIG_THINLTO is not set/' \
            -e 's/^CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/' \
            -e 's/^# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/' \
            $MAIN_DEFCONFIG
        echo "-- Applying O3 flags..."
        sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
        sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
        echo "-- Tuning default configs..."
        echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_KALLSYMS_ALL=y" >> $MAIN_DEFCONFIG
        echo "CONFIG_CHECKPOINT_RESTORE=y" >> $MAIN_DEFCONFIG
    ;;
    *)
        echo "No specific patches to apply for $DEVICE_IMPORT."
    ;;
esac

if [[ "$CLANG_STRAT" == "1" ]]; then
    echo "- Allowing to compile on new AOSP clang..."
    sed -i 's/-Wno-format-security/-Wno-format-security -Wno-enum-conversion -Wno-default-const-init-var-unsafe -Wno-default-const-init-field-unsafe -Wno-implicit-enum-enum-cast/g' Makefile
fi