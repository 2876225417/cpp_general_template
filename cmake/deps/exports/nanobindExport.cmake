include_guard(GLOBAL)

find_package(Python COMPONENTS Interpreter Development REQUIRED)

set(NANONBIND_POSSIBLE_PATHS
    "${DEPENDENCY_ROOT_DIR}/nanobind/linux-x86_64"
    "${DEPENDENCY_ROOT_DIR}/nanobind/build"
    "${DEPENDENCY_ROOT_DIR}/nanobind/install"
    "${DEPENDENCY_ROOT_DIR}/nanobind"
)

foreach(path ${NANONBIND_POSSIBLE_PATHS})
    set(config_path "${path}/nanobind/cmake")
    if (EXISTS "${config_path}/nanobind-config.cmake")
        pretty_message_kv(SUCCESS "Found nanobind config at" "${config_path}")
        list(APPEND CMAKE_PREFIX_PATH ${path})
        find_package(nanobind QUIET CONFIG PATHS ${path} NO_DEFAULT_PATH)
        if (nanobind_FOUND)
            pretty_message_kv(SUCCESS "nanobind loaded from" "${path}")
            pretty_message_kv(SUCCESS "nanobind version" "${nanobind_VERSION}")
            # Issues: find_package(nanobind ...)
            #   can not export the include directories to the other(neither parent scope)
            #   so we force to set nanobind_INCLUDE_DIRS as a global string cache
            #   to make it observable for all files to be included
            #   !!! only for the local compiled 3rdparty like nanobind
            set(nanobind_INCLUDE_DIRS "${path}/nanobind/include" CACHE STRING "nanobind" FORCE)
            break()
        endif()
    endif()
endforeach()

if (NOT nanobind_FOUND)
    pretty_message(OPTIONAL "nanobind not found in local paths")
endif()

