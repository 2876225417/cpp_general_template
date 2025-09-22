#!/bin/bash
set -e

# 构建脚本自身所在目录
SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

# 引入 git 配置
COMMON_GIT_SCRIPT="${SCRIPT_DIR_REALPATH}/../common/common_git.sh" 
if [ -f "$COMMON_GIT_SCRIPT" ]; then 
    source "$COMMON_GIT_SCRIPT" 
else
    echo "Error: common_git.sh not found at $COMMON_GIT_SCRIPT" >&2
    exit 1
fi

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR_REALPATH}/../common/common_color.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/../common/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

# 指定构建平台
print_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options: ${NC}"
    echo -e "   ${CYAN}--target_platform=<platform>         ${NC}       Specify the target platform."
    echo -e "   Supported Platforms: ${GREEN}android, linux, all(both android and linux)${NC}"
    echo -e "   ${CYAN}--clean                              ${NC}       Clean build cache before building"
    echo -e "   ${CYAN}--disable_warnings_as_errors         ${NC}       Disable treating warnings as errors"
}

TARGET_PLATFORM=""
CLEAN_BUILD=false
DISABLE_WARNINGS_AS_ERRORS=false
for i in "$@"; do
    case $i in
        --target_platform=*)
        TARGET_PLATFORM="${i#*=}"
        shift
        ;;
        --clean)
        CLEAN_BUILD=true
        shift
        ;;
        --disable_warnings_as_errors)
        DISABLE_WARNINGS_AS_ERRORS=true
        shift
        ;;
        *)
        echo -e "${BRED}Error: Unknown option '$i'${NC}"
        print_usage
        exit 1
        ;;
    esac
done

if [ -z "$TARGET_PLATFORM" ]; then
    echo -e "${BRED}Error: Target platform must be specified.${NC}"
    print_usage
    exit 1
fi

ABIS_TO_BUILD=()
if [[ "$TARGET_PLATFORM" == "linux" || "$TARGET_PLATFORM" == "all" ]]; then
    ABIS_TO_BUILD+=("linux-x86_64")
fi

if [[ "$TARGET_PLATFORM" == "android" || "$TARGET_PLATFORM" == "all" ]]; then
    # 引入 NDK 工具链配置
    if [ -f "${SCRIPT_DIR_REALPATH}/common_env.sh" ]; then
        source "${SCRIPT_DIR_REALPATH}/common_env.sh"
        if [ $? -ne 0 ] || [ -z "$ANDROID_NDK_HOME" ] || [ -z "$ANDROID_SDK_HOME" ]; then
            echo -e "${BRED}Error: NDK or SDK path not set by common_env.sh ${NC}" >&2
            exit 1
        fi
    else
        echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
        echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME=\"/path/to/your/ndk\"${NC}"
        exit 1
    fi

    ABIS_TO_BUILD+=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
fi

# 配置 ONNXRuntime 版本
ONNXRUNTIME_VERSION="v1.22.0"

# 脚本目录
SCRIPT_BASE_DIR="$(pwd)"

# 源码路径
ONNXRUNTIME_SOURCE_PARENT_DIR="${SCRIPT_BASE_DIR}/source/onnxruntime"
ONNXRUNTIME_REPO_NAME="onnxruntime"
ONNXRUNTIME_SOURCE_DIR_FULL_PATH="${ONNXRUNTIME_SOURCE_PARENT_DIR}/${ONNXRUNTIME_REPO_NAME}"

# 安装和构建路径
ONNXRUNTIME_INSTALL_ROOT_DIR="${SCRIPT_BASE_DIR}/onnxruntime"
ONNXRUNTIME_BUILD_CONFIG="MinSizeRel"
ONNXRUNTIME_HOST_BUILD_CONFIG="Release"

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

