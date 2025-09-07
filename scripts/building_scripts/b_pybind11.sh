#!/bin/bash
set -e

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

# 指定构建平台
print_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options: ${NC}"
    echo -e "   ${CYAN}--target_platform=<platform>         ${NC}       Specify the target platform."
    echo -e "   Supported Platforms: ${GREEN}android, linux, all(both android and linux)${NC}"
}

TARGET_PLATFORM=""
for i in "$@"; do
    case $i in
        --target_platform=*)
        TARGET_PLATFORM="${i#*=}"
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
    # 引入 NDK 工具链配置 export ANDROID_NDK_HOME
    if [ -f "${SCRIPT_DIR_REALPATH}/common_env.sh" ]; then
        source "${SCRIPT_DIR_REALPATH}/common_env.sh"
    else
        echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
        echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME=\"/path/to/your/ndk\"${NC}"
        exit 1
    fi

    # 配置构建 ABI 及相关的 API Level
    ABIS_TO_BUILD+=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
    ANDROID_API_ARM32="21"
    ANDROID_API_ARM64="21"
    ANDROID_API_X86="21"
    ANDROID_API_X86_64="21"

    # NDK 工具链路径
    NDK_TOOLCHAIN_BIN_PATH="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin"
fi

# --- pybind11 配置 ---
PYBIND11_VERSION="v3.0.0"
SCRIPT_BASE_DIR="$(pwd)"

# --- pybind11 源码目录 ---
PYBIND11_SOURCE_PARENT_DIR="${SCRIPT_BASE_DIR}/source/pybind"
PYBIND11_SOURCE_DIR_NAME="pybind-${PYBIND11_VERSION}"
PYBIND11_SOURCE_DIR_FULL_PATH="${PYBIND11_SOURCE_PARENT_DIR}/${PYBIND11_SOURCE_DIR_NAME}"

# --- pybind11 构建/安装/构建日志根目录 ---
PYBIND11_BUILD_ROOT_DIR="${SCRIPT_BASE_DIR}/build/pybind11"
PYBIND11_INSTALL_ROOT_DIR="${SCRIPT_BASE_DIR}/pybind11"
PYBIND11_LOG_DIR="${SCRIPT_BASE_DIR}/logs/pybind11"

# ---- pybind11 源码准备 ----
echo -e "${YELLOW}--- Preparing pybind11 source: $PYBIND11_SOURCE_PARENT_DIR ---${NC}"
mkdir -p "$PYBIND11_SOURCE_PARENT_DIR"

echo -e  "${YELLOW}--- Handling pybind11 repository ---${NC}"
git_clone_or_update "https://github.com/pybind/pybind11.git" "$PYBIND11_SOURCE_DIR_FULL_PATH" "$PYBIND11_VERSION"

# --- 创建构建和安装的根目录 ---
mkdir -p "$PYBIND11_BUILD_ROOT_DIR"
mkdir -p "$PYBIND11_INSTALL_ROOT_DIR"
mkdir -p "$PYBIND11_LOG_DIR"

