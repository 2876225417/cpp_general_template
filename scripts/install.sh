#!/bin/bash

SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

cd ../

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR_REALPATH}/common_color.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

FFI_LIBS_INSTALL_DIR_BASE="$(pwd)/build/output"

CUSTOM_OPENCV_INSTALL_DIR_BASE="$(pwd)/3rdparty/opencv"

CUSTOM_ONNXRUNTIME_INSTALL_DIR_BASE="$(pwd)/3rdparty/onnxruntime"

JNILIBS_DIR_FLUTTER_PROJECT="$(pwd)/../android/app/src/main/jniLibs"

ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

FFI_LIB_NAME="qwq_books_native"

echo -e "${BYELLOW}--- Starting installation of .so files to $JNILIBS_DIR_FLUTTER_PROJECT  ---${NC}"
mkdir -p "$JNILIBS_DIR_FLUTTER_PROJECT"

for ABI in "${ABIS[@]}"; do
    echo -e "${YELLOW}-----------------------------------${NC}"
    echo -e "${YELLOW}--- Installing for ABI: $ABI... ---${NC}"
    echo -e "${YELLOW}-----------------------------------${NC}"
    TARGET_ABI_JNI_DIR="$JNILIBS_DIR_FLUTTER_PROJECT/$ABI"
    mkdir -p "$TARGET_ABI_JNI_DIR"

    FFI_LIB_SOURCE_PATH="$FFI_LIBS_INSTALL_DIR_BASE/$ABI/lib/lib${FFI_LIB_NAME}.so"
    if [ -f "$FFI_LIB_SOURCE_PATH" ]; then
        echo -e "${YELLOW}--- Copying $FFI_LIB_SOURCE_PATH to $TARGET_ABI_JNI_DIR/ ---${NC}"
        cp -v "$FFI_LIB_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo -e "${BRED}Warning: FFI Library lib${FFI_LIB_NAME}.so NOT FOUND for $ABI at $FFI_LIB_SOURCE_PATH ${NC}" >&2
    fi

    OPENCV_LIB_SOURCE_PATH="${CUSTOM_OPENCV_INSTALL_DIR_BASE}/opencv_android_${ABI}/sdk/native/libs/${ABI}/libopencv_world.so"
    if [ -f "$OPENCV_LIB_SOURCE_PATH" ]; then
        echo -e "${YELLOW}--- Copying $OPENCV_LIB_SOURCE_PATH to $TARGET_ABI_JNI_DIR/ ---${NC}"
        cp -v "$OPENCV_LIB_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo -e "${BRED} Warning: libopencv_world.so NOT FOUND for $ABI at $OPENCV_LIB_SOURCE_PATH ${NC}" >&2
    fi
    
    OPENCV_LIB_MISC_SOURCE_PATH="${CUSTOM_OPENCV_INSTALL_DIR_BASE}/opencv_android_${ABI}/sdk/native/libs/${ABI}/libopencv_img_hash.so"
    if [ -f "$OPENCV_LIB_SOURCE_PATH" ]; then
        echo -e "${YELLOW}--- Copying $OPENCV_LIB_MISC_SOURCE_PATH to $TARGET_ABI_JNI_DIR/ --- ${NC}"
        cp -v "$OPENCV_LIB_MISC_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo -e "${BRED} Warning: libopencv_img_hash.so NOT FOUND for $ABI at $OPENCV_LIB_SOURCE_PATH ${NC}" >&2
    fi

    ONNXRUNTIME_LIB_SOURCE_PATH="${CUSTOM_ONNXRUNTIME_INSTALL_DIR_BASE}/onnxruntime_android_${ABI}/lib/libonnxruntime.so"
    if [ -f "$ONNXRUNTIME_LIB_SOURCE_PATH" ]; then
        echo -e "${YELLOW}--- Copying $ONNXRUNTIME_LIB_SOURCE_PATH to $TARGET_ABI_JNI_DIR/ ---${NC}"
        cp -v "$ONNXRUNTIME_LIB_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo -e "${BRED} Warning: libonnxruntime.so NOT FOUND for $ABI at $ONNXRUNTIME_LIB_SOURCE_PATH ${NC}" >&2
    fi
done

echo -e ""
echo -e "${YELLOW}=========================================================================${NC}"
echo -e "${YELLOW}Installation to jniLibs completed!${NC}"
echo -e "${YELLOW}=========================================================================${NC}"
