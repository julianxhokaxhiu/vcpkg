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
# (bgfx requires bx and bimg source for building)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO "losnoco/vgmstream"
    HEAD_REF master
    REF 39f38e0ac8863d2b7a40c54c43a5ba92593b4646
    SHA512 5da030c313f8184bc8a13eb6e80cfe2af78902f79cf02b867debfe9774d5795f7aca7a8852c90ea5e82e8a52147bdfc15ad0138ed4f45cc9479288d39094791c
    PATCHES
        cmake.patch
        cmake2.patch
)

SET(USE_FFMPEG OFF)
SET(USE_MPEG OFF)
SET(USE_VORBIS OFF)

if("ffmpeg" IN_LIST FEATURES)
    SET(USE_FFMPEG ON)
endif()

if("mpg123" IN_LIST FEATURES)
    SET(USE_MPEG ON)
endif()

if("vorbis" IN_LIST FEATURES)
    SET(USE_VORBIS ON)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DUSE_ATRAC9=OFF
        -DUSE_CELT=OFF
        -DUSE_FFMPEG=${USE_FFMPEG}
        -DUSE_FDKAAC=OFF
        -DUSE_G719=OFF
        -DUSE_G7221=ON
        -DUSE_MAIATRAC3PLUS=OFF
        -DUSE_MPEG=${USE_MPEG}
        -DUSE_VORBIS=${USE_VORBIS}
        -DBUILD_AUDACIOUS=OFF
        -DBUILD_CLI=OFF
        -DBUILD_FB2K=OFF
        -DBUILD_XMPLAY=OFF
        -DBUILD_WINAMP=OFF
    OPTIONS_DEBUG
        -DSKIP_INSTALL_HEADERS=ON
)

vcpkg_install_cmake()

vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

# Post-build test for cmake libraries
vcpkg_test_cmake(PACKAGE_NAME ${PORT})
