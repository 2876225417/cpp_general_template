#!/bin/bash

set -e

# 构建 FMT 动态库(或者 Header-Only)

SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

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

# 引入 git 配置
COMMON_GIT_SCRIPT="${SCRIPT_DIR_REALPATH}/common_git.sh" 
if [ -f "$COMMON_GIT_SCRIPT" ]; then 
    source "$COMMON_GIT_SCRIPT" 
else
    echo -e "${BRED}Error: common_git.sh not found at $COMMON_GIT_SCRIPT${NC}" >&2
    exit 1
fi

FMT_VERSION_TAG="11.2.0"
FMT_REPO_URL="https://github.com/fmtlib/fmt.git"

SCRIPT_BASE_DIR="$(pwd)"

FMT_SOURCE_PARENT_DIR="${SCRIPT_BASE_DIR}/source/fmt"
FMT_REPO_NAME="fmt_src"
FMT_SOURCE_DIR_FULL_PATH="${FMT_SOURCE_PARENT_DIR}/${FMT_REPO_NAME}"

FMT_BUILD_ROOT_DIR="${SCRIPT_BASE_DIR}/build/fmt"
FMT_INSTALL_ROOT_DIR="${SCRIPT_BASE_DIR}/fmt"

FMT_BUILD_CONFIG="Release"  # 或者 Debug, RelWithDebInfo

# 针对不同的 架构 及API Level
ABIS_TO_BUILD=("armeabi-v7a" "arm64-v8a" "x86" "x86_64" "linux-x86_64")
ANDROID_API_ARM32="21"
ANDROID_API_ARM64="24"
ANDROID_API_X86="24"
ANDROID_API_X86_64="24"

echo -e "${YELLOW}---Preparing {fmt} source under: $FMT_SOURCE_PARENT_DIR---${NC}"
mkdir -p "$FMT_SOURCE_PARENT_DIR"

echo -e "${BLUE}---Handling {fmt} source repository (Version ${FMT_VERSION_TAG}) ---${NC}"
git_clone_or_update "$FMT_REPO_URL" "$FMT_SOURCE_DIR_FULL_PATH" "$FMT_VERSION_TAGS"

mkdir -p "$FMT_BUILD_ROOT_DIR"
mkdir -p "$FMT_INSTALL_ROOT_DIR"
LOG_ROOT_DIR="${SCRIPT_BASE_DIR}/logs/fmt"
mkdir -p "$LOG_ROOT_DIR"

cd "$SCRIPT_BASE_DIR"