# 清理构建缓存
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}--- Cleaning build cache ---${NC}"
    rm -rf "${ONNXRUNTIME_SOURCE_DIR_FULL_PATH}/build"
    rm -rf "${SCRIPT_BASE_DIR}/logs/onnxruntime"
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
        INSTALL_DIR_ABI="${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_${CURRENT_ABI}"
        ORT_SPECIFIC_CONFIG_BUILD_DIR="${ONNXRUNTIME_SOURCE_DIR_FULL_PATH}/build/Linux/${ONNXRUNTIME_BUILD_CONFIG}"
    else
        INSTALL_DIR_ABI="${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_android_${CURRENT_ABI}"
        ORT_SPECIFIC_CONFIG_BUILD_DIR="${ONNXRUNTIME_SOURCE_DIR_FULL_PATH}/build/Android/${ONNXRUNTIME_BUILD_CONFIG}"
    fi
    
    mkdir -p "${INSTALL_DIR_ABI}/lib"
    mkdir -p "${INSTALL_DIR_ABI}/include"

    cd "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH"

    # 清理特定 ABI 的构建目录
    if [ -d "$ORT_SPECIFIC_CONFIG_BUILD_DIR" ]; then
        echo -e "${YELLOW}--- Clean ONNXRuntime specific configuration build directory: $ORT_SPECIFIC_CONFIG_BUILD_DIR for $CURRENT_ABI ---${NC}"
        rm -rf "$ORT_SPECIFIC_CONFIG_BUILD_DIR"
    fi

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
        
        # 如果需要禁用警告作为错误
        if [ "$DISABLE_WARNINGS_AS_ERRORS" = true ]; then
            BUILD_ARGS+=("--cmake_extra_defines" "CMAKE_CXX_FLAGS=-Wno-error=maybe-uninitialized -Wno-error")
        fi
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
        )
        
        # Android 构建也添加警告忽略
        if [ "$DISABLE_WARNINGS_AS_ERRORS" = true ]; then
            BUILD_ARGS+=("--cmake_extra_defines" "CMAKE_CXX_FLAGS=-Wno-error=maybe-uninitialized -Wno-error")
        else
            BUILD_ARGS+=("--cmake_extra_defines" "CMAKE_CXX_FLAGS=-Wno-error=maybe-uninitialized")
        fi
    fi

    echo -e "${BLUE}Running build.sh with args:${NC}"
    printf "%s\n" "${BUILD_ARGS[@]}"

    ./build.sh "${BUILD_ARGS[@]}" > "${LOG_FILE_FOR_ABI}" 2>&1

    ONNXRUNTIME_BUILD_EXIT_CODE=$?

    if [ $ONNXRUNTIME_BUILD_EXIT_CODE -ne 0 ]; then
      echo -e "${BRED}Error: Failed to build ONNXRuntime for ABI $CURRENT_ABI, EXIT CODE: $ONNXRUNTIME_BUILD_EXIT_CODE${NC}"
      echo -e "${BRED}Check detailed log: ${LOG_FILE_FOR_ABI}${NC}" >&2
    else
      echo -e "${BGREEN}ONNXRuntime ABI $CURRENT_ABI built successfully. Log file: ${LOG_FILE_FOR_ABI}${NC}"
    fi

    echo -e "${YELLOW}--- Utilize cmake --install to install ONNXRuntime for $CURRENT_ABI to $INSTALL_DIR_ABI ---${NC}"

    if [ -d "$ONNXRUNTIME_SOURCE_PARENT_DIR" ] && [ -d "$ORT_SPECIFIC_CONFIG_BUILD_DIR" ]; then
        cmake --install "$ORT_SPECIFIC_CONFIG_BUILD_DIR" \
              --prefix "$INSTALL_DIR_ABI" \
              --config "${ONNXRUNTIME_BUILD_CONFIG}"

        echo -e "${GREEN}ONNXRuntime for $CURRENT_ABI installed to $INSTALL_DIR_ABI by cmake install${NC}"

        # 写入编译元信息
        REPORT_FILE="${INSTALL_DIR_ABI}/build_report_${CURRENT_ABI}.txt"
        echo "ONNXRuntime Build Report" > "$REPORT_FILE"
        echo "===================================" >> "$REPORT_FILE"
        echo "Date: $(date)" >> "$REPORT_FILE"
        echo "ABI: $CURRENT_ABI" >> "$REPORT_FILE"
        echo "ONNXRuntime Versions (Git Tag/Branch): $ONNXRUNTIME_VERSION" >> "$REPORT_FILE"
        if [ -d "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH/.git" ]; then
            GIT_COMMIT_HASH=$(cd "$ONNXRUNTIME_SOURCE_DIR_FULL_PATH" && git rev-parse --short HEAD)
            echo "ONNXRuntime Git Commit: $GIT_COMMIT_HASH" >> "$REPORT_FILE"
        fi
        echo "Build Configuration: $ONNXRUNTIME_BUILD_CONFIG" >> "$REPORT_FILE"
        if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
            echo "Platform: Linux" >> "$REPORT_FILE"
        else
            echo "Platform: Android" >> "$REPORT_FILE"
            echo "Android API Level: $DEFAULT_ANDROID_API" >> "$REPORT_FILE"
            echo "NDK Path: $ANDROID_NDK_HOME" >> "$REPORT_FILE"
        fi
        echo "Build Script Arguments Used: " >> "$REPORT_FILE"
        printf " %s\n" "${BUILD_ARGS[@]}" >> "$REPORT_FILE"
        echo -e "${GREEN}Build report generated :${REPORT_FILE}${NC}"
    else
        echo -e "${BRED}Warning: Not Found ONNXRuntime CMake build directory after build for $CURRENT_ABI${NC}" >&2
        echo -e "${BRED}Skipped cmake --install.${NC}" >&2
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

