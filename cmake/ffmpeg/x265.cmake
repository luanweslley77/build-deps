# x265.pc will not be installed if their cmake cannot detect the latest tag
GIT_FETCH_TAGS("third-party/FFmpeg/x265_git")

set(X265_GENERATED_SRC_PATH ${CMAKE_CURRENT_BINARY_DIR}/FFmpeg/x265_git)

file(GLOB X265_GIT_FILES ${CMAKE_CURRENT_SOURCE_DIR}/patches/FFmpeg/x265_git/*.patch)
foreach(patch_file ${X265_GIT_FILES})
    APPLY_GIT_PATCH(${X265_GENERATED_SRC_PATH} ${patch_file})
endforeach()

if(BUILD_FFMPEG_ALL_PATCHES OR BUILD_FFMPEG_X265_PATCHES)
    file(GLOB FFMPEG_X265_FILES ${CMAKE_CURRENT_SOURCE_DIR}/patches/FFmpeg/FFmpeg/x265/*.patch)

    foreach(patch_file ${FFMPEG_X265_FILES})
        APPLY_GIT_PATCH(${FFMPEG_GENERATED_SRC_PATH} ${patch_file})
    endforeach()
endif()

# ensure x265 installs into the ffmpeg prefix
set(_original_cmake_install_prefix ${CMAKE_INSTALL_PREFIX})
set(CMAKE_INSTALL_PREFIX ${FFMPEG_INSTALL_PREFIX})

# --- Multilib 8/10/12-bit x265 for HDR (Main10) ---
# Use the upstream multilib.sh concept but via CMake ExternalProject for reproducibility
include(ExternalProject)

set(X265_MULTILIB_DIR ${CMAKE_CURRENT_BINARY_DIR}/x265-multilib)
set(X265_8BIT_DIR ${X265_MULTILIB_DIR}/8bit)
set(X265_10BIT_DIR ${X265_MULTILIB_DIR}/10bit)
set(X265_12BIT_DIR ${X265_MULTILIB_DIR}/12bit)

# Create combined header that enables multilib API
# x265 multilib API requires linking all three libs together

ExternalProject_Add(x265-12bit
  SOURCE_DIR ${X265_GENERATED_SRC_PATH}/source
  BINARY_DIR ${X265_12BIT_DIR}
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${FFMPEG_INSTALL_PREFIX}
             -DCMAKE_BUILD_TYPE=Release
             -DENABLE_CLI=OFF
             -DENABLE_SHARED=OFF
             -DSTATIC_LINK_CRT=ON
             -DHIGH_BIT_DEPTH=ON
             -DMAIN12=ON
             -DEXPORT_C_API=OFF
             -DENABLE_HDR10_PLUS=OFF
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel 4
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS <BINARY_DIR>/libx265.a
)

ExternalProject_Add(x265-10bit
  SOURCE_DIR ${X265_GENERATED_SRC_PATH}/source
  BINARY_DIR ${X265_10BIT_DIR}
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${FFMPEG_INSTALL_PREFIX}
             -DCMAKE_BUILD_TYPE=Release
             -DENABLE_CLI=OFF
             -DENABLE_SHARED=OFF
             -DSTATIC_LINK_CRT=ON
             -DHIGH_BIT_DEPTH=ON
             -DEXPORT_C_API=OFF
             -DENABLE_HDR10_PLUS=OFF
  DEPENDS x265-12bit
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel 4
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS <BINARY_DIR>/libx265.a
)

ExternalProject_Add(x265-8bit
  SOURCE_DIR ${X265_GENERATED_SRC_PATH}/source
  BINARY_DIR ${X265_8BIT_DIR}
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${FFMPEG_INSTALL_PREFIX}
             -DCMAKE_BUILD_TYPE=Release
             -DENABLE_CLI=OFF
             -DENABLE_SHARED=OFF
             -DSTATIC_LINK_CRT=ON
             -DENABLE_HDR10_PLUS=ON
             -DEXTRA_LIB=x265_main10.a\\;x265_main12.a
             -DEXTRA_LINK_FLAGS=-L.
             -DLINKED_10BIT=ON
             -DLINKED_12BIT=ON
  DEPENDS x265-10bit x265-12bit
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel 4
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS <BINARY_DIR>/libx265.a
  # Need to symlink the 10/12-bit libs into 8bit build dir before configuring 8bit
  PATCH_COMMAND ${CMAKE_COMMAND} -E create_symlink ${X265_10BIT_DIR}/libx265.a ${X265_8BIT_DIR}/libx265_main10.a
            COMMAND ${CMAKE_COMMAND} -E create_symlink ${X265_12BIT_DIR}/libx265.a ${X265_8BIT_DIR}/libx265_main12.a
)

# Combine step: after 8bit builds, combine into final libx265.a that supports all bit depths
add_custom_target(x265-multilib-combine ALL
  DEPENDS x265-8bit
  COMMAND ${CMAKE_COMMAND} -E copy ${X265_8BIT_DIR}/libx265.a ${X265_8BIT_DIR}/libx265_main.a
  COMMAND ar -M < ${CMAKE_CURRENT_SOURCE_DIR}/cmake/ffmpeg/x265-multilib.ar
  COMMAND ${CMAKE_COMMAND} -E copy ${X265_8BIT_DIR}/libx265.a ${FFMPEG_INSTALL_PREFIX}/lib/libx265.a
  COMMAND ${CMAKE_COMMAND} -E copy ${X265_GENERATED_SRC_PATH}/source/x265.h ${FFMPEG_INSTALL_PREFIX}/include/x265.h
  COMMAND ${CMAKE_COMMAND} -E copy ${X265_GENERATED_SRC_PATH}/source/x265_config.h ${FFMPEG_INSTALL_PREFIX}/include/x265_config.h
  COMMENT "Combining x265 8/10/12-bit into multilib libx265.a"
  VERBATIM
)

# Provide x265.pc
add_custom_target(x265
  COMMAND ${CMAKE_COMMAND} -E copy ${X265_8BIT_DIR}/x265.pc ${FFMPEG_INSTALL_PREFIX}/lib/pkgconfig/x265.pc
  DEPENDS x265-multilib-combine
  COMMENT "Installing x265 pkgconfig"
)
add_dependencies(${CMAKE_PROJECT_NAME} x265)

set(CMAKE_INSTALL_PREFIX ${_original_cmake_install_prefix})
