include_guard(GLOBAL)

function(add_cython_extension target_name)
    set(options)
    set(oneValueArgs SOURCE)
    set(multiValueArgs INCLUDE_DIRS LINK_LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Generate C++ files using Cython
    add_custom_command( # command: cython --cplus -- output-file
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.cpp
        COMMAND ${CYTHON_EXECUTABLE}
            --cplus
            --output-file ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.cpp
            ${ARG_SOURCE}
        DEPENDS ${ARG_SOURCE}
        COMMENT "Generating ${target_name}.cpp with Cython"
    )

    # Generate module
    add_library(${target_name} MODULE # Specific for Python extensions
        ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.cpp
    )

    # Set properties
    set_target_properties(${target_name} PROPERTIES
        PREFIX ""
        OUTPUT_NAME "${target_name}"
    )

    # Link libraries
    if(ARG_LINK_LIBRARIES)
        target_link_libraries(${target_name} ${ARG_LINK_LIBRARIES})
    endif()

    # Include directories
    if(ARG_INCLUDE_DIRS)
        target_include_directories(${target_name} PRIVATE 
            ${ARG_INCLUDE_DIRS}
        )
    endif()

    # Add Python include directories
    target_include_directories(${target_name} PRIVATE 
        ${Python3_INCLUDE_DIRS}
    )

    # Compile options
    target_compile_options(${target_name} PRIVATE
        $<$<CXX_COMPILER_ID:GNU>:-fPIC>
        $<$<CXX_COMPILER_ID:Clang>:-fPIC>
    )
endfunction()

