include_guard(GLOBAL)

include(PrettySymbols)
include(PrettyColors)
# Colored Output
option(USE_CMAKE_COLORED_MESSAGES   "Enable colored messages in CMake output for this project" ON)
option(USE_CPP_COLORED_DEBUG_OUTPUT "Enable colored messages in Debug output for this project" ON)
option(ENABLE_EXTERNAL_FMT          "Enable external {fmt} (even though std fmt is available)" ON)
option(MESSAGE_PADDED               "Enable padded to align prefixes for pretty message"       ON)

set(_PRETTY_MESSAGE_MAX_LENGTH 105 CACHE STRING "Max message length for pretty_message"                          FORCE)
set(BANNER_WIDTH               80  CACHE STRING "Banner width affecting all pretty_message with banner or title" FORCE)
set(PRETTY_KV_ALIGN_COLUMN     40  CACHE STRING "The column where values start in pretty_message"                FORCE)

# Set equal width prefix
function(_pretty_message_get_padded_prefix _type _tags _output_var)
    set(_SEPARATOR " | ")
    set(_prefix_str "[${_type}]${_tags}")
    string(LENGTH "${_prefix_str}" _prefix_len)
    # Fixed width for every prefix(Tidier)
    set(_MAX_WIDTH 23)

    # Dynamic prefix width
    # set(_MIN_WIDTH 15)
    # if (_prefix_len GREATER _MIN_WIDTH)
    #     set(_MAX_WIDTH ${_prefix_len})
    # else()
    #     set(_MAX_WIDTH ${_MIN_WIDTH})
    # endif()

    math(EXPR _padding_len "${_MAX_WIDTH} - ${_prefix_len}")
    if (_padding_len LESS 0) 
        set(_padding_len 0)
    endif()

    set(_SPACES "                                        ")
    string(SUBSTRING "${_SPACES}" 0 ${_padding_len} _padding_spaces)
    set(${_output_var} "${_prefix_str}${_padding_spaces}${_SEPARATOR}" PARENT_SCOPE)
endfunction()

# Duplicated string line
function(_pretty_message_create_line char length output_var)
    set(line "")
    foreach(i RANGE ${length})
        string(APPEND line "${char}")
    endforeach()
    set(${output_var} "${line}" PARENT_SCOPE)
endfunction()

# Header line
function(_pretty_message_create_banner title char length output_var)
    set(content " ${title} ")
    string(LENGTH "${content}" content_len)

    if (${content_len} GREATER ${length})
        set(${output_var} "${content}" PARENT_SCOPE)
        return()
    endif()

    math(EXPR padding_total "${length} - ${content_len}")
    math(EXPR padding_left  "${padding_total} / 2")
    math(EXPR padding_right "${padding_tatal} - ${padding_left}")

    _pretty_message_create_line("${char}" ${padding_left}  left_str)
    _pretty_message_create_line("${char}" ${padding_right} right_str)

    set(banner "${left_str}${content}${right_str}")
    set(${output_var} "${banner}" PARENT_SCOPE)
endfunction()

# Output key-values in configurations
# Usage: pretty_message_kv(<TYPE> <Variable Name> <Variable Value>) 
function(pretty_message_kv TYPE KEY VALUE)
    set(key_part "  ${SYM_POINT_R} ${KEY}")

    string(LENGTH "${key_part}" key_len)

    math(EXPR padding_len "${PRETTY_KV_ALIGN_COLUMN} - ${key_len}")

    if (padding_len LESS 0)
        set(padding_len 1)
    endif()

    set(_SPACES "                                                                  ")
    string(SUBSTRING "${_SPACES}" 0 ${padding_len} padding_spaces)

    set(aligned_message "${key_part}:${padding_spaces}${VALUE}")

    pretty_message(${TYPE} "${aligned_message}")
endfunction()

# --- Customized Message Printer ---
# 1. Simple message output
# Usage: pretty_message(<TYPE> "Message......")
# Defined Type:
#   STATUS      (Blue Bold)         -  Normal (more eye-cathing than message(STATUS))
#   INFO        (Cyan)              -  Reference Info
#   VINFO       (Yellow)            -  CMake Variable Info 
#   SUCCESS     (Green Bold)        -  Successful
#   WARNING     (Yellow Bold)       -  Warning
#   ERROR       (Red Bold)          -  Not Fatal Error (With message(SEND_ERROR))
#   FATAL_ERROR (Red Bold)          -  Fatal Error (With message(FATAL_ERROR))
#   DEBUG       (Magenta)           -  Debug Info (Only effective in CMAKE_BUILD_TYPE as Debug)
#   IMPORTANT   (Magenta Bold)      - Important Tips 
#   DEFAULT     (Default Color)     -  Use message(STATUS) default action
# 2. Output fixed length headline(Title centered)
# Usage: pretty_message(<TYPE>_BANNER <Headline Content> <Headline Filler> <Headline Length>)
# 3. Output fixed length division
# Usage: pretty_message(<TYPE>_LINE <Division Content> <Division Length>)
function(pretty_message MESSAGE)
    if (ARGC EQUAL 1)
        # pretty_message("Message content")
        #   [MESSAGE] | Message content
        _pretty_message_core("MESSAGE" "${MESSAGE}")
        return()
    endif()

    if (ARGC EQUAL 2)
        _pretty_message_core("${MESSAGE}" "${ARGV1}")
    else()
        _pretty_message_core(${ARGV})
    endif()
