include_guard(GLOBAL)

function(add_test_with_perf_stat TARGET_NAME)
    find_program(PERF_EXECUTABLE perf)
    
    if (PERF_EXECUTABLE)
        set(TEST_NAME "PerfStat.${TARGET_NAME}")

        add_test(
            NAME ${TEST_NAME}
            COMMAND ${PERF_EXECUTABLE} stat
                    -d # --detailed
                    --log-fd 1 # standard output
                    $<TARGET_FILE:${TARGET_NAME}>
        )

        set_tests_properties(
            ${TEST_NAME}
            PROPERTIES LABELS "PERF_STAT"
        )
    endif()
endfunction()

function(add_profiling_target_with_perf_record TARGET_NAME)
    find_program(PERF_EXECUTABLE perf)

    if (PERF_EXECUTABLE)
        set(PROFILE_TARGET_NAME "profile_${TARGET_NAME}")

        set(PERF_DATA_FILE "perf.${TARGET_NAME}.data")

        add_custom_target(${PROFILE_TARGET_NAME}
            COMMAND ${PERF_EXECUTABLE} record -g -o ${PERF_DATA_FILE} -- $<TARGET_FILE:${TARGET_NAME}>
            DEPENDS ${TARGET_NAME}
            COMMENT "Profiling '${TARGET_NAME}' with perf record'.\nRun 'perf report' after execution to analyze the generated perf.data file."
        )
    endif()
endfunction()
