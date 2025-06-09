#!/bin/bash

SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

cd ..
# 引入颜色输出配置
if [ -f "${SCRIPT_DIR_REALPATH}/common_color.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

# 引入 NDK 工具链配置 export ANDROID_NDK_HOME
if [ -f "${SCRIPT_DIR_REALPATH}/common_env.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_env.sh"
else
    echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
    echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME="ANDROID NDK Dev Toolchain."${NC}"
    exit 1
fi

# Android ABI types
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# BUILD OUTPUT
OUTPUT_DIR="$(pwd)/build/output"
mkdir -p "$OUTPUT_DIR"

echo "Building libraries..."

for ABI in "${ABIS[@]}"; do
    echo "------------------------------"
    echo "Building for $ABI..."
    echo "------------------------------"

    BUILD_DIR_ABI="build/android_$ABI"
    mkdir -p "$BUILD_DIR_ABI"
    
    cmake -B $BUILD_DIR_ABI \
          -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
          -DANDROID_ABI=$ABI \
          -DANDROID_PLATFORM=android-21 \
          -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR/$ABI \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_TESTS=OFF \
          -DBUILD_EXAMPLES=OFF \
          .

    cmake --build "$BUILD_DIR_ABI" --config Release --parallel $(nproc)

    cmake --install "$BUILD_DIR_ABI"

    echo "Completed building and installing FFI library for $ABI to $OUTPUT_DIR/$ABI" 
done

echo ""
echo "All FFI library builds completed! Libraries are in $OUTPUT_DIR"
