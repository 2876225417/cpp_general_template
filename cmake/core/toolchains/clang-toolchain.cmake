include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux)

find_program(CMAKE_C_COMPILER clang)
find_program(CMAKE_CXX_COMPILER clang++)

if (NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER)
    pretty_message(FATAL "Could not find Clang compiler (clang/clang++).")
endif()

# Install lld if not installed
set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    -fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=lld")
# Install libc++abi if not installed
set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    -lc++abi")

find_program(CMAKE_AR llvm-ar)
find_program(CMAKE_RANLIB llvm-ranlib)

