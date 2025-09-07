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

# 配置 OpenCV 版本 (默认最新 master)
OPENCV_VERSION="master" # 或者其他目标版本 如 "4.9.0"

# 脚本目录
SCRIPT_BASE_DIR="$(pwd)"

# 源码克隆路径
OPENCV_SOURCE_PARENT_DIR="${SCRIPT_BASE_DIR}/source/opencv"
OPENCV_REPO_NAME="opencv"
OPENCV_CONTRIB_REPO_NAME="opencv_contrib"
OPENCV_SOURCE_DIR_FULL_PATH="${OPENCV_SOURCE_PARENT_DIR}/${OPENCV_REPO_NAME}"
OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH="${OPENCV_SOURCE_PARENT_DIR}/${OPENCV_CONTRIB_REPO_NAME}"

# 构建和安装路径
OPENCV_BUILD_ROOT_DIR="${SCRIPT_BASE_DIR}/build/opencv"
OPENCV_INSTALL_ROOT_DIR="${SCRIPT_BASE_DIR}/opencv"

# ---- 准备源码 ----
echo -e  "${YELLOW}--- Preparing OpenCV source directories under: $OPENCV_SOURCE_PARENT_DIR ---${NC}"
mkdir -p "$OPENCV_SOURCE_PARENT_DIR"
echo -e  "${YELLOW}--- Handling OpenCV repository ---${NC}"
git_clone_or_update "https://github.com/opencv/opencv.git" "$OPENCV_SOURCE_DIR_FULL_PATH" "$OPENCV_VERSION"
echo -e  "${YELLOW}--- Handling OpenCV Contrib repository ---${NC}"
git_clone_or_update "https://github.com/opencv/opencv_contrib.git" "$OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH" "$OPENCV_VERSION"

# 编译日志
OPENCV_LOG_DIR="${SCRIPT_BASE_DIR}/logs/opencv"
mkdir -p "$OPENCV_LOG_DIR"

