# ----- Compiler options ----- #

# XXX: Because it is too strict, currently closed.
option(${PROJECT_NAME_UPPER}_WARNINGS_AS_ERRORS
    "Treat compiler warnings as errors." OFF
)
# Generate compile_commands.json for clang based tools.
option(${PROJECT_NAME_UPPER}_EXPORT_COMPILE_COMMANDS
    "Enable the CMake to export compile_commands.json." ON
)

# ----- Package managers ----- #

option(${PROJECT_NAME_UPPER}_ENABLE_CONAN
    "Enable the Conan package manager for this project." OFF
)
option(${PROJECT_NAME_UPPER}_ENABLE_VCPKG
    "Enable the Vcpkg package manager for this project." OFF
)

# ----- Static analyzers ----- #

option(${PROJECT_NAME_UPPER}_ENABLE_CLANG_TIDY
    "Enable static analysis with Clang-Tidy." OFF
)
option(${PROJECT_NAME_UPPER}_ENABLE_CLANG_TIDY_WHEN_BUILD
    "Enable static analysis with Clang-Tidy when building." OFF
)
option(${PROJECT_NAME_UPPER}_ENABLE_CPPCHECK
    "Enable static analysis with Cppcheck." OFF
)
option(${PROJECT_NAME_UPPER}_ENABLE_CPPCHECK_WHEN_BUILD
    "Enable static analysis with Cppcheck when building." OFF
)

# ----- Formatter ----- #

option(${PROJECT_NAME_UPPER}_ENABLE_CLANG_FORMAT
    "Enable code formatting with Clang-Format." OFF
)

# ----- Testing ----- #

option(${PROJECT_NAME_UPPER}_ENABLE_TESTING
    "Enable tests for the projects (from the `test` subfolder)." OFF
)

# ----- Code coverage ----- #

option(${PROJECT_NAME_UPPER}_ENABLE_CODE_COVERAGE
    "Enable code coverage." OFF
)

# In Debug mode, the "Code Coverage" option is enabled by default.
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(${PROJECT_NAME_UPPER}_ENABLE_CODE_COVERAGE ON)
endif ()

# ----- Miscellaneous options ----- #

# Configure symbol visibility for shared libraries.
if (BUILD_SHARED_LIBS)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF)
    set(CMAKE_C_VISIBILITY_PRESET hidden)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden)
    set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
endif ()

# Enable Inter-procedural optimization or not.
option(${PROJECT_NAME_UPPER}_ENABLE_LTO
    "Enable Inter-procedural Optimization, aka Link Time Optimization (LTO)." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    if (result)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else ()
        message(SEND_ERROR "IPO is not supported: ${output}.")
    endif ()
endif ()

# Enable Ccache or not.
option(${PROJECT_NAME_UPPER}_ENABLE_CCACHE
    "Enable the usage of Ccache, in order to speed up rebuild times." ON
)
find_program(CCACHE_FOUND ccache)
if (${PROJECT_NAME_UPPER}_ENABLE_CCACHE AND CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
    message(STATUS "Ccache enabled.")
endif ()

# ----- Sanitizer options ----- #

# Enable Address Sanitizer or not.
option(${PROJECT_NAME_UPPER}_ENABLE_ASAN
    "Enable Address Sanitizer to detect memory error." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_ASAN)
    if (MSVC)
        # Because Qt happens to load before ASan and load C/C++ runtime
        # before ASan DLLs loaded. Qt performs some initialization.
        # So the memory is malloced without ASan knowledge,
        # and later ASan sees reallocate without prior malloc, which it reports.
        # Ref: https://stackoverflow.com/questions/69678689/address-sanitizer-in-msvc-why-does-it-report-an-error-on-startup
        # Currently, stop using Address Sanitizer with MSVC temporarily.
        # FIXME: Rebuild Qt source code by enable Address Sanitizer with MSVC
        #        in correct load order.
        #        (i.e. /d:clang_rt.asan_dbg_dynamic-x86_64.dll Qt6Cored.dll ...)
        # add_compile_options(-fsanitize=address)
    else ()
        # FIXME: Because some global variables in Happytime's source code are have the same name,
        #        this will cause ASan to prompt an error when the program starts,
        #        so temporarily disable ASan.
        add_compile_options(-fsanitize=address)
        # The linker of MSVC will unrecognized and ignore this options.
        add_link_options(-fsanitize=address)
    endif ()
endif ()

# Enable Leak Sanitizer or not.
option(${PROJECT_NAME_UPPER}_ENABLE_LSAN
    "Enable Leak Sanitizer to detect memory error." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_LSAN)
    if (UNIX)
        add_compile_options(-fsanitize=leak)
        add_link_options(-fsanitize=leak)
    endif ()
endif ()

# Enable Thread Sanitizer or not.
# Cannot be used with Address Sanitizer at the same time!
option(${PROJECT_NAME_UPPER}_ENABLE_TSAN
    "Enable Thread Sanitizer to detect memory error." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_TSAN)
    if (UNIX)
        # MSVC's Clang doesn't have TSAN.
        add_compile_options(-fsanitize=thread)
        add_link_options(-fsanitize=thread)
    endif ()
endif ()

# Enable Undefined Behavior Sanitizer or not.
option(${PROJECT_NAME_UPPER}_ENABLE_USAN
    "Enable Undefined Behavior Sanitizer to detect memory error." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_USAN)
    if (UNIX)
        add_compile_options(-fsanitize=undefined)
        add_link_options(-fsanitize=undefined)
    endif ()
endif ()

# Enable Memory Sanitizer or not.
# Cannot be used with Address Sanitizer at the same time!
option(${PROJECT_NAME_UPPER}_ENABLE_MSAN
    "Enable Memory Sanitizer to detect memory error." OFF
)
if (${PROJECT_NAME_UPPER}_ENABLE_MSAN)
    if (UNIX)
        add_compile_options(-fsanitize=memory)
        add_link_options(-fsanitize=memory)
    endif ()
endif ()
