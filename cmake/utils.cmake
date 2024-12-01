# ----- Add a target for formating the project using `clang-format`. ----- #
# ----- (i.e.: cmake --build build --target clang-format)            ----- #

if (${PROJECT_NAME}_ENABLE_CLANG_FORMAT)
    find_program(CLANG_FORMAT_PROGRAM clang-format)
    if (CLANG_FORMAT_PROGRAM-NOTFOUND)
        message(FATAL_ERROR "Clang-format not found !!")
    endif ()
    add_custom_target(CLANG_FORMAT
        COMMAND ${CLANG_FORMAT_PROGRAM}
            -i  ${APP_SOURCES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )
    message(STATUS "Clang-format target added.")
endif ()
