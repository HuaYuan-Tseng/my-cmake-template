# ----- Clang-tidy ----- #

if (${PROJECT_NAME}_ENABLE_CLANG_TIDY)
    find_program(CLANG_TIDY_PROGRAM clang-tidy)
    if (CLANG_TIDY_PROGRAM-NOTFOUND)
        message(FATAL_ERROR "clang-tidy not found !!")
    else ()
        set(CLANG_TIDY_COMMAND
            ${CLANG_TIDY_PROGRAM};
            --use-color;
            --extra-arg=-Wno-unknown-warning-option;
        )
        if (${PROJECT_NAME}_ENABLE_CLANG_TIDY_WHEN_BUILD)
            set_source_files_properties(
                ${APP_SOURCES}
                ${TESTING_SOURCES}
                PROPERTIES
                CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}"
            )
        endif ()
        add_custom_target(CLANG_TIDY
            COMMAND ${CLANG_TIDY_COMMAND}
                ${APP_SOURCES}
                ${TESTING_SOURCES}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )
        message(STATUS "Clang-tidy finished setting up.")
    endif ()
endif ()

# ----- Cppcheck ----- #

if (${PROJECT_NAME}_ENABLE_CPPCHECK)
    find_program(CPPCHECK_PROGRAM cppcheck)
    if (CPPCHECK)
        message(FATAL_ERROR "cppcheck not found !!")
    else ()
        if (UNIX)
            set(CPPCHECK_PLATFORM "unix64")
        else ()
            set(CPPCHECK_PLATFORM "win64")
        endif ()
        set(CPPCHECK_COMMAND
            ${CPPCHECK_PROGRAM};
            --platform=${CPPCHECK_PLATFORM};
            --enable=all;
            --std=c++20;
            --inconclusive;
            --suppress=missingInclude;
            --suppress=missingIncludeSystem;
            --inline-suppr;  # Ex: // cppcheck-suppress warningId
        )
        if (${PROJECT_NAME}_ENABLE_CPPCHECK_WHEN_BUILD)
            set_source_files_properties(
                ${APP_SOURCES}
                PROPERTIES
                CMAKE_CXX_CPPCHECK "${CPPCHECK_COMMAND}"
            )
        endif ()
        add_custom_target(CPPCHECK
            COMMAND ${CPPCHECK_COMMAND}
                ${APP_SOURCES}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )
        message(STATUS "Cppcheck finished setting up.")
    endif ()
endif ()
