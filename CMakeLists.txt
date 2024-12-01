cmake_minimum_required(VERSION 3.16)
cmake_policy(SET CMP0135 NEW)

project(MyCmakeTemplate
    VERSION 0.0.1
    LANGUAGES C CXX
)

# ---------------------------------------------------------------------------------------
# Include guards.
# ---------------------------------------------------------------------------------------

if (PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(
        FATAL_ERROR
        "In-source builds not allowed. \
        Please make a new directory (called a build directory) \
        and run CMake from there."
    )
endif ()

# ---------------------------------------------------------------------------------------
# Set project options.
# ---------------------------------------------------------------------------------------

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_DEBUG_POSTFIX "")
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Enable unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Setup alternatives name.
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWER)
string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

# ---------------------------------------------------------------------------------------
# Include other cmake files.
# ---------------------------------------------------------------------------------------

# Generate the sources_and_headers.cmake file.
execute_process(
    COMMAND bash ${CMAKE_SOURCE_DIR}/cmake/generate_sources.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE GENERATE_SOURCES_RESULT
    ERROR_VARIABLE GENERATE_SOURCES_ERROR
)

if (NOT GENERATE_SOURCES_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to generate the sources and headers files: ${GENERATE_SOURCES_ERROR}")
endif ()

include(cmake/standard_settings.cmake)
include(cmake/sources_and_headers.cmake)
include(cmake/utils.cmake)
include(cmake/static_analyzers.cmake)
include(cmake/compiler_warnings.cmake)

# ---------------------------------------------------------------------------------------
# Export compile commands.
# ---------------------------------------------------------------------------------------

# This option (CMAKE_EXPORT_COMPILE_COMMANDS) is implemented only by
# Makefile Generators and the Ninja. It is ignored on other generators!!!
if (${PROJECT_NAME}_EXPORT_COMPILE_COMMANDS)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif ()

# ---------------------------------------------------------------------------------------
# Set building type.
# ---------------------------------------------------------------------------------------

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif ()

# This will allow to use same _DEBUG macro available in both Linux
# as well as Windows - MSCV environment. Easy to put Debug specific code.
if (UNIX)
    add_compile_options("$<$<CONFIG:DEBUG>:-D_DEBUG>")
endif ()

# ---------------------------------------------------------------------------------------
# Set output directories.
# ---------------------------------------------------------------------------------------

set(OS_NAME ${CMAKE_SYSTEM_NAME} CACHE STRING "The name of the operating system.")
set(OS_VERSION ${CMAKE_SYSTEM_VERSION} CACHE STRING "The version of the operating system.")
string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} CMAKE_SYSTEM_PROCESSOR_LOWER)

set(OS_FOLDER_NAME "")
if (WIN32)
    if (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "x86_64" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "amd64")
        set(OS_FOLDER_NAME "win-amd64")
    elseif (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "arm64" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "aarch64")
        set(OS_FOLDER_NAME "win-arm64")
    else ()
        message(FATAL_ERROR "Cannot identify CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR_LOWER}")
    endif ()
elseif (UNIX AND NOT APPLE)
    string(REPLACE "." "" OS_VERSION_NEW ${OS_VERSION})
    if (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "x86_64" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "amd64")
        set(OS_FOLDER_NAME "${OS_NAME}-amd64")
    elseif (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "arm" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "aarch64")
        set(OS_FOLDER_NAME "${OS_NAME}-arm64v8")
    else ()
        message(FATAL_ERROR "Cannot identify CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR_LOWER}")
    endif ()
elseif (APPLE)
    if (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "x86_64" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "amd64")
        set(OS_FOLDER_NAME "mac-amd64")
    elseif (CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "arm" OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "aarch64")
        set(OS_FOLDER_NAME "mac-arm64")
    else ()
        message(FATAL_ERROR "Cannot identify CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR_LOWER}")
    endif ()
endif ()

# First for the generic no-config case (e.g. with mingw)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
# Second, for multi-config builds (e.g. msvc)
foreach (OUTPUT_CONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUT_CONFIG} OUTPUT_CONFIG)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUT_CONFIG} ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUT_CONFIG} ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUT_CONFIG} ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
    set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_${OUTPUT_CONFIG} ${CMAKE_SOURCE_DIR}/bin/${OS_FOLDER_NAME}/${CMAKE_BUILD_TYPE})
endforeach ()

# ---------------------------------------------------------------------------------------
# Setup dependencies.
# ---------------------------------------------------------------------------------------

include(FetchContent)

# All the include statements about following 'FetchContent' will show warning
# before run the 'cmake' first time.
find_package(Catch2 3 QUIET)
if (NOT Catch2_FOUND)
    message(WARNING "Catch2 for version 3.x not found, will download it.")
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.7.1
    )
    set(BUILD_TESTING OFF CACHE BOOL "Do not build Catch2's tests")
    set(CATCH_INSTALL_DOCS OFF CACHE BOOL "Do not install Catch2's documentation")
    set(CATCH_INSTALL_EXTRAS OFF CACHE BOOL "Do not install Catch2's extras folder")
    set(CATCH_DEVELOPMENT_BUILD OFF CACHE BOOL "Do not configure Catch2 for development")
    FetchContent_MakeAvailable(Catch2)
