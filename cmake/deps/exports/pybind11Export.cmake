include_guard(GLOBAL)

set(PYBIND11_FINDPYTHON ON)

set(PYBIND11_POSSIBLE_PATHS
    "${DEPENDENCY_ROOT_DIR}/pybind11/linux-x86_64"
    "${DEPENDENCY_ROOT_DIR}/pybind11/build"
    "${DEPENDENCY_ROOT_DIR}/pybind11/install"
    "${DEPENDENCY_ROOT_DIR}/pybind11"
)

foreach(path ${PYBIND11_POSSIBLE_PATHS})
    set(config_path "${path}/share/cmake/pybind11")
    if (EXISTS "${config_path}/pybind11Config.cmake")
        pretty_message_kv(SUCCESS "Found pybind11 config at" "${config_path}")
        list(APPEND CMAKE_PREFIX_PATH ${path})
        find_package(pybind11 QUIET CONFIG PATHS ${path} NO_DEFAULT_PATH)
        if (pybind11_FOUND)
            pretty_message_kv(SUCCESS "pybind11 loaded from" "${path}")
            pretty_message_kv(SUCCESS "pybind11 version" "${pybind11_VERSION}")
            break()
        endif()
    endif()
endforeach()

if (NOT pybind11_FOUND)
    pretty_message(OPTIONAL "pybind11 not found in local paths")
endif()

