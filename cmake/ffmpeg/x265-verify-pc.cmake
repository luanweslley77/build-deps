# Verifies that x265's install step produced the pkg-config file consumed by
# FFmpeg, and that the version in it matches the tag the source tree was built
# from. A missing file or an unusable version means x265 could not determine its
# version; a mismatching version means the version that reached the build is not
# the one the sources came from.
#
# Required variables:
#   X265_PC_FILE          - pkg-config file the install step must have written
#   X265_EXPECTED_VERSION - version tag the file must report

foreach(x265_required_var X265_PC_FILE X265_EXPECTED_VERSION)
    if(NOT DEFINED ${x265_required_var} OR "${${x265_required_var}}" STREQUAL "")
        message(FATAL_ERROR "${x265_required_var} must be set")
    endif()
endforeach()

if(NOT EXISTS "${X265_PC_FILE}")
    message(FATAL_ERROR
            "x265.pc was not installed at ${X265_PC_FILE}. x265 only installs it "
            "when it can determine its version; check the version handling in "
            "cmake/ffmpeg/x265.cmake.")
endif()

file(READ "${X265_PC_FILE}" x265_pc_content)
if(NOT x265_pc_content MATCHES "Version:[ \t]*([^\n\r]*)")
    message(FATAL_ERROR "the installed x265.pc has no version field: ${X265_PC_FILE}")
endif()
string(STRIP "${CMAKE_MATCH_1}" x265_pc_version)
if(x265_pc_version STREQUAL "")
    message(FATAL_ERROR "the installed x265.pc has an empty version: ${X265_PC_FILE}")
endif()
if(NOT "${x265_pc_version}" STREQUAL "${X265_EXPECTED_VERSION}")
    message(FATAL_ERROR
            "the installed x265.pc reports version '${x265_pc_version}', but the "
            "source tree was built from tag '${X265_EXPECTED_VERSION}'.")
endif()
