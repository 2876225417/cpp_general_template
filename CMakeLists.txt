cmake_minimum_required(VERSION 3.20) # CMake with version 3.19 or higher to support CMakePresets.json

#############################################
#                                           #
#       Name:   Queue Web Quest             #
#                                           #
#       Author: ppQwQqq                     #
#                                           #
#                                           #
#############################################

project(QueueWebQuest   LANGUAGES C CXX)

set(CMAKE_PROJECT_VERSION 0.0.1)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_BUILD_PARALLEL_LEVEL 8)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release"
        CACHE STRING
        "Build types(Debug, Release, RelWithDebInfo)"
        FORCE)
endif()

option(BUILD_TESTS "Build tests" OFF)

include(cmake/Config.cmake)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/extensions)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

pretty_message(VINFO_BANNER "Compiler Info" "=" ${BANNER_WIDTH})
pretty_message_kv(VINFO "CMAKE_GENERATOR"                "${CMAKE_GENERATOR}")
pretty_message_kv(VINFO "CMAKE_CXX_STANDARD"             "${CMAKE_CXX_STANDARD}")
pretty_message_kv(VINFO "CMAKE_CXX_COMPILER"             "${CMAKE_CXX_COMPILER}")
pretty_message_kv(VINFO "CMAKE_CXX_COMPILER_VERSION"     "${CMAKE_CXX_COMPILER_VERSION}")
pretty_message_kv(VINFO "CMAKE_LINKER"                   "${CMAKE_LINKER}")
pretty_message_kv(VINFO "CMAKE_AR"                       "${CMAKE_AR}")
pretty_message_kv(VINFO "CMAKE_CXX_BYTE_ORDER"           "${CMAKE_CXX_BYTE_ORDER}")
pretty_message_kv(VINFO "CMAKE_CXX_COMPILER_ABI"         "${CMAKE_CXX_COMPILER_ABI}")
pretty_message_kv(VINFO "CMAKE_BUILD_TYPE"               "${CMAKE_BUILD_TYPE}")
pretty_message_kv(VINFO "CMAKE_RUNTIME_OUTPUT_DIRECTORY" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
pretty_message(VINFO_LINE "=" ${BANNER_WIDTH})
pretty_message(STATUS "")

find_dependency(Boost REQUIRED)
find_dependency(OpenSSL REQUIRED)
find_dependency(ONNXRuntime REQUIRED)



add_subdirectory(${CMAKE_SOURCE_DIR}/src)

if (BUILD_TESTS)
    add_subdirectory(${CMAKE_SOURCE_DIR}/tests)
endif()