endfunction()

function(_pretty_message_core TYPE MESSAGE)
   # Use ARGN to extract the params excluding TYPE and MESSAGE
    string(REGEX MATCH "(.+)_LINE$" _match_base_type ${TYPE})
    if (_match_base_type)
        set(BASE_TYPE ${CMAKE_MATCH_1})
        set(char "${MESSAGE}")
        list(GET ARGN 0 length)

        _pretty_message_create_line("${char}" ${length} line_str)
        pretty_message(${BASE_TYPE} "${line_str}")
        return()
    endif()
    
    string(REGEX MATCH "(.+)_BANNER$" _match_base_type ${TYPE})
    if (_match_base_type)
        set(BASE_TYPE ${CMAKE_MATCH_1})
        SET(title "${MESSAGE}")
        list(GET ARGN 0 char)
        list(GET ARGN 1 length)

        _pretty_message_create_banner("${title}" "${char}" ${length} banner_str)
        pretty_message(${BASE_TYPE} "${banner_str}")
        return()
    endif()

    if (${TYPE} STREQUAL "DEFAULT")
        message(STATUS "${MESSAGE}")
        return()
    endif()

    set(PREFIX "")
    set(COLOR  "")
    set(MSG_CMD "STATUS")

    set(_MAIN_TYPE "${TYPE}")
    set(_TAGS "")

    # Match variable tags in ${TYPE} in CRITICAL sequence
    # Example: 
    #       [_MAIN_TYPE][TAG_1][TAG_2]
    #       STATUS[Cython][Build]
    string(REGEX MATCH "^([A-Z_]+)((\\[[^]]*\\])*)" _MATCH_ALL "${TYPE}")
    if (CMAKE_MATCH_1)
        set(_MAIN_TYPE "${CMAKE_MATCH_1}")
        set(_TAGS "${CMAKE_MATCH_2}")
    endif()

    if (MESSAGE_PADDED)
        if (_MAIN_TYPE STREQUAL "OPTIONAL")
            _pretty_message_get_padded_prefix("WARNING" "${_TAGS}" PREFIX)
        else()
            _pretty_message_get_padded_prefix("${_MAIN_TYPE}" "${_TAGS}" PREFIX)
        endif()
    else()
        if (_MAIN_TYPE STREQUAL "OPTIONAL")
            set(PREFIX "[WARNING]${_TAGS}  | ")
        else()
            set(PREFIX "[${_MAIN_TYPE}]${_TAGS}  | ")
        endif()
    endif()

    if (${_MAIN_TYPE} STREQUAL "STATUS")
            set(COLOR   "${C_B_BLUE}")
        elseif (${_MAIN_TYPE} STREQUAL "INFO")
            set(COLOR   "${C_CYAN}")
        elseif (${_MAIN_TYPE} STREQUAL "VINFO")
            set(COLOR   "${C_YELLOW}")
        elseif (${_MAIN_TYPE} STREQUAL "SUCCESS")
            set(COLOR   "${C_B_GREEN}")
        elseif (${_MAIN_TYPE} STREQUAL "OPTIONAL")
            set(COLOR   "${C_YELLOW}")
        elseif (${_MAIN_TYPE} STREQUAL "TIP")
            set(COLOR   "${C_MAGENTA}")
        elseif (${_MAIN_TYPE} STREQUAL "WARNING")
            set(COLOR   "${C_B_YELLOW}")
            set(MSG_CMD "WARNING")
        elseif (${_MAIN_TYPE} STREQUAL "ERROR")
            set(COLOR   "${C_B_RED}")
            set(MSG_CMD "SEND_ERROR")
        elseif (${_MAIN_TYPE} STREQUAL "FATAL_ERROR")
            set(COLOR   "${C_B_RED}")
            set(MSG_CMD "FATAL_ERROR")
        elseif (${_MAIN_TYPE} STREQUAL "IMPORTANT")
            set(COLOR   "${C_B_MAGENTA}")
        elseif (${_MAIN_TYPE} STREQUAL "DEBUG")
            string(TOLOWER "${CMAKE_BUILD_TYPE}" _build_type_lower)
            if (NOT (_build_type_lower STREQUAL "debug" OR _build_type_lower STREQUAL "debug_mode"))
                return()
            endif()
            set(COLOR   "${C_MAGENTA}")
        
        else () # Undefined message type
            set(COLOR   "")
        endif()

        string(LENGTH "${MESSAGE}" _total_len)
        set(_current_pos 0)

        if (_total_len EQUAL 0)
            set(_total_len 1)
        endif()

        while (_current_pos LESS _total_len)
            math(EXPR _len_remaining "${_total_len} - ${_current_pos}")

            if (_len_remaining GREATER _PRETTY_MESSAGE_MAX_LENGTH)
                set(_chunk_len ${_PRETTY_MESSAGE_MAX_LENGTH})
            else()
                set(_chunk_len ${_len_remaining})
            endif()

            string(SUBSTRING "${MESSAGE}" ${_current_pos} ${_chunk_len} _current_line_message)

            if (USE_CMAKE_COLORED_MESSAGES)
                message(${MSG_CMD} "${COLOR}${PREFIX}${_current_line_message}${C_RESET}")
            else()
                message(${MSG_CMD} "${PREFIX}${_current_line_message}")
            endif()

            math(EXPR _current_pos "${_current_pos} + ${_chunk_len}")
        endwhile()
