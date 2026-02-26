##################################################
###       libzip                               ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_LIBZIP )
OPENMS_LOGHEADER_LIBRARY("libzip")
#extract: (takes very long.. so skip if possible)
if(MSVC)
  set(ZIP_ARGS x -y -osrc)
else()
  set(ZIP_ARGS xzf)
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_LIBZIP "LIBZIP" "CMakeLists.txt")

# Common CMake options for libzip (all platforms)
set(_LIBZIP_COMMON_ARGS
    "-DENABLE_COMMONCRYPTO=OFF"
    "-DENABLE_GNUTLS=OFF"
    "-DENABLE_MBEDTLS=OFF"
    "-DENABLE_OPENSSL=OFF"
    "-DENABLE_WINDOWS_CRYPTO=OFF"
    "-DENABLE_BZIP2=ON"
    "-DENABLE_LZMA=OFF"
    "-DENABLE_ZSTD=OFF"
    "-DBUILD_TOOLS=OFF"
    "-DBUILD_REGRESS=OFF"
    "-DBUILD_OSSFUZZ=OFF"
    "-DBUILD_EXAMPLES=OFF"
    "-DBUILD_DOC=OFF"
    "-DCMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}"
    "-DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}"
)

## build the obj/lib
if (MSVC)
  message(STATUS "Generating libzip build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_LIBZIP_COMMON_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          ${ARCHITECTURE_OPTION_CMAKE}
                          .
                  WORKING_DIRECTORY ${LIBZIP_DIR}
                  OUTPUT_VARIABLE LIBZIP_CMAKE_OUT
                  ERROR_VARIABLE LIBZIP_CMAKE_ERR
                  RESULT_VARIABLE LIBZIP_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${LIBZIP_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${LIBZIP_CMAKE_ERR})

  if(NOT LIBZIP_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "Generating libzip build system .. failed")
    message(STATUS "Output: ${LIBZIP_CMAKE_OUT}")
    message(FATAL_ERROR "Error: ${LIBZIP_CMAKE_ERR}")
  else()
    message(STATUS "Generating libzip build system .. done")
  endif()

  message(STATUS "Building libzip lib (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${LIBZIP_DIR} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${LIBZIP_DIR}
                  OUTPUT_VARIABLE LIBZIP_BUILD_OUT
                  ERROR_VARIABLE LIBZIP_BUILD_ERR
                  RESULT_VARIABLE LIBZIP_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_ERR})

  if(NOT LIBZIP_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building libzip lib (Debug) .. failed")
    message(STATUS "Output: ${LIBZIP_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${LIBZIP_BUILD_ERR}")
  else()
    message(STATUS "Building libzip lib (Debug) .. done")
  endif()

  # rebuild as release
  message(STATUS "Building libzip lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${LIBZIP_DIR} --target INSTALL --config Release
                  WORKING_DIRECTORY ${LIBZIP_DIR}
                  OUTPUT_VARIABLE LIBZIP_BUILD_OUT
                  ERROR_VARIABLE LIBZIP_BUILD_ERR
                  RESULT_VARIABLE LIBZIP_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_ERR})

  if(NOT LIBZIP_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building libzip lib (Release) .. failed")
    message(STATUS "Output: ${LIBZIP_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${LIBZIP_BUILD_ERR}")
  else()
    message(STATUS "Building libzip lib (Release) .. done")
  endif()

else() ## Linux/MacOS

  # Build list of platform-specific CMake args
  set(_LIBZIP_PLATFORM_ARGS)
  if(APPLE)
    list(APPEND _LIBZIP_PLATFORM_ARGS
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
        "-DCMAKE_MACOSX_RPATH=TRUE"
      )
  endif()

  # CFLAGS for libzip
  set(LIBZIP_CFLAGS "-Wall -O3 -fPIC")

  message(STATUS "Generating libzip build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_LIBZIP_PLATFORM_ARGS}
                          ${_LIBZIP_COMMON_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          "-DCMAKE_BUILD_TYPE=Release"
                          "-DCMAKE_C_FLAGS=${LIBZIP_CFLAGS}"
                          .
                  WORKING_DIRECTORY ${LIBZIP_DIR}
                  OUTPUT_VARIABLE LIBZIP_CMAKE_OUT
                  ERROR_VARIABLE LIBZIP_CMAKE_ERR
                  RESULT_VARIABLE LIBZIP_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${LIBZIP_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${LIBZIP_CMAKE_ERR})

  if(NOT LIBZIP_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "Generating libzip build system .. failed")
    message(STATUS "Output: ${LIBZIP_CMAKE_OUT}")
    message(STATUS "Error: ${LIBZIP_CMAKE_ERR}")
    message(FATAL_ERROR "libzip configuration failed. Check the log file for details: ${LOGFILE}")
  else()
    message(STATUS "Generating libzip build system .. done")
  endif()

  message(STATUS "Building libzip lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                  --build ${LIBZIP_DIR}
                  --target install
                  WORKING_DIRECTORY ${LIBZIP_DIR}
                  OUTPUT_VARIABLE LIBZIP_BUILD_OUT
                  ERROR_VARIABLE LIBZIP_BUILD_ERR
                  RESULT_VARIABLE LIBZIP_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${LIBZIP_BUILD_ERR})

  if(NOT LIBZIP_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Output: ${LIBZIP_BUILD_OUT}")
    message(STATUS "Error: ${LIBZIP_BUILD_ERR}")
    message(FATAL_ERROR "Building libzip lib (Release) .. failed")
  else()
    message(STATUS "Building libzip lib (Release) .. done")
  endif()

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_LIBZIP )
