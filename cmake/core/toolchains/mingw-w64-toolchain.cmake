include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  x86_64-w64-mingw32-windres)

set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)
set(CMAKE_PREFIX_PATH /usr/x86_64-w64-mingw32)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

find_program(PKG_CONFIG_EXECUTABLE x86_64-w64-mingw32-pkg-config)
if (NOT PKG_CONFIG_EXECUTABLE)
    pretty_message(WARNING "Cross-compiling pkg-config not found. Dependencies using pkg-config might fail.")
endif()

set(Python_ROOT_DIR # Python executable for cross-compile 
    "/usr/x86_64-w64-mingw32/bin" 
    CACHE PATH 
    "Root directory of the target Python installed."
)