endfunction()

if (CMAKE_CXX_STANDARD GREATER_EQUAL 20)
    include(CheckCXXSourceCompiles)
    set(STD_FORMAT_TEST
    "
    #include <format>
    #include <string>
    #if !defined(__cpp_lib_format) || __cpp_lib_format < 201907L
    #endif

    int main() {
        std::string s = std::format(\"Hello, {}!\", \"world\");
        (void)s;
        return 0;
    }
    "
    )
    # Store them in case of 'check_cxx_source_compiles's side effect 
    set(CMAKE_REQUIRED_FLAGS_     ${CMAKE_REQUIRED_FLAGS})
    set(CMAKE_REQUIRED_LIBRARIES_ ${CMAKE_REQUIRED_LIBRARIES})

    check_cxx_source_compiles("${STD_FORMAT_TEST}" _HAS_STD_FORMAT)

    # Restore
    set(CMAKE_REQUIRED_FLAGS      ${CMAKE_REQUIRED_FLAGS_})
    set(CMAKE_REQUIRED_LIBRARIES  ${CMAKE_REQUIRED_LIBRARIES_})

    if (_HAS_STD_FORMAT)    # Enable cpp std format 
        set(HAVE_STD_FORMAT ON CACHE INTERNAL "std::format is avaible")
    else() 
        set(HAVE_STD_FORMAT OFF CACHE INTERNAL "std::format is unavaible")
    endif()
endif()


if (HAVE_STD_FORMAT)
    if (ENABLE_EXTERNAL_FMT)
        add_compile_definitions(USE_EXTERNAL_FMT=1)
    else()
        add_compile_definitions(USE_STD_FMT=1)
    endif()
else()
    add_compile_definitions(USE_EXTERNAL_FMT=1)
endif()

if (USE_CPP_COLORED_DEBUG_OUTPUT)
    add_compile_definitions(USE_CPP_COLORED_DEBUG_OUTPUT=1)
endif()


# Verbose Info
function(print_pretty_debug_info)
    pretty_message(DEBUG "PrettyPrint.cmake module loaded.")
    pretty_message(VINFO_BANNER "Pretty Message Info" "=" ${BANNER_WIDTH})
    pretty_message_kv(VINFO "USE_CMAKE_COLORED_MESSAGES"      "${USE_CMAKE_COLORED_MESSAGES} ")
    pretty_message_kv(VINFO "USE_CPP_COLORED_DEBUG_OUTPUT"    "${USE_CPP_COLORED_DEBUG_OUTPUT} ")
    pretty_message_kv(VINFO "ENABLE_EXTERNAL_FMT"             "${ENABLE_EXTERNAL_FMT}")
    pretty_message_kv(VINFO "PRETTY_MESSAGE_MAX_LENGTH"       "${_PRETTY_MESSAGE_MAX_LENGTH}")
    pretty_message_kv(VINFO "BANNER_WIDTH"                    "${BANNER_WIDTH}")    
    pretty_message_kv(VINFO "PRETTY_KV_ALIGN_COLUMN"          "${PRETTY_KV_ALIGN_COLUMN}")
    pretty_message_kv(VINFO "PRETTY_PRINT_USE_ASCII_FALLBACK" "${PRETTY_PRINT_USE_ASCII_FALLBACK}")
    if (NOT ENABLE_EXTERNAL_FMT)
    pretty_message(VINFO "  HAVE_STD_FORMAT:                ${HAVE_STD_FORMAT}")
    endif()
    pretty_message(VINFO_LINE "=" ${BANNER_WIDTH})
endfunction()
