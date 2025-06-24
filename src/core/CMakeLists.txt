cmake_minimum_required(VERSION 3.16)

module_begin("Core")

# =============== core configuration ===============
file(GLOB CORE_HEADERS
    "${CMAKE_SOURCE_DIR}/include/core/*.h"
    "${CMAKE_SOURCE_DIR}/include/core/*.hpp"
)

file(GLOB CORE_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

module_show_files("Headers" "${CORE_HEADERS}")
module_show_files("Sources" "${CORE_SOURCES}")

add_library(core
    SHARED
    ${CORE_HEADERS}
    ${CORE_SOURCES}
)

target_include_directories(core
    PUBLIC
    ${CMAKE_SOURCE_DIR}/include
    
)

target_link_libraries(core
    PUBLIC
)

auto_enable_pch(core core)

set_target_properties(core PROPERTIES
    VERSION     ${PROJECT_VERSION}
    SOVERSION   ${PROJECT_VERSION_MAJOR}
    OUTPUT_NAME "core"
)
# ===================================================

module_target_info(core SHOW_PROPERTIES)
module_show_dependencies(core)
module_end("Core" core SHOW_SUMMARY)