endif ()

find_package(spdlog CONFIG QUIET)
if (NOT spdlog_FOUND)
    message(WARNING "spdlog not found, will download it.")
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY  https://github.com/gabime/spdlog.git
        GIT_TAG         v1.15.0
    )
    set(SPDLOG_BUILD_SHARED ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(spdlog)
endif ()

# ---------------------------------------------------------------------------------------
# Headers and sources.
# ---------------------------------------------------------------------------------------

# app.

add_executable(${PROJECT_NAME_LOWER}-app "")
target_sources(${PROJECT_NAME_LOWER}-app
    PRIVATE
    ${APP_SOURCES}
)
target_include_directories(${PROJECT_NAME_LOWER}-app
    PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)
target_link_libraries(${PROJECT_NAME_LOWER}-app
    PRIVATE
    spdlog::spdlog
)
if (UNIX AND NOT APPLE)
    target_link_libraries(${PROJECT_NAME_LOWER}-app
        PRIVATE
        pthread
    )
endif ()

# ---------------------------------------------------------------------------------------
# Set the building and warning options.
# ---------------------------------------------------------------------------------------

if (UNIX)
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0")
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0")
    elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
    endif ()
elseif (MSVC)
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /Od /Zi")
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Od /Zi")
    elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /O2")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2")
    endif ()

    set(CMAKE_EXE_LINKER_FLAGS_DEBUG "/DEBUG /INCREMENTAL:NO /SUBSYSTEM:CONSOLE")
    set(CMAKE_STATC_LINKER_FLAGS_DEBUG "/DEBUG /INCREMENTAL:NO /SUBSYSTEM:CONSOLE")
    set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "/DEBUG /INCREMENTAL:NO /SUBSYSTEM:CONSOLE")
    set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "/DEBUG /INCREMENTAL:NO /SUBSYSTEM:CONSOLE")

    if (MSVC_VERSION GREATER_EQUAL 1914)
        target_compile_options(${PROJECT_NAME_LOWER}-app PRIVATE "/Zc:__cplusplus" "/Zc:nrvo" "/FS")
    endif ()

    set_target_properties(${PROJECT_NAME_LOWER}-app PROPERTIES WIN32_EXECUTABLE ON)
endif ()

set_project_warnings(${PROJECT_NAME_LOWER}-app)

# ---------------------------------------------------------------------------------------
# Windows Multi-Threaded Library.
# ---------------------------------------------------------------------------------------
# For Windows, it is necessary to link with the MultiThreaded library.
# Depending on how the rest of the project's dependencies are linked, it might be necessary
# to change the line to statically link with the library.
#
# This is done as follows:
#
# set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
#
# On Linux and Mac this variable is ignored. If any issues rise from it, try commenting it out
# and letting CMake decide how to link with it.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# ---------------------------------------------------------------------------------------
# Unit Testing, E2E Testing, and Code Coverage.
# ---------------------------------------------------------------------------------------

if (${PROJECT_NAME_UPPER}_ENABLE_TESTING)
    enable_testing()

    # Catch2 CMake options.
    set(CATCH_CONFIG_COLOUR_WIN32 ON)
    set(CATCH_CONFIG_NO_COLOUR_WIN32 OFF)
    set(CATCH_CONFIG_CONSOLE_WIDTH 120)
    set(CATCH_CONFIG_FAST_COMPILE ON)
    set(CATCH_CONFIG_NO_FAST_COMPILE OFF)

    # Set the sources & linking libraries.
    add_executable(${PROJECT_NAME_LOWER}-test "")
    target_sources(${PROJECT_NAME_LOWER}-test
        PRIVATE
        ${TESTING_SOURCES}
    )
    target_include_directories(${PROJECT_NAME_LOWER}-test
        PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/test
    )
    target_link_libraries(${PROJECT_NAME_LOWER}-test
        PRIVATE
        Catch2::Catch2
    )
    if (UNIX AND NOT APPLE)
        target_link_libraries(${PROJECT_NAME_LOWER}-test
            PRIVATE
            pthread
        )
    endif ()

    # Set the building options.
    if (MSVC)
        if (MSVC_VERSION GREATER_EQUAL 1914)
            target_compile_options(${PROJECT_NAME_LOWER}-test PRIVATE "/Zc:__cplusplus" "/Zc:nrvo" "/FS")
        endif ()
        set_target_properties(${PROJECT_NAME_LOWER}-test PROPERTIES WIN32_EXECUTABLE ON)
    elseif (UNIX)
        if (${PROJECT_NAME}_ENABLE_CODE_COVERAGE)
            target_compile_options(${PROJECT_NAME_LOWER}-test PRIVATE "--coverage")
            target_link_options(${PROJECT_NAME_LOWER}-test PRIVATE "--coverage")
        endif ()
    endif ()

    set_project_warnings(${PROJECT_NAME_LOWER}-test)

    add_custom_target(run-${PROJECT_NAME_LOWER}-test
        COMMAND ${PROJECT_NAME_LOWER}-test
            --reporter console::out=-::colour-mode=ansi
            --reporter JSON::out=test_results.json
            # --reporter XML::out=test_results.xml
            # --reporter JUnit::out=test_results.xml
        WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
        COMMENT "Running ${PROJECT_NAME_LOWER}-test with custom options ..."
    )

    include(Catch)
    catch_discover_tests(${PROJECT_NAME_LOWER}-test)