for CURRENT_ABI in "${ABIS_TO_BUILD[@]}"; do
    echo ""
    echo -e "${BPURPLE}================================================================${NC}"
    CURRENT_API_LEVLE=""
    if [ "$CURRENT_ABI" != "linux-x86_64" ]; then
        case "$CURRENT_ABI" in
            "armeabi-v7a")  CURRENT_API_LEVLE="$ANDROID_API_ARM32"  ;;
            "arm64-v8a")    CURRENT_API_LEVLE="$ANDROID_API_ARM64"  ;;
            "x86")          CURRENT_API_LEVLE="$ANDROID_API_X86"    ;;
            "x86_64")       CURRENT_API_LEVLE="$ANDROID_API_X86_64" ;;
            *)
                echo -e "${BRED}Error: Not supported ABI: '$CURRENT_ABI'${NC}"
                continue
                ;;
        esac
    fi

    echo -e "${BPURPLE}--- Building {fmt} for ABI ${CYAN}$CURRENT_ABI${BPURPLE}, Target API Level: $CURRENT_API_LEVLE ---${NC}"
    echo -e "${BPURPLE}================================================================${NC}"
    
    BUILD_DIR_ABI="${FMT_BUILD_ROOT_DIR}/fmt_build_android_${CURRENT_ABI}"
    if [ "$CURRENT_ABI" = "linux-x86_64" ]; then
        INSTALL_DIR_ABI="${FMT_INSTALL_ROOT_DIR}/fmt_${CURRENT_ABI}"
    else
        INSTALL_DIR_ABI="${FMT_INSTALL_ROOT_DIR}/fmt_android_${CURRENT_ABI}"
    fi
    LOG_FILE_FOR_ABI="${LOG_ROOT_DIR}/build_fmt_${CURRENT_ABI}.log"

    echo "fmt Build Log for ABI: $CURRENT_ABI - $(date)" > "${LOG_FILE_FOR_ABI}"

    echo -e "${YELLOW}--- Cleaning build directory: $BUILD_DIR_ABI ---${NC}"
    rm -rf "$BUILD_DIR_ABI"
    
    echo -e "${YELLOW}--- Creating install directory: $INSTALL_DIR_ABI ---${NC}" | tee -a "$LOG_FILE_FOR_ABI"
    mkdir -p "$INSTALL_DIR_ABI"

    echo -e "${BLUE}--- Configuring CMake {fmt} for ABI ${CURRENT_ABI}(Log file: ${LOG_FILE_FOR_ABI}) ---${NC}"
    

    CMAKE_ARGS=(
        "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR_ABI}"
        "-DFMT_TEST=OFF"
        "-DFMT_DOC=OFF"
        "-DBUILD_SHARED_LIBS=ON"
        "-DCMAKE_CXX_STANDRAD=23"   
    )

    if [ "$CURRENT_ABI" != "linux-x86_64" ]; then 
        CMAKE_ARGS+=(
            "-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
            "-DANDROID_NDK=${ANDROID_NDK_HOME}"
            "-DANDROID_ABI=${CURRENT_ABI}"
            "-DANDROID_PLATFORM=android-${CURRENT_API_LEVLE}"
            "-DCMAKE_ANDROID_ARCH_ABI=${CURRENT_ABI}"
        )
    fi

    echo "CMake Configurations: " >> "$LOG_FILE_FOR_ABI"
    echo "cmake -S \"$FMT_SOURCE_DIR_FULL_PATH\" -B \"$BUILD_DIR_ABI\" ${CMAKE_ARGS[*]}" >> "$LOG_FILE_FOR_ABI"

    BUILD_SUCCESSFUL_FLAG=false
    
    if cmake -S "$FMT_SOURCE_DIR_FULL_PATH" -B "$BUILD_DIR_ABI" "${CMAKE_ARGS[@]}" >> "$LOG_FILE_FOR_ABI" 2>&1; then
        CMAKE_CONFIG_EXIT_CODE=0
    else
        CMAKE_CONFIG_EXIT_CODE=$?
    fi
    
    if [ "$CMAKE_CONFIG_EXIT_CODE" -ne 0 ]; then
        echo -e "${BRED}Error: Failed to configure {fmt} CMake for ABI $CURRENT_ABI. EXIT CODE: $CMAKE_CONFIG_EXIT_CODE ${NC}" >&2
    else
        echo -e "${BLUE}--- Building {fmt} for ABI $CURRENT_ABI ---${NC}"
        if cmake --build "$BUILD_DIR_ABI" --config "${FMT_BUILD_CONFIG}" --parallel $(nproc) >> "$LOG_FILE_FOR_ABI" 2>&1; then
            CMAKE_BUILD_EXIT_CODE=0
        else
            CMAKE_BUILD_EXIT_CODE=$?
        fi

        if [ "$CMAKE_BUILD_EXIT_CODE" -ne 0 ]; then
            echo -e "${BRED}Error: Failed to build {fmt} for ABI $CURRENT_ABI. EXIT CODE: $CMAKE_BUILD_EXIT_CODE ${NC}" >&2
        else
            echo -e "${GREEN}{fmt} for ABI $CURRENT_ABI built successfully.${NC}"
            
            echo -e "${BLUE}--- Installing {fmt} for ABI ${CURRENT_ABI} ---${NC}"
            if cmake --install "$BUILD_DIR_ABI" --config "${FMT_BUILD_CONFIG}" >> "$LOG_FILE_FOR_ABI" 2>&1; then
                CMAKE_INSTALL_EXIT_CODE=0
            else
                CMAKE_CONFIG_EXIT_CODE=$?
            fi

            if [ "$CMAKE_INSTALL_EXIT_CODE" -ne 0 ]; then
                echo -e "${BRED}Error: Failed to install {fmt} for ABI $CURRENT_ABI. EXIT CODE: $CMAKE_INSTALL_EXIT_CODE ${NC}" >&2
            else
                echo -e "${GREEN}{fmt} for ABI $CURRENT_ABI installed successfully.${NC}"
                BUILD_SUCCESSFUL_FLAG=true

                REPORT_FILE="${INSTALL_DIR_ABI}/build_report_${CURRENT_ABI}.txt"
                echo "{fmt} Build Report" > "$REPORT_FILE"
                echo "========================================================" >> "$REPORT_FILE"
                echo "Date: $(date)"                                            >> "$REPORT_FILE"
                echo "ABI: $CURRENT_ABI"                                        >> "$REPORT_FILE"
                echo "{fmt} Version (Git Tag/Branch): $FMT_VERSION_TAG" >> "$REPORT_FILE"
                if [ -d "$FMT_SOURCE_DIR_FULL_PATH/.git" ]; then
                    GIT_COMMIT_HASH=$(cd "$FMT_SOURCE_DIR_FULL_PATH" && git rev-parse --short HEAD)
                    echo "{fmt} Git Commit: $GIT_COMMIT_HASH"                  >> "$REPORT_FILE"
                fi
                
                echo "Build Configuration: Release (via CMake)"                 >> "$REPORT_FILE"
                if [ "$CURRENT_ABI" != "linux-x86_64" ]; then
                    echo "NDK Path: $ANDROID_NDK_HOME"                              >> "$REPORT_FILE"
                    echo "NDK Version (fom source.properties): $NDK_VERSION_STRING" >> "$REPORT_FILE"
                    echo "CLANG_CXX_COMPILER: $CLANG_COMPILER_PATH"                 >> "$REPORT_FILE"
                    echo "CLANG_C_COMPILER: $CLANG_C_COMPILER_PATH"                 >> "$REPORT_FILE"
                    echo "Clang Version: $CLANG_VERSION_STRING"                     >> "$REPORT_FILE"
                else
                    echo "HOST_GCC_PATH: $HOST_GCC_PATH"                            >> "$REPORT_FILE"
                    echo "HOST_GXX_PATH: $HOST_GXX_PATH"                            >> "$REPORT_FILE"
                    echo "HOST_GCC_VERSION: $HOST_GCC_VERSION"                      >> "$REPORT_FILE"
                    echo "HOST_CLANG_PATH: $HOST_CLANG_PATH"                        >> "$REPORT_FILE"
                    echo "HOST_CLANGXX_PATH: $HOST_CLANGXX_PATH"                    >> "$REPORT_FILE"
                    echo "HOST_CLANG_VERSION: $HOST_CLANG_VERSION" 
                fi
                
                echo ""                                                         >> "$REPORT_FILE"
                echo "CMake Arguments Used: "                                   >> "$REPORT_FILE"
                printf "    %s\n" "${CMAKE_ARGS[@]}"                            >> "$REPORT_FILE"
                echo ""                                                         >> "$REPORT_FILE"

                echo -e "${GREEN}Build Report Generated${NC}"
            fi
        fi
    fi

    cd "$SCRIPT_BASE_DIR"
    if [ "$BUILD_SUCCESSFUL_FLAG" = true ]; then
        echo -e "${GREEN}--- {fmt} for ABI $CURRENT_ABI built and intalled successully---${NC}"
    else
        echo -e "${BRED}--- Failed to build or install {fmt} for ABI $CURRENT_ABI. Please check log file: $LOG_FILE_FOR_ABI---${NC}" >&2
    fi
    echo -e "${BPURPLE}================================================================${NC}"
done

echo ""
echo -e "${YELLOW}=======================================${NC}"
echo -e "${BLUE}All {fmt} built successfully.${NC}"
echo -e "Installed directory: ${CYAN}$FMT_INSTALL_ROOT_DIR${NC}"
ls -1 "$FMT_INSTALL_ROOT_DIR"
echo -e "${YELLOW}=======================================${NC}"