include_guard(GLOBAL)

# Use string(ASCII <n>) to generate char to avoid invalid escape sequence of "/0"
string(ASCII 27 ESC) # ESC: 
                     #   ASCII Code: 27
                     #   HEX:        0x1B
                     #   OCT:        033
                     
# --- ANSI Color Code Definitions ----
if (USE_CMAKE_COLORED_MESSAGES AND (NOT WIN32 OR CMAKE_GENERATOR STREQUAL "Ninja" OR CMAKE_COLOR_MAKEFILE))
    set(C_RESET     "${ESC}[0m" )
    set(C_BLACK     "${ESC}[30m")
    set(C_RED       "${ESC}[31m")
    set(C_GREEN     "${ESC}[32m")
    set(C_YELLOW    "${ESC}[33m")
    set(C_BLUE      "${ESC}[34m")
    set(C_MAGENTA   "${ESC}[35m")
    set(C_CYAN      "${ESC}[36m")
    set(C_WHITE     "${ESC}[37m")

    # Bold/Bright
    set(C_B_BLACK   "${ESC}[1;30m")
    set(C_B_RED     "${ESC}[1;31m")
    set(C_B_GREEN   "${ESC}[1;32m")
    set(C_B_YELLOW  "${ESC}[1;33m")
    set(C_B_BLUE    "${ESC}[1;34m")
    set(C_B_MAGENTA "${ESC}[1;35m")
    set(C_B_CYAN    "${ESC}[1;36m")
    set(C_B_WHITE   "${ESC}[1;37m")
else()
    # For terminal not support colored output
    set(C_RESET     "")
    set(C_BLACK     "")
    set(C_RED       "")
    set(C_GREEN     "")
    set(C_YELLOW    "")
    set(C_BLUE      "")
    set(C_MAGENTA   "")
    set(C_CYAN      "")
    set(C_WHITE     "")

    set(C_B_BLACK   "")
    set(C_B_RED     "")
    set(C_B_GREEN   "")
    set(C_B_YELLOW  "")
    set(C_B_BLUE    "")
    set(C_B_MAGENTA "")
    set(C_B_CYAN    "")
    set(C_B_WHITE   "")
endif()
