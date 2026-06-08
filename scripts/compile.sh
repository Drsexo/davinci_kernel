#!/bin/bash

# Apply O3 flags
if [ "$DEVICE_IMPORT" != "a9y18qlte" ]; then
    echo "-- Applying O3 flags before compiling..."
    sed -i 's/KBUILD_CFLAGS\s\++= -O2/KBUILD_CFLAGS   += -O3/g' Makefile
    sed -i 's/LDFLAGS\s\++= -O2/LDFLAGS += -O3/g' Makefile
fi

# Make sure out folder exist
mkdir -p out &> /dev/null

# Common make command array for readability
MAKE_CMD=(make O=out "${MAKE_ARGS[@]}")

# Setup main defconfig
"${MAKE_CMD[@]}" $ACTUAL_MAIN_DEFCONFIG &> /dev/null

# Append additional configs
echo "-- Appending fragments to .config..."
for fragment in $COMMON_DEFCONFIG $DEVICE_DEFCONFIG $FEATURE_DEFCONFIG; do
    if [ -f "arch/arm64/configs/$fragment" ]; then
        echo "   -> Merging $fragment..."
        cat "arch/arm64/configs/$fragment" >> out/.config
    else
        echo "   -> Warning: Fragment arch/arm64/configs/$fragment not found!"
    fi
done

# Set kernel name
echo "-- Appending kernel name..."
echo "CONFIG_LOCALVERSION=\"$KERNEL_NAME\"" >> out/.config
echo "CONFIG_LOCALVERSION_AUTO=n" >> out/.config

# Config generation
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" olddefconfig &> /dev/null
{ yes "" 2>/dev/null || true; } | "${MAKE_CMD[@]}" syncconfig &> /dev/null

# Warning start banner
echo " "
echo "====================================="
echo " COMPILING PROCESS HAVE BEEN STARTED "
echo "====================================="
echo " "

# Compile the kernel
make -j$(nproc --all) O=out "${MAKE_ARGS[@]}"

# WWarning finish banner
echo " "
echo "======================================"
echo " COMPILING PROCESS HAVE BEEN FINISHED "
echo "======================================"
echo " "