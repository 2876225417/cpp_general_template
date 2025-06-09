#!/bin/bash

set -e

# 项目编译 build

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR}/scripts/common_color.sh" ]; then
    source "${SCRIPT_DIR}/scripts/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi
# 引入 NDK 工具链配置 
if [ -f "${SCRIPT_DIR}/scripts/common_env.sh" ]; then
    source "${SCRIPT_DIR}/scripts/common_env.sh"
    if [ $? -ne 0 ] || [ -z "$ANDROID_NDK_HOME" ] || [ -z "$ANDROID_SDK_HOME" ]; then
        echo -e "${BRED}Error: NDK or SDK path not set by common_ndk.sh ${NC}" >&2
        exit 1
    fi
else
    echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
    echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME="ANDROID NDK Dev Toolchain."${NC}"
    exit 1
fi
DEFAULT_ANDROID_API="android-24"    # 默认 Android API Level
BUILD_DIR="${SCRIPT_DIR}/build"     

# 此处使用默认生成的测试路径
TEST_DIR="${SCRIPT_DIR}/build/tests/"
TEST_LOG_FILE_DIR="${SCRIPT_DIR}/tests/logs"
BUILD_LOG_FILE_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${TEST_LOG_FILE_DIR}"
mkdir -p "${BUILD_LOG_FILE_DIR}"

# ---- 运行参数 ----
BUILD_WITH_CLEAN="on"   # 构建前是否清空构建目录(默认:on)
BUILD_TESTS="off"       # 是否构建测试(默认:off)
VERBOSE_TEST_INFO="off" # 是否显示详细测试信息
BUILD_EXAMPLES="off"    # 是否构建用例(默认:off)
BUILD_TYPE="Release"    # 构建类型(默认:Release)
SAVE_TESTS_LOGS="off"   # 是否保存测试日志(默认:off)
SAVE_BUILD_LOGS="off"   # 是否保存构建日志(默认:off)
TARGET_ARCH=""          # 编译架构

print_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options: ${NC}"
    echo -e "   ${CYAN}--arch=<ARCH>                ${NC}       Specify the target architecture."
    echo -e "   Supported Android ABIs: ${GREEN}armeabi-v7a, arm64-v8a, x86, x86_64{$NC}"
    echo -e "   Supported Native  Arch: ${GREEN}linux-x86_64${NC}"
    echo ""
    echo -e "   ${CYAN}--build_with_clean=<on|off>  ${NC}       Enable or disable building after clean. Default is '${BUILD_WITH_CLEAN}'"
    echo ""
    echo -e "   ${CYAN}--build_tests=<on|off>       ${NC}       Enable or disable building tests. Default is '${BUILD_TESTS}'"
    echo -e "   ${YELLOW}Note: If 'on', the architecture is automatically set to 'linux-x86_64'.${NC}"
    echo ""
    echo -e "   ${CYAN}--verbose_test_info=<on|off> ${NC}       Enable or disable show verbose tests. Default is '${BUILD_TESTS}'"
    echo ""
    echo -e "   ${CYAN}--build_examples=<on|off>    ${NC}       Enable or disable building examples. Default is '${BUILD_EXAMPLES}'."
    echo -e "   ${YELLOW}Note: If 'on', the architecture is automatically set to 'linux-x86_64'.${NC}"
    echo ""
    echo -e "   ${CYAN}--build_type=<TYPE>          ${NC}       Switch build type. Default is 'Release'."
    echo -e "   Supported Build Type: ${GREEN}Release, Debug, MinSizeRelWithDebInfo, RelWithDebInfo. Default is 'Release'.${NC}"
    echo ""
    echo -e "   ${CYAN}--save_tests_logs=<on|off>   ${NC}       Enable or disable saving tests logs. Default is 'off'."
    echo -e "   ${YELLOW}Note: If 'on', the test logs will be saved to ${TEST_LOG_FILE_DIR}.${NC}"
    echo ""
    echo -e "   ${CYAN}--save_build_logs=<on|off>   ${NC}       Enable or disable saving build logs. Default is 'off'."
    echo -e "   ${YELLOW}Note: If 'on', the test logs will be saved to ${TEST_LOG_FILE_DIR}.${NC}"
    echo -e "   ${CYAN}-h, --help${NC}                Show this help message."
    echo ""
    echo -e "   ${YELLOW}Example (Android cross-compile):               ${NC}"
    echo -e "   ${CYAN}$0 --arch=arm64_v8a                              ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Build before clean):                  ${NC}"
    echo -e "   ${CYAN}$0 --build_with_clean=on                         ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Native Linux build with tests):       ${NC}"
    echo -e "   ${CYAN}$0 --build_tests=on                              ${NC}"
    echo -e "   ${YELLOW}Example (Tests info in verbose):               ${NC}"
    echo -e "   ${CYAN}$0 --verbose_test_info=on                       ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Native Linux build with examples):    ${NC}"
    echo -e "   ${CYAN}$0 --build_examples=on                           ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Specify native Linux build type):     ${NC}"
    echo -e "   ${CYAN}$0 --build_type=Release                          ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Save build log):                      ${NC}"
    echo -e "   ${CYAN}$0 --save_build_logs=on                          ${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Save tests log if enable build_tests):${NC}"
    echo -e "   ${CYAN}$0 --save_test_logs=on                           ${NC}"
}

