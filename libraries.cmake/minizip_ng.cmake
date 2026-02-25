##################################################
###       minizip-ng                           ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_MINIZIP_NG )
OPENMS_LOGHEADER_LIBRARY("minizip-ng")
#extract: (takes very long.. so skip if possible)
if(MSVC)
  set(ZIP_ARGS x -y -osrc)
else()
  set(ZIP_ARGS xzf)
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_MINIZIP_NG "MINIZIP_NG" "CMakeLists.txt")

# Common CMake options for minizip-ng (all platforms)
set(_MZ_COMMON_ARGS
    "-DMZ_FETCH_LIBS=OFF"
    "-DMZ_LIB_SUFFIX=-ng"
    "-DMZ_COMPAT=OFF"
    "-DMZ_ZLIB=ON"
    "-DMZ_BZIP2=ON"
    "-DMZ_LZMA=OFF"
    "-DMZ_ZSTD=OFF"
    "-DMZ_OPENSSL=OFF"
    "-DMZ_ICONV=OFF"
    "-DMZ_PKCRYPT=ON"
    "-DMZ_WZAES=OFF"
    "-DCMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}"
    "-DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}"
)

## build the obj/lib
if (MSVC)
  message(STATUS "Generating minizip-ng build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_MZ_COMMON_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          ${ARCHITECTURE_OPTION_CMAKE}
                          .
                  WORKING_DIRECTORY ${MINIZIP_NG_DIR}
                  OUTPUT_VARIABLE MZ_CMAKE_OUT
                  ERROR_VARIABLE MZ_CMAKE_ERR
                  RESULT_VARIABLE MZ_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${MZ_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${MZ_CMAKE_ERR})

  if(NOT MZ_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "Generating minizip-ng build system .. failed")
    message(STATUS "Output: ${MZ_CMAKE_OUT}")
    message(FATAL_ERROR "Error: ${MZ_CMAKE_ERR}")
  else()
    message(STATUS "Generating minizip-ng build system .. done")
  endif()

  message(STATUS "Building minizip-ng lib (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${MINIZIP_NG_DIR} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${MINIZIP_NG_DIR}
                  OUTPUT_VARIABLE MZ_BUILD_OUT
                  ERROR_VARIABLE MZ_BUILD_ERR
                  RESULT_VARIABLE MZ_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${MZ_BUILD_OUT})
  file(APPEND ${LOGFILE} ${MZ_BUILD_ERR})

  if(NOT MZ_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building minizip-ng lib (Debug) .. failed")
    message(STATUS "Output: ${MZ_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${MZ_BUILD_ERR}")
  else()
    message(STATUS "Building minizip-ng lib (Debug) .. done")
  endif()

  # rebuild as release
  message(STATUS "Building minizip-ng lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${MINIZIP_NG_DIR} --target INSTALL --config Release
                  WORKING_DIRECTORY ${MINIZIP_NG_DIR}
                  OUTPUT_VARIABLE MZ_BUILD_OUT
                  ERROR_VARIABLE MZ_BUILD_ERR
                  RESULT_VARIABLE MZ_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${MZ_BUILD_OUT})
  file(APPEND ${LOGFILE} ${MZ_BUILD_ERR})

  if(NOT MZ_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building minizip-ng lib (Release) .. failed")
    message(STATUS "Output: ${MZ_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${MZ_BUILD_ERR}")
  else()
    message(STATUS "Building minizip-ng lib (Release) .. done")
  endif()

else() ## Linux/MacOS

  # Build list of platform-specific CMake args
  set(_MZ_PLATFORM_ARGS)
  if(APPLE)
    list(APPEND _MZ_PLATFORM_ARGS
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
        "-DCMAKE_MACOSX_RPATH=TRUE"
      )
  endif()

  # CFLAGS for minizip-ng
  set(MZ_CFLAGS "-Wall -O3 -fPIC")

  message(STATUS "Generating minizip-ng build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_MZ_PLATFORM_ARGS}
                          ${_MZ_COMMON_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          "-DCMAKE_BUILD_TYPE=Release"
                          "-DCMAKE_C_FLAGS=${MZ_CFLAGS}"
                          .
                  WORKING_DIRECTORY ${MINIZIP_NG_DIR}
                  OUTPUT_VARIABLE MZ_CMAKE_OUT
                  ERROR_VARIABLE MZ_CMAKE_ERR
                  RESULT_VARIABLE MZ_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${MZ_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${MZ_CMAKE_ERR})

  if(NOT MZ_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "Generating minizip-ng build system .. failed")
    message(STATUS "Output: ${MZ_CMAKE_OUT}")
    message(STATUS "Error: ${MZ_CMAKE_ERR}")
    message(FATAL_ERROR "minizip-ng configuration failed. Check the log file for details: ${LOGFILE}")
  else()
    message(STATUS "Generating minizip-ng build system .. done")
  endif()

  message(STATUS "Building minizip-ng lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                  --build ${MINIZIP_NG_DIR}
                  --target install
                  WORKING_DIRECTORY ${MINIZIP_NG_DIR}
                  OUTPUT_VARIABLE MZ_BUILD_OUT
                  ERROR_VARIABLE MZ_BUILD_ERR
                  RESULT_VARIABLE MZ_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${MZ_BUILD_OUT})
  file(APPEND ${LOGFILE} ${MZ_BUILD_ERR})

  if(NOT MZ_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Output: ${MZ_BUILD_OUT}")
    message(STATUS "Error: ${MZ_BUILD_ERR}")
    message(FATAL_ERROR "Building minizip-ng lib (Release) .. failed")
  else()
    message(STATUS "Building minizip-ng lib (Release) .. done")
  endif()

endif()

# Fix minizip-ng CMake config files to be relocatable
# minizip-ng uses raw path variables (${ZLIB_LIBRARIES}) in target_link_libraries(... PUBLIC ...)
# which embeds absolute paths in the exported targets file. This breaks when the
# contrib archive is extracted to a different location.
set(MZ_CMAKE_DIR "${PROJECT_BINARY_DIR}/lib/cmake/minizip-ng")

# Normalize path separators for replacement
file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}" PROJECT_BINARY_DIR_NORMALIZED)

set(MZ_RELOCATABLE_REPLACEMENT "get_filename_component(_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_DIR}/../../..\" ABSOLUTE)")
set(MZ_ORIGINAL_PATTERN "set(_IMPORT_PREFIX \"${PROJECT_BINARY_DIR_NORMALIZED}\")")

message(STATUS "minizip-ng relocatability fix:")
message(STATUS "  Build dir: ${PROJECT_BINARY_DIR_NORMALIZED}")

file(GLOB MZ_TARGET_FILES "${MZ_CMAKE_DIR}/minizip-ng*.cmake")
foreach(TARGET_FILE ${MZ_TARGET_FILES})
  file(READ "${TARGET_FILE}" TARGET_CONTENT)
  # Fix the _IMPORT_PREFIX definition
  string(REPLACE "${MZ_ORIGINAL_PATTERN}" "${MZ_RELOCATABLE_REPLACEMENT}" TARGET_CONTENT "${TARGET_CONTENT}")
  # Fix ALL hardcoded absolute paths (IMPORTED_LOCATION, INTERFACE_LINK_LIBRARIES, generator expressions)
  string(REPLACE "${PROJECT_BINARY_DIR_NORMALIZED}/" "\${_IMPORT_PREFIX}/" TARGET_CONTENT "${TARGET_CONTENT}")
  file(WRITE "${TARGET_FILE}" "${TARGET_CONTENT}")
  message(STATUS "  Fixed: ${TARGET_FILE}")
endforeach()

message(STATUS "Fixed minizip-ng CMake configs for relocatability")

ENDMACRO( OPENMS_CONTRIB_BUILD_MINIZIP_NG )
