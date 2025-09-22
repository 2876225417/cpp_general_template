cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_LIST_DIR}"
    "${CMAKE_CURRENT_LIST_DIR}/core"
    "${CMAKE_CURRENT_LIST_DIR}/core/python"
    "${CMAKE_CURRENT_LIST_DIR}/deps"
    "${CMAKE_CURRENT_LIST_DIR}/misc"
    "${CMAKE_CURRENT_LIST_DIR}/test"
)

# Cross-compile
# include(mingw-w64-toolchain)

include(PrettyPrint)

# core
include(ProjectVerbose)
include(ProjectInfo)
include(PCH)
include(PythonConfig)
include(CythonConfig)
include(CompileOptions)
include(BuildConfig)

# deps
include(DependencyManager)

dependency_manager_init()

# misc
include(ModuleInfo)

include(QtInfo)

# test
include(PerfTools)
include(ValgrindTools)


# GLOBAL CONFIGS

# TARGET CONFIGS




