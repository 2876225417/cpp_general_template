include_guard(GLOBAL)

function(add_test_with_valgrind TARGET_NAME)
    find_program(VALGRIND_EXECUTABLE valgrind)

    if (VALGRIND_EXECUTABLE)
        add_test(
            NAME MemoryCheck.${TARGET_NAME}
            COMMAND ${VALGRIND_EXECUTABLE}
                    --leak-check=full
                    --show-leak-kinds=all
                    --track-origins=yes
                    --error-exitcode=1
                    $<TARGET_FILE:${TARGET_NAME}>
        )
        
        set_tests_properties(
            MemoryCheck.${TARGET_NAME}
            PROPERTIES LABELS "MEMORY_CHECK"
        )
    endif()
endfunction()