endif ()

# ---------------------------------------------------------------------------------------
# Print the final status.
# ---------------------------------------------------------------------------------------

message("\n")
message(STATUS "--------------------")
message(STATUS "Configure Result:   ")
message(STATUS "--------------------")
message(STATUS "Project Name: ${PROJECT_NAME_UPPER}")
message(STATUS "Project Version: ${PROJECT_VERSION}")
message(STATUS "System Name: ${CMAKE_SYSTEM_NAME}")
message(STATUS "System Version: ${CMAKE_SYSTEM_VERSION}")
message(STATUS "System Processor: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C Version: ${CMAKE_C_STANDARD}")
message(STATUS "C++ Version: ${CMAKE_CXX_STANDARD}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C Flags: ${CMAKE_C_FLAGS}")
message(STATUS "C Debug Flags: ${CMAKE_C_FLAGS_DEBUG}")
message(STATUS "C Release Flags: ${CMAKE_C_FLAGS_RELEASE}")
message(STATUS "C++ Flags: ${CMAKE_CXX_FLAGS}")
message(STATUS "C++ Debug Flags: ${CMAKE_CXX_FLAGS_DEBUG}")
message(STATUS "C++ Release Flags: ${CMAKE_CXX_FLAGS_RELEASE}")
message(STATUS "Linker Flags: ${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "Onvif Client Version: ${ONVIF_CLIENT_VERSION}")
message(STATUS "Onvif Server Version: ${ONVIF_SERVER_VERSION}")
message(STATUS "Media Pusher Version: ${MEDIA_PUSHER_VERSION}")
message(STATUS "Media Server Version: ${MEDIA_SERVER_VERSION}")
message(STATUS "Stream2file Version: ${STREAM2FILE_VERSION}")
message(STATUS "--------------------")
message(STATUS "Treat Warnings As Errors: ${${PROJECT_NAME_UPPER}_WARNINGS_AS_ERRORS}")
message(STATUS "Export Compile Commands: ${${PROJECT_NAME_UPPER}_EXPORT_COMPILE_COMMANDS}")
message(STATUS "Enable Conan: ${${PROJECT_NAME_UPPER}_ENABLE_CONAN}")
message(STATUS "Enable VCPKG: ${${PROJECT_NAME_UPPER}_ENABLE_VCPKG}")
message(STATUS "Enable Clang-Format: ${${PROJECT_NAME_UPPER}_ENABLE_CLANG_FORMAT}")
message(STATUS "Enable Clang-Tidy: ${${PROJECT_NAME_UPPER}_ENABLE_CLANG_TIDY}")
message(STATUS "Enable Clang-Tidy When Building: ${${PROJECT_NAME_UPPER}_ENABLE_CLANG_TIDY_WHEN_BUILD}")
message(STATUS "Enable CppCheck: ${${PROJECT_NAME_UPPER}_ENABLE_CPPCHECK}")
message(STATUS "Enable CppCheck When Building: ${${PROJECT_NAME_UPPER}_ENABLE_CPPCHECK_WHEN_BUILD}")
message(STATUS "Enable CCache: ${${PROJECT_NAME_UPPER}_ENABLE_CCACHE}")
message(STATUS "Enable LTO: ${${PROJECT_NAME_UPPER}_ENABLE_LTO}")
message(STATUS "Enable Testing: ${${PROJECT_NAME_UPPER}_ENABLE_TESTING}")
message(STATUS "Enable Code Coverage: ${${PROJECT_NAME_UPPER}_ENABLE_CODE_COVERAGE}")
message(STATUS "Enable Address Sanitizer: ${${PROJECT_NAME_UPPER}_ENABLE_ASAN}")
message(STATUS "Enable Leak Sanitizer: ${${PROJECT_NAME_UPPER}_ENABLE_LSAN}")
message(STATUS "Enable Thread Sanitizer: ${${PROJECT_NAME_UPPER}_ENABLE_TSAN}")
message(STATUS "Enable Undefined Behavior Sanitizer: ${${PROJECT_NAME_UPPER}_ENABLE_USAN}")
message(STATUS "Enable Memory Sanitizer: ${${PROJECT_NAME_UPPER}_ENABLE_MSAN}")
message("\n")
