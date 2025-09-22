# CMake Toolchain

Add cmake configure options:
`-DCMAKE_TOOLCHAIN_FILE="*-toolchain.cmake"`

## Host Toolchain (Default GCC)

> default-toolchain.cmake

On Linux, like Ubuntu, ArchLinux, CentOS, the default host toolchain is gcc, matched tools of which are gcc(compiler), ld(linker), libstdc++(stdlib), abi integrated in libstdc++, gdb(debugger)
<details>
    <summary> Introduction(Chinese) </summary>
    在 Linux 操作系统上(像 Ubuntu, Archlinux, CentOS)的默认工具链为 GCC, 配套的工具有 gcc(编译器), ld(链接器), libstdc++(标准库), abi(集成在了libstdc++中), 调试器(debugger)
</details>

## Clang Toolchain

> clang-toolchain.cmake

Clang's matched tools are clang(compiler), lld(linker), libc++(stdlib), libc++abi(abi), debugger(lldb).

<details>
    <summary> Introduction(Chinese)</summary>
    Clang工具链配套的工具有 clang(编译器), lld(链接器), libc++(标准库), libc++abi(abi), lldb(调试器)
</details>

## Cross-compile Toolchain

### Android NDK Toolchain

> android-ndk-toolchain.cmake

Android native development kit is composed of llvm(AKA clang), thus, NDK toolchain is similar to clang toolchain.
<details>
    <summary>Introduction(Chinese)</summary>
    安卓 NDK 交叉编译工具链是由llvm工具链构成的,和Clang是差不多的
</details>

### Mingw64 Toolchain

> mingw-w64-toolchain.cmake

mingw-w64 is a transplanted GCC from Linux for Windows to cross-compile or native-compile for Windows.

<details>
    <summary>Introduction(Chinese)</summary>
    mingw-w64工具链是移植与Linux为Windows设计的GCC工具链,可用于交叉编译或者Windows上本地编译
</details>
