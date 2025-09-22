include_guard(GLOBAL)

# Compiler Detection
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(COMPILER_IS_CLANG TRUE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(COMPILER_IS_GCC TRUE)
    # elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC") # TODO(ppqwqqq): Support MSVC...
endif()

# Aggressive and Modern C++
set(WARNING_FLAGS
    -Wall
    -Wextra
    -Wpedantic
    -Wcast-align
    -Wcast-qual
    -Wctor-dtor-privacy
    -Wdisabled-optimization
    -Wformat=2
    -Winit-self
    -Wlogical-op
    -Wmissing-include-dirs
    -Wnoexcept
    -Wold-style-cast
    -Woverloaded-virtual
    -Wredundant-decls
    -Wshadow
    -Wsign-conversion
    -Wsign-promo
    -Wstrict-null-sentinel
    -Wstrict-overflow=5
    -Wsuggest-override
    -Wswitch-default
    -Wundef
    -Wunreachable-code
    -Wunused
    -Wuseless-cast
    -Wzero-as-null-pointer-constant
    
    -Wdouble-promotion
    -Wnull-dereference
    -Wduplicated-branches
    -Wduplicated-cond
    -Wfloat-equal
    -Wunsafe-loop-optimizations
    -Wvector-operation-performance
)

if(COMPILER_IS_GCC)
    list(APPEND WARNING_FLAGS
        -Wtrampolines
        -Wstack-usage=4096
        -Wsuggest-final-types
        -Wsuggest-final-methods
        -Walloc-zero
        -Warith-conversion
    )
endif()

if(COMPILER_IS_CLANG)
    list(APPEND WARNING_FLAGS
        -Wheader-hygiene
        -Wcomma
        -Wimplicit-fallthrough
        -Wcovered-switch-default
        -Winconsistent-missing-destructor-override
        -Wnon-virtual-dtor
        -Wundefined-func-template
    )
endif()

set(DEBUG_COMPILE_FLAGS
    -g3
    -O0
    -fno-omit-frame-pointer
    -fno-optimize-sibling-calls
    -fstack-protector-strong
)

set(DEBUG_LINK_FLAGS)
if(UNIX AND NOT APPLE)
    # On Linux, enable sanitizers
    list(APPEND DEBUG_COMPILE_FLAGS
        -fsanitize=address,undefined,leak
        -fno-sanitize-recover=all
    )
    list(APPEND DEBUG_LINK_FLAGS
        -fsanitize=address,undefined,leak
    )
endif()

set(DEBUG_DEFINITIONS
    DEBUG_MODE
    _GLIBCXX_DEBUG
    -GLIBCXX_ASSERTIONS
 )

set(RELEASE_COMPILE_FLAGS
    -O3
    -DNDEBUG
    -flto=auto
    -march=native
    -mtune=native
    -ffunction-sections
    -fdata-sections
)

set(RELEASE_LINK_FLAGS
    -flto=auto
    -Wl,--gc-sections
)

set(RELEASE_DEFINITIONS
    NDEBUG
)

set(RELWITHDEBINFO_COMPILE_FLAGS
    -O2
    -g
    -DNDEBUG
    -fno-omit-frame-pointer
)

set(RELWITHDEBINFO_DEFINITIONS
    NDEBUG
)

function(target_apply_options TARGET_NAME)
    # Require C++23 standard
    target_compile_features(${TARGET_NAME} PUBLIC cxx_std_23)
    
    # Apply all warnings
    target_compile_options(${TARGET_NAME} PRIVATE ${WARNING_FLAGS})

    # Apply flags
    target_compile_options(${TARGET_NAME} PRIVATE
        $<$<CONFIG:Debug>:${DEBUG_COMPILE_FLAGS}>
        $<$<CONFIG:Release>:${RELEASE_COMPILE_FLAGS}>
        $<$<CONFIG:RelWithDebInfo>:${RELWITHDEBINFO_COMPILE_FLAGS}>
    )
    
    # Apply linker flags
    target_link_options(${TARGET_NAME} PRIVATE
        $<$<CONFIG:Debug>:${DEBUG_LINK_FLAGS}>
        $<$<CONFIG:Release>:${RELEASE_LINK_FLAGS}>
    )

    # Apply definitions
    target_compile_definitions(${TARGET_NAME} PRIVATE
        $<$<CONFIG:Debug>:${DEBUG_DEFINITIONS}>
        $<$<CONFIG:Release>:${RELEASE_DEFINITIONS}>
        $<$<CONFIG:RelWithDebInfo>:${RELWITHDEBINFO_DEFINITIONS}>
    )

endfunction()

