vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO cocos2d/cocos2d-x
    REF cocos2d-x-3.14.1
    SHA512 48d12a48b5c880aa1cccafa64353f025b32235be5d15d73861f6e825a5305946e039a1585883f7ca5336a59c966cb8daf61012ed0c99810a5fe3ae8aa98f80a3
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
      -DUSE_PREBUILT_LIBS=OFF
)
vcpkg_cmake_install()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