build_opencv_for_abi() {
    local ABI="$1" 
    local MIN_SDK_VERSION="$2"
    local EXTRA_CMAKE_OPTIONS="$3"
    local BUILD_SUCCESSFUL_FLAG=false

    echo ""
    echo -e "${YELLOW}============================================================${NC}"
    if [ "$ABI" = "linux-x86_64" ]; then
        echo -e "${YELLOW}Building OpenCV for ABI: $ABI${NC}"
    else
        echo -e "${YELLOW}Building OpenCV for ABI: $ABI, Min SDK: $MIN_SDK_VERSION${NC}"
    fi
    if [ -n "$EXTRA_CMAKE_OPTIONS" ]; then
        echo -e "${BLUE}With extra CMake options: $EXTRA_CMAKE_OPTIONS${NC}"
    fi
    echo -e "${YELLOW}============================================================${NC}"

    local BUILD_DIR_ABI="${OPENCV_BUILD_ROOT_DIR}/opencv_android_${ABI}"
    
    if [ "$ABI" = "linux-x86_64" ]; then
        local INSTALL_DIR_ABI="${OPENCV_INSTALL_ROOT_DIR}/opencv_${ABI}"
    else
        local INSTALL_DIR_ABI="${OPENCV_INSTALL_ROOT_DIR}/opencv_android_${ABI}"
    fi
    
    local LOG_FILE_FOR_ABI="${OPENCV_LOG_DIR}/build_opencv_${ABI}.log"
    rm -rf "$LOG_FILE_FOR_ABI"

    echo -e "${YELLOW}--- Cleaning up old build directory: $BUILD_DIR_ABI ---${NC}"
    rm   -rf "$BUILD_DIR_ABI"

    echo  -e "${YELLOW}--- Creating build directory: $BUILD_DIR_ABI ---${NC}"
    mkdir -p "$BUILD_DIR_ABI"

    echo  -e "${YELLOW}--- Creating install directory: $INSTALL_DIR_ABI ---${NC}"
    mkdir -p "$INSTALL_DIR_ABI"
    
    cd "$BUILD_DIR_ABI"
    echo -e "${YELLOW}--- Configuring CMake for $ABI... ---${NC}"

    if [ "$ABI" = "linux-x86_64" ]; then
        CMAKE_ARGS=(
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR_ABI}" 
            "-DOPENCV_EXTRA_MODULES_PATH=${OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH}/modules" 
            "-DBUILD_opencv_world=ON"
            "-DBUILD_SHARED_LIBS=ON"
            "-DBUILD_DOCS=OFF"
            "-DBUILD_EXAMPLES=OFF"
            "-DBUILD_TESTS=OFF"
            "-DBUILD_PERF_TESTS=OFF"
            "-DBUILD_JAVA=OFF"
            "-DBUILD_opencv_viz=OFF"
            "-DBUILD_opencv_apps=OFF"
            "-DBUILD_opencv_python_bindings_generator=OFF"
            "-DBUILD_opencv_python_tests=OFF"
            "-DWITH_VTK=OFF"
            "-DWITH_QT=OFF"
            "-DWITH_CUDA=OFF"
            "-DWITH_FFMPEG=OFF"
            "-DWITH_OPENCL=OFF"
            "-DOPENCV_GENERATE_PKGCONFIG=ON"
        )
    else
        CMAKE_ARGS=(
            "-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" 
            "-DANDROID_NDK=${ANDROID_NDK_HOME}"
            "-DANDROID_ABI=${ABI}"
            "-DANDROID_PLATFORM=android-${MIN_SDK_VERSION}"
            "-DCMAKE_ANDROID_ARCH_ABI=${ABI}"
            "-DCMAKE_ANDROID_STL=c++_shared"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR_ABI}" 
            "-DOPENCV_EXTRA_MODULES_PATH=${OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH}/modules" 
            "-DBUILD_opencv_world=ON"
            "-DBUILD_SHARED_LIBS=ON"
            "-DBUILD_ANDROID_PROJECTS=OFF"
            "-DBUILD_ANDROID_EXAMPLES=OFF"
            "-DBUILD_DOCS=OFF"
            "-DBUILD_EXAMPLES=OFF"
            "-DBUILD_FAT_JAVA_LIB=OFF"
            "-DBUILD_TESTS=OFF"
            "-DBUILD_PERF_TESTS=OFF"
            "-DBUILD_JAVA=OFF"
            "-DWITH_CUDA=OFF"
            "-DWITH_FFMPEG=OFF"
            "-DWITH_OPENCL=OFF"
            "-DOPENCV_GENERATE_PKGCONFIG=ON"
            "-DBUILD_opencv_apps=OFF"
            "-DBUILD_opencv_python_bindings_generator=OFF"
            "-DBUILD_opencv_python_tests=OFF"
            "-DWITH_VTK=OFF"
            "-DBUILD_opencv_viz=OFF"
            "-DWITH_QT=OFF"
        )
    fi

    # 剩余 CMake 参数
    if [ -n "$EXTRA_CMAKE_OPTIONS" ]; then
        CMAKE_ARGS+=("${EXTRA_CMAKE_OPTIONS}")
    fi
    CMAKE_ARGS+=("$OPENCV_SOURCE_DIR_FULL_PATH")

    echo "CMake Configurations:" >> "$LOG_FILE_FOR_ABI"
    echo "cmake -S \"$OPENCV_SOURCE_DIR_FULL_PATH\" -B \"$BUILD_DIR_ABI\" ${CMAKE_ARGS[*]}" >> "$LOG_FILE_FOR_ABI"

    if cmake -S "$OPENCV_SOURCE_DIR_FULL_PATH" -B "$BUILD_DIR_ABI" "${CMAKE_ARGS[@]}" >> "$LOG_FILE_FOR_ABI" 2>&1; then
        CMAKE_CONFIG_EXIT_CODE=0
    else
        CMAKE_CONFIG_EXIT_CODE=$?
    fi

    if [ "$CMAKE_CONFIG_EXIT_CODE" -ne 0 ]; then
        echo -e "${BRED}Error: Failed to configure cmake for OpenCV ABI $ABI, EXIT CODE: $CMAKE_CONFIG_EXIT_CODE ${NC}" >&2
        echo -e "${BRED}Please check detailed log: ${LOG_FILE_FOR_ABI} ${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}--- Building for $ABI... ---${NC}"
    if cmake --build "$BUILD_DIR_ABI" --config Release --parallel $(nproc) >> "$LOG_FILE_FOR_ABI"; then
        CMAKE_BUILD_EXIT_CODE=0
    else
        CMAKE_BUILD_EXIT_CODE=$?
    fi
    
    if [ "$CMAKE_BUILD_EXIT_CODE" -ne 0 ]; then
        echo -e "${BRED}Error: Failed to build OpenCV for ABI $ABI, EXIT CODE: $CMAKE_BUILD_EXIT_CODE ${NC}" >&2
        echo -e "${BRED}Please check detailed log: ${LOG_FILE_FOR_ABI} ${NC}" >&2
        return 1
    else 
        echo -e "${GREEN}OpenCV ABI $ABI built succefsully.${NC}"
        BUILD_SUCCESSFUL_FLAG=true
    fi

    if [ "$BUILD_SUCCESSFUL_FLAG" = true ]; then
        echo -e "${YELLOW}--- Installing OpenCV for ABI... ---${NC}"
        if cmake --install . --config Release >> "$LOG_FILE_FOR_ABI" 2>&1; then
            CMAKE_INSTALL_EXIT_CODE=0
        else
            CMAKE_INSTALL_EXIT_CODE=$?
        fi

        if [ "$CMAKE_INSTALL_EXIT_CODE" -ne 0 ]; then
            echo -e "${BRED}Error: Failed to install OpenCV for ABI $ABI, EXIT CODE: $CMAKE_INSTALL_EXIT_CODE ${NC}" >&2
            echo -e "${BRED}Please check detailed log: ${LOG_FILE_FOR_ABI} ${NC}" >&2
            BUILD_SUCCESSFUL_FLAG=false
        else
            echo -e "${YELLOW}--- OpenCV for $ABI built and installed to $INSTALL_DIR_ABI ---${NC}"
            
            REPORT_FILE="${INSTALL_DIR_ABI}/build_report_${ABI}.txt"
            echo "OpenCV Build Report" > "$REPORT_FILE"
            echo "========================================================" >> "$REPORT_FILE"
            echo "Date: $(date)"                                            >> "$REPORT_FILE"
            echo "ABI: $ABI"                                                >> "$REPORT_FILE"
            echo "OpenCV Version (Git Tag/Branch): $OPENCV_VERSION"         >> "$REPORT_FILE"
            if [ -d "$OPENCV_SOURCE_DIR_FULL_PATH/.git" ]; then
                GIT_COMMIT_HASH=$(cd "$OPENCV_SOURCE_DIR_FULL_PATH" && git rev-parse --short HEAD)
                echo "OpenCV Git Commit: $GIT_COMMIT_HASH"                  >> "$REPORT_FILE"
            fi
            if [ -d "$OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH/.git" ]; then
                GIT_CONTRIB_COMMIT_HASH=$(cd "$OPENCV_CONTRIB_SOURCE_DIR_FULL_PATH" && git rev-parse --short HEAD)
                echo "OpenCV Contrib Git Commit: $GIT_CONTRIB_COMMIT_HASH"  >> "$REPORT_FILE"
            fi
            
            echo "Build Configuration: Release (via CMake)"                 >> "$REPORT_FILE"
            if [ "$ABI" = "linux-x86_64" ]; then
                echo "HOST_GCC_PATH: $HOST_GCC_PATH"                            >> "$REPORT_FILE"
                echo "HOST_GXX_PATH: $HOST_GXX_PATH"                            >> "$REPORT_FILE"
                echo "HOST_GCC_VERSION: $HOST_GCC_VERSION"                      >> "$REPORT_FILE"
                echo "HOST_CLANG_PATH: $HOST_CLANG_PATH"                        >> "$REPORT_FILE"
                echo "HOST_CLANGXX_PATH: $HOST_CLANGXX_PATH"                    >> "$REPORT_FILE"
                echo "HOST_CLANG_VERSION: $HOST_CLANG_VERSION"                  >> "$REPORT_FILE"
            else
                echo "Android API Level: $MIN_SDK_VERSION"                      >> "$REPORT_FILE"
                echo "NDK Path: $ANDROID_NDK_HOME"                              >> "$REPORT_FILE"
                echo "NDK Version (fom source.properties): $NDK_VERSION_STRING" >> "$REPORT_FILE"
                echo "CLANG_CXX_COMPILER: $CLANG_COMPILER_PATH"                 >> "$REPORT_FILE"
                echo "CLANG_C_COMPILER: $CLANG_C_COMPILER_PATH"                 >> "$REPORT_FILE"
                echo "Clang Version: $CLANG_VERSION_STRING"                     >> "$REPORT_FILE"
            fi

            echo ""                                                         >> "$REPORT_FILE"
            echo "CMake Arguments Used: "                                   >> "$REPORT_FILE"
            printf "    %s\n" "${CMAKE_ARGS[@]}"                            >> "$REPORT_FILE"
            echo ""                                                         >> "$REPORT_FILE"
            echo -e "${GREEN}Build Report Generated: ${REPORT_FILE}${NC}"            
        fi
    fi

    cd "$SCRIPT_BASE_DIR"
    echo -e "${YELLOW}------------------------------------------------------------------${NC}"
}

mkdir -p "$OPENCV_BUILD_ROOT_DIR"
mkdir -p "$OPENCV_INSTALL_ROOT_DIR"

build_opencv_for_abi "arm64-v8a"    "21" ""
build_opencv_for_abi "armeabi-v7a"  "19" ""
build_opencv_for_abi "x86"          "21" "-DWITH_IPP=OFF"
build_opencv_for_abi "x86_64"       "21" "-DWITH_IPP=OFF"
build_opencv_for_abi "linux-x86_64" ""   ""

echo ""
echo -e "${YELLOW}===============================================================${NC}"
echo -e "${YELLOW}All OpenCV ABI builds completed.${NC}"
echo -e "${YELLOW}Installation directories are in: $OPENCV_INSTALL_ROOT_DIR/${NC}"
ls -1 "$OPENCV_INSTALL_ROOT_DIR"
echo -e "${YELLOW}===============================================================${NC}"