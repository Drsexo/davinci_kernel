#!/bin/bash
echo "- Setting up build environment..."

# Find the device configuration file
JSON_FILE="devices.json"
if [ ! -f "$JSON_FILE" ]; then
    if [ -f "../devices/weekly.json" ] && jq -e --arg t "$DEVICE_IMPORT" '.[$t]' ../devices/weekly.json &>/dev/null; then
        JSON_FILE="../devices/weekly.json"
    elif [ -f "../devices/playground.json" ] && jq -e --arg t "$DEVICE_IMPORT" '.[$t]' ../devices/playground.json &>/dev/null; then
        JSON_FILE="../devices/playground.json"
    else
        echo "-- Fatal: No valid device configuration found for $DEVICE_IMPORT!"
        exit 1
    fi
fi

# Device Settings parsed dynamically from JSON
echo "-- Exporting device settings for $DEVICE_IMPORT from $JSON_FILE..."
export KBUILD_BUILD_USER=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.kbuild_build_user // "riarumoda-compile"' "$JSON_FILE")
export KBUILD_BUILD_HOST="riaru.com"
export KERNEL_NAME=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.kernel_name // "-perf-neon"' "$JSON_FILE")
export KERNEL_VERSION=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.kernel_version // "4.14"' "$JSON_FILE")
export MAIN_DEFCONFIG=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.main_defconfig // "arch/arm64/configs/vendor/sdmsteppe-perf_defconfig"' "$JSON_FILE")
export ACTUAL_MAIN_DEFCONFIG=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.actual_main_defconfig // "vendor/sdmsteppe-perf_defconfig"' "$JSON_FILE")
export COMMON_DEFCONFIG=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.common_defconfig // "vendor/debugfs.config"' "$JSON_FILE")
export DEVICE_DEFCONFIG=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.device_defconfig // ""' "$JSON_FILE")
export FEATURE_DEFCONFIG=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.feature_defconfig // ""' "$JSON_FILE")

# Toolchain Settings
echo "-- Exporting toolchain settings..."
export CLANG_ROOT="$PWD/clang"
export GCC64_ROOT="$PWD/gcc64"
export GCC32_ROOT="$PWD/gcc32"
export PATH="$CLANG_ROOT/bin:$GCC64_ROOT/bin:$GCC32_ROOT/bin:/usr/bin:$PATH"
export MAKE_ARGS=(
        ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as
        NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
        CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
        CLANG_TRIPLE=aarch64-linux-gnu-
)
TC_URLS=(
    "clang|https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git"
    "gcc64|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git"
    "gcc32|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git"
)

# Clang and GCC Setup
for tc in "${TC_URLS[@]}"; do
    dir="${tc%%|*}"; url="${tc##*|}"
    if [[ "$url" == *.git ]]; then
        if [ ! -d "$dir/.git" ]; then
            echo "-- Cloning $dir..."
            rm -rf "$dir"
            git clone "$url" --depth=1 "$dir" &> /dev/null || { echo "-- Fatal: Failed to clone $dir!"; exit 1; }
        else
            echo "-- Using local $dir"
        fi
    fi
done