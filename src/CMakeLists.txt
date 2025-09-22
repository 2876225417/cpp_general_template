add_subdirectory(core)
add_subdirectory(qinfer)

add_executable(qweb_quest
    main.cpp
)


target_include_directories(qweb_quest
    PRIVATE
    ${CMAKE_SOURCE_DIR}/include/core
)

target_link_libraries(qweb_quest
    PRIVATE
    core
)