is_supported_arch() {
    local abi_to_check="$1"
    case "$abi_to_check" in
        "armeabi-v7a" | "arm64-v8a" | "x86" | "x86_64" | "linux-x86_64")
            return 0    # true, 支持该 abi
            ;;
        *)
            return 1    # false, 不支持该 abi
            ;;
    esac 
}

is_spported_build_type() {
    local build_type_check="$1"
    case "$build_type_check" in
        "Release" | "Debug" | "RelWithDebInfo" | "MinSizeRelWithDebInfo")
            return 0    # true， 支持该   build type
            ;;
        *)
            return 1    # false，不支持该 build type
            ;;
    esac
}

# --- 解析运行参数 ---
for i in "$@"; do
    case $i in
        --arch=*)
        TARGET_ARCH="${i#*=}"
        shift
        ;;
        --build_tests=*)
        BUILD_TESTS="${i#*=}"
        shift
        ;;
        --build_exmaples=*)
        BUILD_EXAMPLES="${i#*=}"
        shift
        ;;
        --save_tests_logs=*)
        SAVE_TESTS_LOGS="${i#*=}"
        shift
        ;;
        --save_build_logs=*)
        SAVE_BUILD_LOGS="${i#*=}"
        shift
        ;;
        --build_type=*)
        BUILD_TYPE="${i#*=}"
        shift
        ;;
        --build_with_clean=*)
        BUILD_WITH_CLEAN="${i#*=}"
        shift
        ;;
        --verbose_test_info=*)
        VERBOSE_TEST_INFO="${i#*=}"
        shift
        ;;
        -h|--help)
        print_usage
        exit 0
        ;;
        *)
        # Unknown optios
        echo -e "${BRED}Error: Unknown option '$i'${NC}"
        print_usage
        exit 1
        ;;
    esac
done

if [[ "$BUILD_WITH_CLEAN" == "on" ]] || [[ "$BUILD_WITH_CLEAN" == "ON" ]]; then
    echo -e "${YELLOW}Info: Build will be executed before clean the build directory.${NC}"
fi

if [[ "$BUILD_TESTS" == "on" ]]; then
    if [[ -n "$TARGET_ARCH" && "$TARGET_ARCH" != "linux-x86_64" ]]; then
        echo -e "${YELLOW}Warning: --build_tests=on overrides arch. Forcing architecture to 'linux-x86_64'.${NC}"
    fi
    TARGET_ARCH="linux-x86_64"
fi

if [[ "$BUILD_EXAMPLES" == "on" ]]; then
    if [[ -n "$TARGET_ARCH" && "$TARGET_ARCH" != "linux-x86_64" ]]; then
        echo -e "${YELLOW}Warning: --build_examples=on overrides arch. Forcing architecture to 'linux-x86_64'.${NC}"
    fi
    TARGET_ARCH="linux-x86_64"
fi

if [[ "$SAVE_TESTS_LOGS" == "on" ]]; then
    echo -e "${YELLOW}Info: Tests info will be saved to file ${TEST_LOG_FILE_DIR}"
fi

if [[ "$SAVE_BUILD_LOGS" == "on" ]]; then
    echo -e "${YELLOW}Info: Tests info will be saved to file ${BUILD_LOG_FILE_DIR}"
fi

if [ -z "$TARGET_ARCH" ]; then
    echo -e "${BRED}Error: Target architecture not specified. Use --arch=<ARCH> or --build_tests=on.${NC}"
    print_usage
    exit 1
fi

if [[ "$VERBOSE_TEST_INFO" = "on" ]]; then
    echo -e "${YELLOW}Info: Tests info will show in verbose${NC}"
fi

if ! is_supported_arch "$TARGET_ARCH"; then
    echo -e "${BRED}Error: Unsupported architecture '$TARGET_ARCH'.${NC}"
    print_usage
    exit 1
fi

if [ -z "$BUILD_TYPE" ]; then
    echo -e "${RED}Warning: Build type not specified. Default build type '$BUILD_TYPE' will be used,or use --build_type=<TYPE> to specify build type.${NC}" 
fi

if ! is_spported_build_type "$BUILD_TYPE"; then
    echo -e "${BRED}Warning: Unsupported build type  '$BUILD_TYPE'. ${NC}"
    echo -e "${CYAN}Info: Build type set as default: '$BUILD_TYPE'. ${NC}"    
fi

# --- 主构建流程 ---
if [ "$TARGET_ARCH" != "linux-x86_64" ]; then
    echo -e "${BGREEN}Start building tests for host${NC}"
else
    echo -e "${BGREEN}Start building Flutter FFI project${NC}"
    echo -e "${GREEN}Target ABI: ${CYAN}$TARGET_ARCH${NC}"
    echo -e "${GREEN}NDK directory: ${CYAN}$ANDROID_NDK_HOME${NC}"
