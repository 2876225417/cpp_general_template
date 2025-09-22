include_guard(GLOBAL)

# Integrated ONNX Runtime download, extraction and export module
#   !!!To fix official onnxruntimeConfig.cmake issues!!!
# Platform Support:
#   - Linux (x86_64, aarch64)
#   - Windows (x86, x64)
#   - macOS (x64)
#
# GPU Support:
#   - CUDA (via ENABLE_GPU or ENABLE_CUDA option)

# ============================================================================
# 1. Get variable information (system type, CPU architecture, GPU enablement)
# ============================================================================

# GPU enablement options (support both ENABLE_GPU and ENABLE_CUDA)
#   Use -ENABLE_GPU=ON or -ENABLE_CUDA=ON to configure onnxruntime_gpu
if(DEFINED ENABLE_CUDA AND ENABLE_CUDA)
    set(ENABLE_GPU ON)
endif()

option(ENABLE_GPU "Enable GPU support for ONNX Runtime" OFF)

# Version configuration
#   Default Version: 1.21.0
if(NOT DEFINED ONNXRUNTIME_VERSION)
    set(ONNXRUNTIME_VERSION "1.21.0")
endif()

# Download directory configuration
#   Default directory: "Project root source directory" / 3rdparty
if(ENABLE_GPU)
    if(NOT DEFINED ONNXRUNTIME_DOWNLOAD_DIR)
        set(ONNXRUNTIME_DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/3rdparty/onnxruntime_gpu")
    endif()
    set(ONNXRUNTIME_VARIANT "gpu")
    set(ONNXRUNTIME_TYPE_STR "GPU")
else()
    if(NOT DEFINED ONNXRUNTIME_DOWNLOAD_DIR)
        set(ONNXRUNTIME_DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/3rdparty/onnxruntime")
    endif()
    set(ONNXRUNTIME_VARIANT "")
    set(ONNXRUNTIME_TYPE_STR "CPU")
endif()

# Platform and architecture detection
if(WIN32)
    set(ONNXRUNTIME_OS "win")
    set(ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX "zip")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(ONNXRUNTIME_ARCH "x64")
    else()
        set(ONNXRUNTIME_ARCH "X86")
    endif()
elseif(APPLE)
    set(ONNXRUNTIME_OS "osx")
    set(ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX "tgz")
    set(ONNXRUNTIME_ARCH "x64")
elseif(UNIX AND NOT APPLE)
    set(ONNXRUNTIME_OS "linux")
    set(ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX "tgz")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        set(ONNXRUNTIME_ARCH "aarch64")
    else()
        set(ONNXRUNTIME_ARCH "x64")
    endif()
else()
    pretty_message(ERROR "Unsupported platform for ONNX Runtime download")
endif()

# ============================================================================
# 2. Build download URL (user can specify version via variables)
# ============================================================================

if(ENABLE_GPU)
    set(ONNXRUNTIME_DOWNLOAD_URL "https://github.com/microsoft/onnxruntime/releases/download/v${ONNXRUNTIME_VERSION}/onnxruntime-${ONNXRUNTIME_OS}-${ONNXRUNTIME_ARCH}-gpu-${ONNXRUNTIME_VERSION}.${ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX}")
    set(ONNXRUNTIME_DOWNLOAD_FILE "${ONNXRUNTIME_DOWNLOAD_DIR}/onnxruntime-gpu-${ONNXRUNTIME_VERSION}.${ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX}")
else()
    set(ONNXRUNTIME_DOWNLOAD_URL "https://github.com/microsoft/onnxruntime/releases/download/v${ONNXRUNTIME_VERSION}/onnxruntime-${ONNXRUNTIME_OS}-${ONNXRUNTIME_ARCH}-${ONNXRUNTIME_VERSION}.${ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX}")
    set(ONNXRUNTIME_DOWNLOAD_FILE "${ONNXRUNTIME_DOWNLOAD_DIR}/onnxruntime-${ONNXRUNTIME_VERSION}.${ONNXRUNTIME_DOWNLOAD_FILE_POSTFIX}")
endif()

# Use download directory as an extraction directory
set(ONNXRUNTIME_EXTRACT_DIR "${ONNXRUNTIME_DOWNLOAD_DIR}")

# ============================================================================
# 3. Download ONNX Runtime
# ============================================================================

if(NOT EXISTS "${ONNXRUNTIME_EXTRACT_DIR}/include/onnxruntime_c_api.h")
    file(MAKE_DIRECTORY "${ONNXRUNTIME_DOWNLOAD_DIR}")

    pretty_message(STATUS "Downloading ONNX Runtime ${ONNXRUNTIME_TYPE_STR} v${ONNXRUNTIME_VERSION} from ${ONNXRUNTIME_DOWNLOAD_URL}")

    file(DOWNLOAD
        "${ONNXRUNTIME_DOWNLOAD_URL}"
        "${ONNXRUNTIME_DOWNLOAD_FILE}"
        SHOW_PROGRESS
        STATUS DOWNLOAD_STATUS
    )

    list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
    if(NOT STATUS_CODE EQUAL 0)
        list(GET DOWNLOAD_STATUS 1 ERROR_MESSAGE)
        pretty_message(ERROR "Failed to download ONNX Runtime: ${ERROR_MESSAGE}")
    endif()

    # ============================================================================
    # 4. Extract ONNX Runtime and verify file integrity
    # ============================================================================

    pretty_message(STATUS "Extracting ONNX Runtime to ${ONNXRUNTIME_EXTRACT_DIR}")

    set(TEMP_EXTRACT_DIR "${ONNXRUNTIME_DOWNLOAD_DIR}/temp_extract")
    file(MAKE_DIRECTORY "${TEMP_EXTRACT_DIR}")

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${ONNXRUNTIME_DOWNLOAD_FILE}"
        WORKING_DIRECTORY "${TEMP_EXTRACT_DIR}"
        RESULT_VARIABLE EXTRACT_RESULT
    )

    if(NOT EXTRACT_RESULT EQUAL 0)
        pretty_message(ERROR "Failed to extract ONNX Runtime")
    endif()

    # Move extracted files to final location
    file(GLOB EXTRACTED_DIR "${TEMP_EXTRACT_DIR}/onnxruntime*")
    file(GLOB_RECURSE EXTRACTED_FILES "${EXTRACTED_DIR}/*")

    foreach(FILE ${EXTRACTED_FILES})
        file(RELATIVE_PATH REL_FILE "${EXTRACTED_DIR}" "${FILE}")
        if(NOT IS_DIRECTORY "${FILE}")
            get_filename_component(REL_DIR "${ONNXRUNTIME_EXTRACT_DIR}/${REL_FILE}" DIRECTORY)
            file(MAKE_DIRECTORY "${REL_DIR}")
            file(COPY "${FILE}" DESTINATION "${REL_DIR}")
        endif()
    endforeach()

    # Cleanup
    file(REMOVE_RECURSE "${TEMP_EXTRACT_DIR}")
    file(REMOVE "${ONNXRUNTIME_DOWNLOAD_FILE}")

    # Verify file integrity
    #   TODO(ppqwqqq):
    #       Intensify the logics for checking integrity with more vital files
    if(NOT EXISTS "${ONNXRUNTIME_EXTRACT_DIR}/include/onnxruntime_c_api.h")
        pretty_message(ERROR "ONNX Runtime extraction failed - missing header files")
    endif()

    pretty_message(SUCCESS "ONNX Runtime ${ONNXRUNTIME_TYPE_STR} v${ONNXRUNTIME_VERSION} downloaded and extracted successfully")
else()
    pretty_message(STATUS "ONNX Runtime ${ONNXRUNTIME_TYPE_STR} v${ONNXRUNTIME_VERSION} already exists(skip downloading)")
endif()

# ============================================================================
# 5. Manual export of ONNX Runtime targets (avoiding onnxruntimeConfig.cmake issues)
# ============================================================================

# Set up paths for manual target creation
set(ONNXRUNTIME_INCLUDE_DIR "${ONNXRUNTIME_EXTRACT_DIR}/include")
set(ONNXRUNTIME_LIB_DIR "${ONNXRUNTIME_EXTRACT_DIR}/lib")

# Verify installation integrity
if(NOT EXISTS "${ONNXRUNTIME_INCLUDE_DIR}/onnxruntime_c_api.h")
    pretty_message(ERROR "ONNX Runtime ${ONNXRUNTIME_TYPE_STR} headers are incomplete: ${ONNXRUNTIME_INCLUDE_DIR}")
endif()

# Find the library
find_library(ONNXRUNTIME_LIBRARY
    NAMES onnxruntime
    PATHS "${ONNXRUNTIME_LIB_DIR}"
    NO_DEFAULT_PATH
    REQUIRED
)

# Use standard CMake find package handling
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ONNXRuntime
    REQUIRED_VARS
        ONNXRUNTIME_INCLUDE_DIR
        ONNXRUNTIME_LIBRARY
)

