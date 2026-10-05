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

# Feature selectors default to the device config; positional builder arguments override them.
if [[ ! ${BBG_SELECTOR+x} ]]; then
    export BBG_SELECTOR=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].build_flags.bbg_type // "none"' "$JSON_FILE")
fi
if [[ ! ${NOMOUNT_SELECTOR+x} ]]; then
    export NOMOUNT_SELECTOR=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].build_flags.nomount_type // "none"' "$JSON_FILE")
fi
if [[ ! ${DROIDSPACES_SELECTOR+x} ]]; then
    export DROIDSPACES_SELECTOR=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].build_flags.droidspaces_type // "none"' "$JSON_FILE")
fi
if [[ ! ${REKERNEL_SELECTOR+x} ]]; then
    export REKERNEL_SELECTOR=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].build_flags.rekernel_type // "none"' "$JSON_FILE")
fi
if [[ ! ${NETHUNTER_SELECTOR+x} ]]; then
    export NETHUNTER_SELECTOR=$(jq -r --arg t "$DEVICE_IMPORT" '.[$t].build_flags.nethunter_type // "none"' "$JSON_FILE")
fi

# Toolchain Settings
echo "-- Exporting toolchain settings..."
if [[ "$CLANG_STRAT" == "1" ]]; then
    echo "-- Using Neutron Clang to compile the kernel"
    export CLANG_ROOT="$PWD/clang"
    export PATH="$PWD/clang/bin/:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 LD=ld.lld
            CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    )
    if [[ "$GITHUB_TOKEN" == "" ]]; then
        TC_URLS=$(curl -s https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
    else
        TC_URLS=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
    fi
elif [[ "$CLANG_STRAT" == "2" ]]; then
    echo "-- Using AOSP Clang + Eva GCC to compile the kernel"
    export CLANG_ROOT="$PWD/clang"
    export GCC64_ROOT="$PWD/gcc64"
    export GCC32_ROOT="$PWD/gcc32"
    export PATH="$CLANG_ROOT/bin:$GCC64_ROOT/bin:$GCC32_ROOT/bin:/usr/bin:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 CROSS_COMPILE=$GCC64_DIR/bin/aarch64-elf-
            CROSS_COMPILE_COMPAT=$GCC32_DIR/bin/arm-eabi-
    )
    TC_URLS_CLANG=("clang|https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379.git")
    if [[ "$GITHUB_TOKEN" == "" ]]; then
        TC_URLS_GCC64=$(curl -s https://api.github.com/repos/mvaisakh/gcc-build/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep -E "eva-gcc-arm.*\.xz")
    else
        TC_URLS_GCC64=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/mvaisakh/gcc-build/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep -E "eva-gcc-arm.*\.xz")
    fi
elif [[ "$CLANG_STRAT" == "3" ]]; then
    echo "-- Using Playground TC to compile the kernel"
    export CLANG_ROOT="$PWD/clang"
    export PATH="$CLANG_ROOT/bin:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-
            CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    )
    TC_URLS=("https://github.com/basamaryan/kernel_xiaomi_sm6150/releases/download/18/playgroundtc.tar.gz")
else
    echo "-- Using AOSP Clang + Android GCC 4.9 to compile the kernel"
    export CLANG_ROOT="$PWD/clang"
    export GCC64_ROOT="$PWD/gcc64"
    export GCC32_ROOT="$PWD/gcc32"
    export PATH="$CLANG_ROOT/bin:$GCC64_ROOT/bin:$GCC32_ROOT/bin:/usr/bin:$PATH"
    export MAKE_ARGS=(
            ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as
            NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
            CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-androideabi- CROSS_COMPILE_ARM32=arm-linux-androideabi-
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
       		if ! tar -C clang -xf neutron-clang-*.tar.zst 2>/dev/null; then
			echo "-- Error: Extraction failed! The archive might be corrupted." >&2
			echo "-- Cleaning up corrupted files..."
			rm -rf clang neutron-clang-*.tar.zst
			exit 1
		fi
		rm neutron-clang-*.tar.zst
		echo "-- Clang successfully downloaded!"
	else
		echo "-- Using local $dir"
	fi
elif [[ "$CLANG_STRAT" == "2" ]]; then
    for tc in "${TC_URLS_CLANG[@]}"; do
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

    echo "-- Downloading Eva GCC..."
    for url in $TC_URLS_GCC64; do
      wget --content-disposition -qL "$url"
    done
    for file in eva-gcc-arm*.xz; do
      if [[ "$file" == *arm64* ]]; then
        tar -xf "$file" 2>/dev/null
        mv gcc-arm64 gcc64
      else
        tar -xf "$file" 2>/dev/null
        mv gcc-arm gcc32
      fi
      rm -rf "$file"
    done
elif [[ "$CLANG_STRAT" == "3" ]]; then
    echo "-- Downloading Playground TC..."
    for url in $TC_URLS; do
        if [[ "$GITHUB_TOKEN" == "" ]]; then
            wget -q "$url"
        else
            wget --header="Authorization: Bearer $GITHUB_TOKEN" -q "$url"
        fi
    done
    echo "-- Extracting Clang..."
    mkdir -p clang
    if ! tar -C clang -xf playgroundtc.tar.gz 2>/dev/null; then
		echo "-- Error: Extraction failed! The archive might be corrupted." >&2
		echo "-- Cleaning up corrupted files..."
		rm -rf clang playgroundtc.tar.gz
	    exit 1
	fi
    cd clang/
    mv playgroundtc/* .
    cd ..
	rm playgroundtc.tar.gz
	echo "-- Clang successfully downloaded!"
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