fi

# 1. Clean 
BUILD_WITH_CLEAN_FLAGS="${BUILD_WITH_CLEAN^^}"
if [ "$BUILD_WITH_CLEAN_FLAGS" == "ON" ]; then
    echo -e "${YELLOW}Cleaning build directory: ${BUILD_DIR}${NC}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
fi

# 2. Configure
echo -e "${GREEN}Configuring CMake...${NC}"

BUILD_TESTS_CMAKE="${BUILD_TESTS^^}"
BUILD_EXMAPLES_CMAKE="${BUILD_EXAMPLES^^}"
VERBOSE_TEST_INFO_FLAG="${VERBOSE_TEST_INFO^^}"
CMAKE_COMMON_ARGS=(
    -S "${SCRIPT_DIR}"
    -B "${BUILD_DIR}"
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
    -DBUILD_TESTS="${BUILD_TESTS_CMAKE}"
    -DBUILD_EXAMPLES="${BUILD_EXMAPLES_CMAKE}"
    -DBUILD_TESTS_VERBOSE="${VERBOSE_TEST_INFO_FLAG}"
    -DUSE_CMAKE_COLORED_MESSAGES=ON
    -DUSE_CPP_COLORED_DEBUG_OUTPUT=ON
    -DENABLE_EIGEN3=ON
    -DENABLE_BOOST=OFF
    -DENABLE_EXTERNAL_FMT=ON
)

if [[ "$TARGET_ARCH" == "linux-x86_64" ]]; then
    echo -e "${PURPLE}Configuring for Native Linux Build.${NC}"
    cmake "${CMAKE_COMMON_ARGS[@]}"
else
    echo -e "${PURPLE}Configuring for Android cross-compilation.${NC}"
    echo -e "${GREEN} NDK directory: ${ANDROID_NDK_HOME}${NC}"
    if [ ! -d "$ANDROID_NDK_HOME" ]; then
        echo -e "${BRED}Error: NDK directory not found at '$ANDROID_NDK_HOME'  ${NC}"
    fi
    cmake "${CMAKE_COMMON_ARGS[@]}" \
          -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
          -DANDROID_ABI="${TARGET_ARCH}" \
          -DANDROID_PLATFORM="android-${DEFAULT_ANDROID_API}"
fi

# 3. Build
if [[ "$TARGET_ARCH" == "linux-x86_64" ]]; then
    echo -e "${GREEN}Building test... for $TARGET_ARCH ${NC}"
    echo -e "${GREEN}Generated test will be automatically executed ${NC}"
else
    echo -e "${GREEN}Building project for $TARGET_ARCH ${NC}"
fi

cmake --build "${BUILD_DIR}" --config "${DEFAULT_CMAKE_BUILD_TYPE}" --parallel $(nproc)

if [[ "$TARGET_ARCH" == "linux-x86_64" ]]; then

    if [[ "$BUILD_TESTS_CMAKE" == "ON" ]]; then
        CTEST_ARGS=(
            "--test-dir" "${TEST_DIR}"
            "--verbose"
        )

        if [ "$VERBOSE_TEST_INFO_FLAG" = "ON" ]; then
            CTEST_ARGS+=(
                "--rerun-failed"
                "--output-on-failure"
            )
        fi

        echo -e "${YELLOW}Generated test dir: ${TEST_DIR}${NC}"
        echo -e "${YELLOW}--- Running test: ctest ${CTEST_ARGS[*]} ---${NC}"
    
        TEST_LOG_FILE="${TEST_LOG_FILE_DIR}/$(date).txt"
        SAVE_TESTS_LOGS_FLAGS="${SAVE_TESTS_LOGS^^}"

        if [ "$SAVE_TESTS_LOGS_FLAGS" == "ON" ]; then
            if ctest "${CTEST_ARGS[@]}" > "$TEST_LOG_FILE"; then
                CTEST_EXIT_CODE=0
            else
                CTEST_EXIT_CODE=$?
            fi
        else
            if ctest "${CTEST_ARGS[@]}" ; then
                CTEST_EXIT_CODE=0
            else
                CTEST_EXIT_CODE=$?
            fi
        fi

        if [ "$CTEST_EXIT_CODE" -ne 0 ]; then
            echo -e "${BRED}ERROR: FAILED TO CTEST EXECUTED.${NC}"
            echo -e "${BRED}Please check testing log: ${TEST_LOG_FILE}.${NC}"
        else
            echo -e "${BYELLOW}SUCCESS: CTEST EXECUTED SUCCESSFULLY.${NC}"
            if [ "$SAVE_LOGS" == "on" ]; then
                echo -e "${BYELLOW}More info please check log: ${TEST_LOG_FILE}.${NC}"
            fi
        fi
    fi

    if [[ "$BUILD_EXMAPLES_CMAKE" == "ON" ]]; then
        echo -e "${CYAN}Generated example dir...${NC}"

    fi
else
    echo ""
    echo -e "${BGREEN}ABI ${TARGET_ARCH} Project's building is finished!${NC}"
fi