if(ONNXRuntime_FOUND)
    pretty_message(SUCCESS "Found ONNX Runtime ${ONNXRUNTIME_TYPE_STR}")
    # Not need verbose info
    # pretty_message_kv(STATUS "Include path" "${ONNXRUNTIME_INCLUDE_DIR}")
    # pretty_message_kv(STATUS "Library" "${ONNXRUNTIME_LIBRARY}")
endif()

# Create imported target
if(NOT TARGET onnxruntime::onnxruntime)
    add_library(onnxruntime::onnxruntime UNKNOWN IMPORTED)
    set_target_properties(onnxruntime::onnxruntime PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${ONNXRUNTIME_INCLUDE_DIR}"
        IMPORTED_LOCATION "${ONNXRUNTIME_LIBRARY}"
    )

    # Add CUDA dependencies for GPU variant
    if(ENABLE_GPU)
        find_package(CUDA QUIET)
        if(CUDA_FOUND)
            set_property(TARGET onnxruntime::onnxruntime APPEND PROPERTY
                INTERFACE_INCLUDE_DIRECTORIES ${CUDA_INCLUDE_DIRS})
            pretty_message(STATUS "CUDA support enabled for ONNX Runtime")
        else()
            pretty_message(WARNING "CUDA not found, but GPU variant of ONNX Runtime was requested")
        endif()
    endif()
