# Verifies that a nested x265 build produced the expected static library and
# refreshes its timestamp, so the custom command that declares the library as
# its OUTPUT stays up to date.
#
# Required variables:
#   X265_LIBRARY - path of the library the nested build must have produced

if(NOT DEFINED X265_LIBRARY OR NOT EXISTS "${X265_LIBRARY}")
    message(FATAL_ERROR "x265 did not produce the expected library: ${X265_LIBRARY}")
endif()

file(TOUCH_NOCREATE "${X265_LIBRARY}")