for CURRENT_ABI in "${ABIS_TO_BUILD[@]}"; do
    echo ""
    echo -e "${YELLOW}==============================================================================================${NC}"
    echo -e "${YELLOW}Building pybind11 for ABI: $CURRENT_ABI ${NC}"
    echo -e "${YELLOW}==============================================================================================${NC}"

    BUILD_DIR_ABI="${PYBIND11_BUILD_ROOT_DIR}/${CURRENT_ABI}"
    INSTALL_DIR_ABI="${PYBIND11_INSTALL_ROOT_DIR}/${CURRENT_ABI}"
    LOG_FILE_FOR_ABI="${PYBIND11_LOG_DIR}/pybind11_build_${CURRENT_ABI}.log"
    
    # 清理旧目录和日志
    rm -rf "$BUILD_DIR_ABI"
    rm -rf "$INSTALL_DIR_ABI"
    rm -f "$LOG_FILE_FOR_ABI"
    mkdir -p "$BUILD_DIR_ABI"
    mkdir -p "$INSTALL_DIR_ABI"

    # 进入源码目录进行构建
    cd "$BUILD_DIR_ABI"
    
    CMAKE_ARGS=(
        "-DCMAKE_BUILD_TYPE=Release"
        "-DPYBIND11_TEST=OFF"
        "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR_ABI}"
    )

    if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
        echo -e "${YELLOW}--- Configuring pybind11 for linux x86_64 ---${NC}"
    else
        echo -e "${YELLOW}--- Configuring pybind11 for Android ABI: $CURRENT_ABI ---${NC}"
        CURRENT_ANDROID_API_LEVEL=""
        case "$CURRENT_ABI" in
            "armeabi-v7a") CURRENT_ANDROID_API_LEVEL=$ANDROID_API_ARM32  ;;
            "arm64-v8a")   CURRENT_ANDROID_API_LEVEL=$ANDROID_API_ARM64  ;;
            "x86")         CURRENT_ANDROID_API_LEVEL=$ANDROID_API_X86    ;;
            "X86_64")      CURRENT_ANDROID_API_LEVEL=$ANDROID_API_X86_64 ;;
        esac
        
        CMAKE_ARGS+=(
            "-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
            "-DANDROID_ABI=${CURRENT_ABI}"
            "-DANDROID_PLATFORM=android-${CURRENT_ANDROID_API_LEVEL}"
        )
    fi

    echo -e "${YELLOW}--- Configuring pybind11 for $CURRENT_ABI ---${NC}"
    echo "CMake Args: ${CMAKE_ARGS[@]}" >> "${LOG_FILE_FOR_ABI}"
    
    # 1. 配置 (Configure)
    if cmake "${CMAKE_ARGS[@]}" "$PYBIND11_SOURCE_DIR_FULL_PATH" >> "${LOG_FILE_FOR_ABI}" 2>&1; then
        echo -e "${YELLOW}---- Building pybind11 for $CURRENT_ABI (make) ---${NC}"
        # 2. 编译 (Make)
        if make -j$(nproc) >> "${LOG_FILE_FOR_ABI}" 2>&1; then
        echo -e "${YELLOW}--- Installing pybind11 for $CURRENT_ABI (make install) ---${NC}"
            # 3. 安装 (make install)
            if make install >> "${LOG_FILE_FOR_ABI}" 2>&1; then
                echo -e "${GREEN}pybind11 for ABI $CURRENT_ABI built and installed successfully.${NC}"
                
                # 4. 生成构建报告
                REPORT_FILE="${INSTALL_DIR_ABI}/build_report_${CURRENT_ABI}.txt"
                echo "pybind11 Build Report"              >> "$REPORT_FILE"
                echo "==============================="    >> "$REPORT_FILE"
                echo "Date: $(date)"                      >> "$REPORT_FILE"
                echo "ABI: $CURRENT_ABI"                  >> "$REPORT_FILE"
                echo "pybind11 Version: $PYBIND11_VERSION" >> "$REPORT_FILE"
                echo "Install Path: $INSTALL_DIR_ABI"     >> "$REPORT_FILE"
                if [[ "$CURRENT_ABI" != "linux-x86_64" ]]; then
                    echo "Platform: Android"              >> "$REPORT_FILE"
                    echo "NDK Path: $ANDROID_NDK_HOME"    >> "$REPORT_FILE"
                else
                    echo "Platform: Linux"                >> "$REPORT_FILE"
                fi
                echo "Log File: ${LOG_FILE_FOR_ABI}"      >> "$REPORT_FILE"
            else
                echo -e "${BRED}Error: Failed to install pybind11 for ABI $CURRENT_ABI${NC}" >&2
                echo -e "${BRED}Check detailed log: ${LOG_FILE_FOR_ABI}${NC}" >&2
            fi
        else
            echo -e "${BRED}Error: Failed to build pybind11 for ABI $CURRENT_ABI ${NC}" >&2
            echo -e "${BRED}Check detailed log: ${LOG_FILE_FOR_ABI}${NC}" >&2
        fi
    else
      echo -e "${BRED}Error: Failed to build pybind11 for ABI $CURRENT_ABI${NC}" >&2
      echo -e "${BRED}Check detailed log: ${LOG_FILE_FOR_ABI}${NC}" >&2
    fi

    cd "$SCRIPT_BASE_DIR"

    echo -e "${YELLOW}--- pybind11 for ABI $CURRENT_ABI installed to: $INSTALL_DIR_ABI---${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------------------------------------------${NC}"
done

echo ""
echo -e "${YELLOW}==================================================${NC}"
echo -e "${BLUE}All selected pybind11 ABIs have been processed.${NC}"
echo -e "${BLUE}Installation summary:${NC}"
ls -1 "$PYBIND11_INSTALL_ROOT_DIR"
echo -e "${YELLOW}==================================================${NC}"