endif()

# Mark variables as advanced
mark_as_advanced(
    ONNXRUNTIME_INCLUDE_DIR
    ONNXRUNTIME_LIB_DIR
    ONNXRUNTIME_LIBRARY
)

# ============================================================================
# 6. Keep existing fallback logic for compatibility
# ============================================================================

# Try to find ONNX Runtime in possible paths (fallback mechanism)
if(NOT onnxruntime_FOUND AND DEFINED DEPENDENCY_ROOT_DIR)
    set(ONNXRUNTIME_POSSIBLE_PATHS
        "${DEPENDENCY_ROOT_DIR}/onnxruntime/linux-x86_64"
        "${DEPENDENCY_ROOT_DIR}/onnxruntime/build"
        "${DEPENDENCY_ROOT_DIR}/onnxruntime/install"
        "${DEPENDENCY_ROOT_DIR}/onnxruntime"
        "${ONNXRUNTIME_EXTRACT_DIR}"  # Add our extracted directory
    )

    foreach(path ${ONNXRUNTIME_POSSIBLE_PATHS})
        set(config_path "${path}/lib/cmake/onnxruntime")
        # pretty_message_kv(STATUS "Checking path" "${config_path}")

        if(EXISTS "${config_path}/onnxruntimeConfig.cmake")
            pretty_message_kv(SUCCESS "Found onnxruntime config at" "${config_path}")

            list(APPEND CMAKE_PREFIX_PATH ${path})
            find_package(onnxruntime QUIET CONFIG PATHS ${path} NO_DEFAULT_PATH QUIET)

            if(onnxruntime_FOUND)
                pretty_message_kv(SUCCESS "onnxruntime loaded from" "${path}")
                pretty_message_kv(SUCCESS "onnxruntime version" "${onnxruntime_VERSION}")
                if (NOT ENABLE_GPU AND NOT ENABLE_CUDA)
                    pretty_message(TIP "Use -DENABLE_GPU=ON or -DENABLE_CUDA=ON to enable cuda for onnxruntime")
                endif()
                break()
            endif()
        endif()
    endforeach()

    if(NOT onnxruntime_FOUND)
        pretty_message(OPTIONAL "onnxruntime not found in local paths, using manual export")
    endif()
endif()

