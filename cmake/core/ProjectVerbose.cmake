include_guard(GLOBAL)

option(ENABLE_DEPRECATED_INFO "Enable deprecated info in project" ON)

if (ENABLE_DEPRECATED_INFO)
    add_compile_definitions(_DEPRECATED_INFO_=1)
endif()

function(project_verbose_module_detail)
    pretty_message(DEBUG "ProjectVerbose.cmake module loaded.")
    pretty_message(VINFO_BANNER "ProjectVerbose Configuration" "=" ${BANNER_WIDTH})
    pretty_message_kv(VINFO "ENABLE_DEPRECATED_INFO" "${ENABLE_DEPRECATED_INFO}")
    pretty_message(VINFO_BANNER "=" ${BANNER_WIDTH})
endfunction()
