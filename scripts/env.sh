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
export CLANG_STRAT=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].env.clang_strat // "1"' "$JSON_FILE")

# Toolchain Settings
echo "-- Exporting toolchain settings..."
if [[ "$CLANG_STRAT" == "1" ]]; then
    echo "-- Using new method to compile the kernel (AOSP Clang Only)"
    export CLANG_ROOT="$PWD/clang"
    export PATH="$PWD/clang/bin/:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 LD=ld.lld
            CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    )
    TC_URLS=$(curl -s https://api.github.com/repos/bachnxuan/aosp_clang_mirror/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
else
    echo "-- Using old method to compile the kernel (Clang + GCC64 + GCC32)"
    export CLANG_ROOT="$PWD/clang"
    export GCC64_ROOT="$PWD/gcc64"
    export GCC32_ROOT="$PWD/gcc32"
    export PATH="$CLANG_ROOT/bin:$GCC64_ROOT/bin:$GCC32_ROOT/bin:/usr/bin:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as
            NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
            CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
            CLANG_TRIPLE=aarch64-linux-gnu-
    )
    TC_URLS=(
        "clang|https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git"
        "gcc64|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git"
        "gcc32|https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git"
    )
fi

# Clang and GCC Setup
if [[ "$CLANG_STRAT" == "1" ]]; then
    if [ -d "$PWD/clang" ]; then
        	if [ -z "$(ls -A "$PWD/clang")" ] || [ ! -d "$PWD/clang/bin" ]; then
                	echo "-- Warning: 'clang' directory is empty or incomplete. Cleaning up..."
                	rm -rf "$PWD/clang"
        	fi
	fi

	if [ ! -d "$PWD/clang" ]; then
		echo "-- Downloading Clang..."
                	if ! curl -L -O "$TC_URLS"; then
                        	echo "-- Error: Failed to download Clang from $TC_URLS" >&2
                        	exit 1
                	fi
		echo "-- Extracting Clang..."
        	mkdir -p clang
       		if ! tar -C clang -xf clang-*.tar.gz 2>/dev/null; then
			echo "-- Error: Extraction failed! The archive might be corrupted." >&2
			echo "-- Cleaning up corrupted files..."
			rm -rf clang clang-*.tar.gz
			exit 1
		fi
		rm clang-*.tar.gz
		echo "-- Clang successfully downloaded!"
	else
		echo "-- Using local $dir"
	fi
else
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
fi