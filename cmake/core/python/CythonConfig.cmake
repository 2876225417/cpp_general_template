include_guard(GLOBAL)

option(USE_CYTHON "Enable Cython extension" OFF)

set(CYTHON_FOUND FALSE)
set(CYTHON_EXECUTABLE "")
set(CYTHON_VERSION "")

function(cython_config_module_detail)
    pretty_message(DEBUG "CythonConfig.cmake module loaded.")
    if (CYTHON_FOUND AND USE_CYTHON)
        pretty_message(VINFO_BANNER "Cython Module" "=" ${BANNER_WIDTH})
        pretty_message_kv(VINFO " - Version" "${CYTHON_VERSION}")
        pretty_message_kv(VINFO " - Executable" "${CYTHON_EXECUTABLE}")
        pretty_message_kv(VINFO " - Python Version" "${Python_VERSION}")
        pretty_message(VINFO_LINE "=" ${BANNER_WIDTH})
    endif()
endfunction()

if (USE_PYTHON AND USE_CYTHON)
    if (NOT Python_FOUND) # Make sure Python configured
        pretty_message(WARNING "Python not found. Cython support disabled.")
        set(USE_CYTHON OFF)
    else()
        # Execute "python -m cython --version" to get verbose info
        pretty_message(DEBUG "Python executable for cython: ${Python_EXECUTABLE}")

        execute_process(
            COMMAND ${Python_EXECUTABLE} -m cython --version
            OUTPUT_VARIABLE CYTHON_VERSION_OUTPUT
            ERROR_VARIABLE  CYTHON_VERSION_OUTPUT
            RESULT_VARIABLE CYTHON_VERSION_RESULT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            TIMEOUT 10
        )

        if (CYTHON_VERSION_RESULT EQUAL 0)
            pretty_message(DEBUG "Found Cython via Python module")
            set(CYTHON_EXECUTABLE ${Python_EXECUTABLE} -m cython)
            set(CYTHON_VIA_PYTHON_MODULE TRUE)
            set(CYTHON_FOUND TRUE)

            string(REGEX MATCH "([0-9]+\\.[0-9]+\\.[0-9]+)" CYTHON_VERSION "${CYTHON_VERSION_OUTPUT}")
            if (NOT CYTHON_VERSION)
                string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" CYTHON_VERSION "${CYTHON_VERSION_OUTPUT}")
            endif()
        else() # Failed to get cython via Python module
            pretty_message(DEBUG "Trying find_program for cython")
            find_program(CYTHON_EXECUTABLE
                NAMES cython cython3
                DOC "Cython compiler"
            )

            if (CYTHON_EXECUTABLE)
                pretty_message(DEBUG "Found Cython via find_program: ${CYTHON_EXECUTABLE}")

                execute_process(
                    COMMAND ${CYTHON_EXECUTABLE} --version
                    OUTPUT_VARIABLE CYTHON_VERSION_OUTPUT
                    ERROR_VARIABLE  CYTHON_VERSION_OUTPUT
                    RESULT_VARIABLE CYTHON_VERSION_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_STRIP_TRAILING_WHITESPACE
                )

                if (CYTHON_VERSION_RESULT EQUAL 0)
                    string(REGEX MATCH "([0-9]+\\.[0-9]+\\.[0-9]+)" CYTHON_VERSION "${CYTHON_VERSION_OUTPUT}")
                    if (NOT CYTHON_VERSION)
                        string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" CYTHON_VERSION "${CYTHON_VERSION_OUTPUT}")
                    endif()
                    set(CYTHON_FOUND TRUE)
                else()
                    pretty_message(WARNING "Failed to get Cython version.")
                    set(CYTHON_EXECUTABLE "")
                endif()
            endif()
        endif()

        if (CYTHON_FOUND)
            pretty_message("STATUS" "Found cython: ${CYTHON_EXECUTABLE}(version ${CYTHON_VERSION})")
            add_compile_definitions(USE_CYTHON=1)
        else()
            pretty_message(WARNING "Cython not found. Please install Cython for current env(pip install cython).")
        endif()
    endif()
endif()

if (USE_CYTHON)
    if (NOT CYTHON_FOUND)
        pretty_message(STATUS "Cython support disabled due to missing Cython executable.")
        set(USE_CYTHON OFF)
    endif()
endif()

function(add_cython_extension target_name)
    if (NOT USE_CYTHON OR NOT CYTHON_FOUND)
        pretty_message(WARNING "Cython extension '${target_name}' not created: Cython not available.")
        return()
    endif()

    set(options)
    set(oneValueArgs SOURCE OUTPUT_NAME)
    set(multiValueArgs INCLUDE_DIRS LINK_LIBRARIES COMPILE_OPTIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARG_OUTPUT_NAME)
        set(ARG_OUTPUT_NAME "${target_name}")
    endif()

    if (NOT ARG_SOURCE)
        pretty_message(FATAL_ERROR "No SOURCE specified for Cython extension '${target_name}'")
    endif()

    # Generate C++ files using Cython
    set(GENERATED_CPP "${CMAKE_CURRENT_BINARY_DIR}/${ARG_OUTPUT_NAME}.cpp")
    add_custom_command( # command: cython --language c++ -- output-file
        OUTPUT ${GENERATED_CPP}
        COMMAND ${CYTHON_EXECUTABLE}
            --cplus
            -o ${GENERATED_CPP}
            # $<$<BOOL:${CYTHON_DEBUG}>:--verbose>
            ${ARG_SOURCE}
        DEPENDS ${ARG_SOURCE}
        COMMENT "Generating ${target_name}.cpp from ${ARG_SOURCE} with Cython"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    # Generate module
    add_library(${target_name} MODULE # Specific for Python extensions
        ${GENERATED_CPP}
    )

    # Set properties
    set_target_properties(${target_name} PROPERTIES
        PREFIX ""
        OUTPUT_NAME "${ARG_OUTPUT_NAME}"
    )

    # Link libraries
    if (ARG_LINK_LIBRARIES)
        target_link_libraries(${target_name} ${ARG_LINK_LIBRARIES})
    endif()

    # Include directories
    if (ARG_INCLUDE_DIRS)
        target_include_directories(${target_name} PRIVATE
            ${ARG_INCLUDE_DIRS}
        )
    endif()

    target_include_directories(${target_name} PRIVATE
        ${Python_INCLUDE_DIRS}
    )

    # Compile options
    target_compile_options(${target_name} PRIVATE
        $<$<CXX_COMPILER_ID:GNU>:-fPIC>
        $<$<CXX_COMPILER_ID:Clang>:-fPIC>
    )

    if (ARG_COMPILE_OPTIONS)
        target_compile_options(${target_name} PRIVATE
            ${ARG_COMPILE_OPTIONS}
        )
    endif()

    # C++ standard
    if (CMAKE_CXX_STANDARD)
        set_target_properties(${target_name} PROPERTIES
            CXX_STANDARD ${CMAKE_CXX_STANDARD}
            CXX_STANDARD_REQUIRED ON
        )
    endif()

    pretty_message(DEBUG "Created Cython extension target '${target_name}'")
endfunction()

