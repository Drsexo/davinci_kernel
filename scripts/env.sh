#!/bin/bash
echo "- Setting up build environment..."

# Device Default Exports
echo "-- Exporting device settings..."
export KBUILD_BUILD_USER=drsexo-compile
export KBUILD_BUILD_HOST=drsexo
export KERNEL_NAME="-Nebula_ReSukiSU"
export KERNEL_VERSION="4.14"

# PixelOS ships davinci as one standalone defconfig, no vendor/ fragment to merge
if [ "$ROM_IMPORT" = "pixelos" ]; then
    export MAIN_DEFCONFIG="arch/arm64/configs/davinci_defconfig"
    export ACTUAL_MAIN_DEFCONFIG="davinci_defconfig"
    export COMMON_DEFCONFIG=""
    export DEVICE_DEFCONFIG=""
else
    export MAIN_DEFCONFIG="arch/arm64/configs/vendor/sdmsteppe-perf_defconfig"
    export ACTUAL_MAIN_DEFCONFIG="vendor/sdmsteppe-perf_defconfig"
    export COMMON_DEFCONFIG="vendor/debugfs.config"
    export DEVICE_DEFCONFIG="vendor/davinci.config"
fi
export FEATURE_DEFCONFIG=""

# Clang settings (Neutron Toolchains, latest tag, cached by tag)
echo "-- Exporting toolchain settings..."
export CLANG_ROOT="$PWD/clang"
export PATH="$CLANG_ROOT/bin:/usr/bin:$PATH"
export MAKE_ARGS=(
        ARCH=arm64 LLVM=1 LLVM_IAS=1 CC="ccache clang" LD=ld.lld AR=llvm-ar AS=llvm-as
        NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
        CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
        KCFLAGS="-Wno-implicit-enum-enum-cast -Wno-default-const-init-unsafe"
)

NEUTRON_REPO="Neutron-Toolchains/clang-build-catalogue"

if [[ -x "$CLANG_ROOT/bin/clang" && -f "$CLANG_ROOT/build.info" ]]; then
    echo "-- Using cached Neutron clang at $CLANG_ROOT (tag $(cat "$CLANG_ROOT/build.info"))"
else
    echo "-- Fetching latest Neutron clang tag..."
    NEUTRON_TAG=$(curl -fsSL "https://raw.githubusercontent.com/${NEUTRON_REPO}/main/latest.txt" \
                  | grep -A1 '^\[tag\]' | tail -n1 | tr -d '[:space:]')
    if [[ -z "$NEUTRON_TAG" ]]; then
        echo "-- Fatal: Failed to fetch latest Neutron tag!"
        exit 1
    fi
    echo "-- Latest tag: $NEUTRON_TAG"

    NEUTRON_TARBALL="neutron-clang-${NEUTRON_TAG}.tar.zst"
    NEUTRON_URL="https://github.com/${NEUTRON_REPO}/releases/download/${NEUTRON_TAG}/${NEUTRON_TARBALL}"

    rm -rf "$CLANG_ROOT"
    mkdir -p "$CLANG_ROOT"

    echo "-- Downloading $NEUTRON_TARBALL ..."
    curl -fL --retry 3 -o "$NEUTRON_TARBALL" "$NEUTRON_URL" \
        || { echo "-- Fatal: Failed to download Neutron tarball!"; exit 1; }

    echo "-- Extracting..."
    tar -I zstd -xf "$NEUTRON_TARBALL" -C "$CLANG_ROOT" \
        || { echo "-- Fatal: Failed to extract Neutron tarball!"; exit 1; }

    if [[ ! -x "$CLANG_ROOT/bin/clang" ]]; then
        nested=$(find "$CLANG_ROOT" -maxdepth 1 -type d -name "neutron-clang-*" | head -n1)
        if [[ -n "$nested" && -x "$nested/bin/clang" ]]; then
            mv "$nested"/* "$CLANG_ROOT"/ 2>/dev/null || true
            mv "$nested"/.[!.]* "$CLANG_ROOT"/ 2>/dev/null || true
            rmdir "$nested" 2>/dev/null || true
        fi
    fi

    [[ -x "$CLANG_ROOT/bin/clang" ]] \
        || { echo "-- Fatal: clang binary not found after extraction!"; exit 1; }

    rm -f "$NEUTRON_TARBALL"
    echo "$NEUTRON_TAG" > "$CLANG_ROOT/build.info"
    echo "-- Neutron clang tag $NEUTRON_TAG installed at $CLANG_ROOT"
fi

"$CLANG_ROOT/bin/clang" --version \
    || { echo "-- Fatal: clang not executable after setup!"; exit 1; }