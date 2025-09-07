#!/bin/zsh

set -e

# 构建脚本自身所在目录
SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

# 引入 git 配置
COMMON_GIT_SCRIPT="${SCRIPT_DIR_REALPATH}/common_git.sh" 
if [ -f "$COMMON_GIT_SCRIPT" ]; then 
    source "$COMMON_GIT_SCRIPT" 
else
    echo "Error: common_git.sh not found at $COMMON_GIT_SCRIPT" >&2
    exit 1
fi

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR_REALPATH}/common_color.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

# 引入 NDK 工具链配置 
if [ -f "${SCRIPT_DIR_REALPATH}/common_env.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_env.sh"
    if [ $? -ne 0 ] || [ -z "$ANDROID_NDK_HOME" ] || [ -z "$ANDROID_SDK_HOME" ]; then
        echo -e "${BRED}Error: NDK or SDK path not set by common_ndk.sh ${NC}" >&2
        exit 1
    fi
else
    echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
    echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME="ANDROID NDK Dev Toolchain."${NC}"
    exit 1
fi

# 配置 ONNXRuntime 版本 (默认最新 master)
ONNXRUNTIME_VERSION="v1.22.0" # 或者其他目标版本 如 "v1.20.0"

# 脚本目录
SCRIPT_BASE_DIR="$(pwd)"

# 源码克隆路径
ONNXRUNTIME_SOURCE_PARENT_DIR="${SCRIPT_BASE_DIR}/source/onnxruntime"
ONNXRUNTIME_REPO_NAME="onnxruntime"
ONNXRUNTIME_SOURCE_DIR_FULL_PATH="${ONNXRUNTIME_SOURCE_PARENT_DIR}/${ONNXRUNTIME_REPO_NAME}"

# 安装和构建路径
ONNXRUNTIME_INSTALL_ROOT_DIR="${SCRIPT_BASE_DIR}/onnxruntime"
ONNXRUNTIME_BUILD_CONFIG="MinSizeRel"   # Or Release, RelWithDebInfo
ONNXRUNTIME_HOST_BUILD_CONFIG="Release"

ABIS_TO_BUILD=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
DEFAULT_ANDROID_API="24"

HOST_TAG="linux-x86_64"

# ---- 准备源码 ----
echo -e "${YELLOW}--- Preparing ONNXRuntime source directories under: $ONNXRUNTIME_SOURCE_PARENT_DIR --- ${NC}"
mkdir -p "$ONNXRUNTIME_SOURCE_PARENT_DIR"

echo -e "${YELLOW}--- Handling ONNXRuntime repository ---${NC}"
git_clone_or_update "https://github.com/microsoft/onnxruntime.git" "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH" "$ONNXRUNTIME_VERSION"

if [ -d "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH/.git" ]; then
    echo -e "${YELLOW}--- Update submodules for ONNXRuntime under $ONNXRUNTIME_SOURCE_DIR_FULL_PATH ---${NC}" 
    cd "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH"
    git submodule sync --recursive
    git submodule update --init --recursive --force
    cd "$SCRIPT_BASE_DIR"
else
    echo -e "${BRED}Error: Not Found ONNXRuntime Source After clone/update.${NC}" >&2
    exit 1
fi

mkdir -p "$ONNXRUNTIME_INSTALL_ROOT_DIR"

for CURRENT_ABI in "${ABIS_TO_BUILD[@]}"; do
    echo -e ""
    echo -e "${YELLOW}=====================================================================================${NC}"
    if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
        echo -e "${YELLOW}Start building ONNXRuntime for platform: $CURRENT_ABI${NC}"
    else 
        echo -e "${YELLOW}Start building ONNXRuntime for ABI: $CURRENT_ABI, target API: $DEFAULT_ANDROID_API${NC}"
    fi
    echo -e "${YELLOW}=====================================================================================${NC}"
   
    if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
        local INSTALL_DIR_ABI="${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_${CURRENT_ABI}"
    else
        local INSTALL_DIR_ABI="${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_android_${CURRENT_ABI}"
    fi
    mkdir -p "${INSTALL_DIR_ABI}/lib"
    mkdir -p "${INSTALL_DIR_ABI}/include"

    cd "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH"

    local ORT_SPECIFIC_CONFIG_BUILD_DIR="build/Android/${ONNXRUNTIME_BUILD_CONFIG}"
    if [ -d "$ORT_SPECIFIC_CONFIG_BUILD_DIR" ]; then
        echo -e "${YELLOW}--- Clean ONNXRuntime specific configuration build directory: $ORT_SPECIFIC_CONFIG_BUILD_DIR for $CURRENT_ABI ---${NC}"
        rm -rf "$ORT_SPECIFIC_CONFIG_BUILD_DIR"
    fi

    # ONNXRuntime 构建日志
    ORT_BUILD_LOG_FILE_DIR="${SCRIPT_BASE_DIR}/logs/onnxruntime"
    mkdir -p "${ORT_BUILD_LOG_FILE_DIR}"
    LOG_FILE_FOR_ABI="${ORT_BUILD_LOG_FILE_DIR}/build_onnxruntime_${CURRENT_ABI}.log"

    if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
        BUILD_ARGS=(
            "--config" "Release"
            "--parallel"
            "--update"
            "--build"
            "--skip_tests"
        )
    else 
        BUILD_ARGS=(
            "--android"
            "--android_sdk_path" "$ANDROID_SDK_HOME" 
            "--android_ndk_path" "$ANDROID_NDK_HOME" 
            "--android_abi" "$CURRENT_ABI" 
            "--android_api" "$DEFAULT_ANDROID_API" 
            "--config" "${ONNXRUNTIME_BUILD_CONFIG}" 
            "--parallel" "$(nproc)" 
            "--build_shared_lib"
            "--minimal_build=extended"
            "--disable_contrib_ops"
            "--disable_ml_ops"
            "--disable_exceptions"
            "--disable_rtti"
            "--skip_tests"
            "--use_xnnpack"
            "--use_nnapi"
            "--cmake_extra_defines" "CMAKE_CXX_FLAGS=-Wno-error=shorten-64-to-32"
        )
    fi

    ./build.sh "${BUILD_ARGS[@]}" > "${LOG_FILE_FOR_ABI}" 2>&1    # 写入编译日志

    ONNXRUNTIME_BUILD_EXIT_CODE=$?
    
    if [ $ONNXRUNTIME_BUILD_EXIT_CODE -ne 0 ]; then
      echo -e "${BRED}Error: Failed to build ONNXRuntime for ABI $CURRENT_ABI, EXIT CODE: $ONNXRUNTIME_BUILD_EXIT_CODE${NC}"
      echo -e "${BRED}Check detailed log: ${LOG_FILE_ALL}${NC}" >&2
    else
      echo -e "${BGREEN}ONNXRuntime ABI $CURRENT_ABI built successfully. Log file: ${LOG_FILE_FOR_ABI}${NC}"
    fi

    echo "--- Utilize cmake --install to install ONNXRuntime for $CURRENT_ABI to $INSTALL_DIR_ABI ---"
    
    if [ -d "$ONNXRUNTIME_SOURCE_PARENT_DIR" ]; then
        cmake --install "$ORT_SPECIFIC_CONFIG_BUILD_DIR" \
              --prefix "$INSTALL_DIR_ABI" \
              --config "${ONNXRUNTIME_BUILD_CONFIG}"

        echo "ONNXRuntime for $CURRENT_ABI installed to $INSTALL_DIR_ABI by cmake install"

        # 写入编译元信息
        REPORT_FILE="${INSTALL_DIR_ABI}/build_report_${CURRENT_ABI}.txt"
        # 基础信息
        echo "ONNXRuntime Build Report" > "$REPORT_FILE"
        echo "===================================" > "$REPORT_FILE"
        echo "Date: $(date)" >> "$REPORT_FILE"
        echo "ABI: $CURRENT_ABI" >> "$REPORT_FILE"
        echo "ONNXRuntime Versions (Git Tag/Branch): $ONNXRUNTIME_VERSION" >> "$REPORT_FILE"
        if [ -d "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH/.git" ]; then
            GIT_COMMIT_HASH=$(cd "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH" && git rev-parse --short HEAD)
            echo "ONNXRuntime Git Commit: $GIT_COMMIT_HASH" >> "$REPORT_FILE"
        fi
        echo "Build Configuration: $ONNXRUNTIME_BUILD_CONFIG" >> "$REPORT_FILE"
        if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
            echo "HOST_GCC_PATH: $HOST_GCC_PATH"                            >> "$REPORT_FILE"
            echo "HOST_GXX_PATH: $HOST_GXX_PATH"                            >> "$REPORT_FILE"
            echo "HOST_GCC_VERSION: $HOST_GCC_VERSION"                      >> "$REPORT_FILE"
            echo "HOST_CLANG_PATH: $HOST_CLANG_PATH"                        >> "$REPORT_FILE"
            echo "HOST_CLANGXX_PATH: $HOST_CLANGXX_PATH"                    >> "$REPORT_FILE"
            echo "HOST_CLANG_VERSION: $HOST_CLANG_VERSION"                  >> "$REPORT_FILE"
        else
            echo "Android API Level: $DEFAULT_ANDROID_API" >> "$REPORT_FILE"
            echo "NDK Path: $ANDROID_NDK_HOME" >> "$REPORT_FILE"
            echo "NDK Version (from source.properties): $NDK_VERSION_STRING" >> "$REPORT_FILE"
            echo "NDK Compiler"                                 >> "$REPORT_FILE"
            echo "CLANG_CXX_COMPILER: $CLANG_COMPILER_PATH"     >> "$REPORT_FILE"
            echo "CLANG_C_COMPILER: $CLANG_C_COMPILER_PATH"     >> "$REPORT_FILE"
            echo "Clang Version: $CLANG_VERSION_STRING"         >> "$REPORT_FILE"
            echo "=============================================">> "$REPORT_FILE"
        fi
        echo "Build Script Arguments Used: "                >> "$REPORT_FILE"
        printf " %s\n" "${BUILD_ARGS[@]}"                   >> "$REPORT_FILE"
        echo -e "${GREEN}Build report generated :${REPORT_FILE}${NC}"
    else
        echo "Warning: Not Found ONNXRuntime CMake build directory '$ORT_SPECIFIC_CONFIG_BUILD_DIR' after build for $CURRENT_ABI" >&2
        echo "Skipped cmake --install." >&2
    fi

    cd "$SCRIPT_BASE_DIR"
    
    echo -e "${YELLOW}Built ONNXRuntime for ABI $CURRENT_ABI. Copied build output to $INSTALL_DIR_ABI${NC}"
    echo -e "${YELLOW}-------------------------------------------------------------------------------${NC}"
done

echo ""
echo -e "${YELLOW}===============================================================${NC}"
echo -e "${YELLOW}All ONNXRuntime ABI builds completed.${NC}"
echo -e "${YELLOW}Installation directories are in: $ONNXRUNTIME_INSTALL_ROOT_DIR/${NC}"
ls -1 "$ONNXRUNTIME_INSTALL_ROOT_DIR"
echo -e "${YELLOW}===============================================================${NC}"
