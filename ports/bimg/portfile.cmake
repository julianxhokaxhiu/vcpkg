# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT_DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#
include(vcpkg_common_functions)

# Download source packages
# (bimg requires bx source for building)

vcpkg_from_github(OUT_SOURCE_PATH BX_SOURCE_DIR
    REPO "bkaradzic/bx"
    HEAD_REF master
    REF 8d96af9873a0a0c5ce76614f92be90d9fd9da34c
    SHA512 11491e9b298d10755f7eea72b6d76e494337c26ed86ed4f840d740a8af4b5c08e7e328897531a4b5dacf50e35c4b0e1e3e20db9f943e36308bd5e085cffa2b3e
)

vcpkg_from_github(OUT_SOURCE_PATH SOURCE_DIR
    REPO "bkaradzic/bimg"
    HEAD_REF master
    REF bfe3c683f9c628fb3fd5d71b1a80d8fbdb6044a4
    SHA512 d9fcad6af16f050923454871ade16576f18b766ee13d4f704898cfde300af8b40e1af22ec0c9f7b3d3e99887552238809bcb8dd3bfc4ca8d7c8cd807c9ca7ad3
)

# Copy bx source inside bimg source tree
file(GLOB BX_FILES LIST_DIRECTORIES true "${BX_SOURCE_DIR}/*")
file(COPY ${BX_FILES} DESTINATION "${SOURCE_DIR}/.bx")
set(BX_DIR ${SOURCE_DIR}/.bx)
set(ENV{BX_DIR} ${BX_DIR})

# Set up GENie (custom project generator)

if(VCPKG_CRT_LINKAGE STREQUAL dynamic)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --with-dynamic-runtime)
endif()
if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --with-shared-lib)
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --platform=x32)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --platform=x64)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL arm OR VCPKG_TARGET_ARCHITECTURE STREQUAL arm64)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --platform=ARM)
else()
    message(WARNING "Architecture may be not supported: ${VCPKG_TARGET_ARCHITECTURE}")
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --platform=${VCPKG_TARGET_ARCHITECTURE})
endif()

if(TARGET_TRIPLET MATCHES osx)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --os=macosx)
elseif(TARGET_TRIPLET MATCHES linux)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --os=linux)
elseif(TARGET_TRIPLET MATCHES windows)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --os=windows)
elseif(TARGET_TRIPLET MATCHES uwp)
    set(GENIE_OPTIONS ${GENIE_OPTIONS} --vs=winstore100)
endif()

# GENie does not allow cmake+msvc, so we use msbuild in windows
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if(VCPKG_PLATFORM_TOOLSET STREQUAL "v140")
        set(GENIE_ACTION vs2015)
    elseif(VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
        set(GENIE_ACTION vs2017)
    elseif(VCPKG_PLATFORM_TOOLSET STREQUAL "v142")
        set(GENIE_ACTION vs2019)
    else()
        message(FATAL_ERROR "Unsupported Visual Studio toolset: ${VCPKG_PLATFORM_TOOLSET}")
    endif()
    set(PROJ_FOLDER ${GENIE_ACTION})
    if(TARGET_TRIPLET MATCHES uwp)
        set(PROJ_FOLDER ${PROJ_FOLDER}-winstore100)
    endif()
else()
    set(GENIE_ACTION cmake)
    set(PROJ_FOLDER ${GENIE_ACTION})
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(GENIE "${BX_DIR}/tools/bin/windows/genie.exe")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    set(GENIE "${BX_DIR}/tools/bin/darwin/genie")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(GENIE "${BX_DIR}/tools/bin/linux/genie")
else()
    message(FATAL_ERROR "Unsupported host platform: ${CMAKE_HOST_SYSTEM_NAME}")
endif()

# Run GENie

vcpkg_execute_required_process(
    COMMAND ${GENIE} ${GENIE_OPTIONS} ${GENIE_ACTION}
    WORKING_DIRECTORY "${SOURCE_DIR}"
    LOGNAME "genie-${TARGET_TRIPLET}"
)

if(GENIE_ACTION STREQUAL cmake)
    # Run CMake
    vcpkg_configure_cmake(
        SOURCE_PATH "${SOURCE_DIR}/.build/projects/${PROJ_FOLDER}"
        PREFER_NINJA
        OPTIONS_RELEASE -DCMAKE_BUILD_TYPE=Release
        OPTIONS_DEBUG -DCMAKE_BUILD_TYPE=Debug
    )
    vcpkg_install_cmake(TARGET bimg/all)
    vcpkg_install_cmake(TARGET bimg_encode/all)
    vcpkg_install_cmake(TARGET bimg_decode/all)
    # GENie does not generate an install target, so we install explicitly
    file(INSTALL "${SOURCE_DIR}/include/bimg" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
    file(GLOB instfiles
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg/*.so"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg_encode/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg_encode/*.so"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg_decode/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bimg_decode/*.so"
    )
    file(INSTALL ${instfiles} DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
    file(GLOB instfiles
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg/*.so"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg_encode/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg_encode/*.so"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg_decode/*.a"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bimg_decode/*.so"
    )
    file(INSTALL ${instfiles} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
    file(INSTALL "${SOURCE_DIR}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
else()
    # Run MSBuild for all 3 targets
    foreach(PROJ bimg bimg_decode bimg_encode)
        vcpkg_install_msbuild(
            SOURCE_PATH "${SOURCE_DIR}"
            PROJECT_SUBPATH ".build/projects/${PROJ_FOLDER}/${PROJ}.vcxproj"
            LICENSE_SUBPATH "LICENSE"
            INCLUDES_SUBPATH "include"
        )
    endforeach()
endif()

# Post-build test for cmake libraries
vcpkg_test_cmake(PACKAGE_NAME ${PORT})
