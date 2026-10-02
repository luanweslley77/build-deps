# Verifies that x265's install step produced the pkg-config file consumed by
# FFmpeg, and that the version in it matches the tag the source tree was built
# from. A missing file (or one without a usable version) means the version file
# was not materialized correctly; a mismatching version means x265 picked up a
# stale x265Version.txt instead of the generated one.
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
            "when it can detect its version, so make sure the generated "
            "x265Version.txt reached the copied source tree (see x265.cmake).")
endif()

file(READ "${X265_PC_FILE}" x265_pc_content)
if(NOT x265_pc_content MATCHES "Version:[ \t]*([^\n\r]*)")
    message(FATAL_ERROR "the installed x265.pc has no usable version: ${X265_PC_FILE}")
endif()
string(STRIP "${CMAKE_MATCH_1}" x265_pc_version)
if(NOT x265_pc_version STREQUAL X265_EXPECTED_VERSION)
    message(FATAL_ERROR
            "the installed x265.pc reports version '${x265_pc_version}', but the "
            "source tree was built from tag '${X265_EXPECTED_VERSION}'. The copied "
            "tree probably still carries a stale x265Version.txt.")
endif()
