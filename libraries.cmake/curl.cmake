##################################################
###       libcurl                              ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_CURL )
OPENMS_LOGHEADER_LIBRARY("curl")

if(MSVC)
  set(ZIP_ARGS x -y -osrc)
else()
  set(ZIP_ARGS xzf)
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_CURL "CURL" "CMakeLists.txt")

# curl doesn't allow insource builds
set(_CURL_BUILD_DIR "${CURL_DIR}/build")
file(TO_NATIVE_PATH "${_CURL_BUILD_DIR}" _CURL_NATIVE_BUILD_DIR)
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${_CURL_NATIVE_BUILD_DIR})

# Platform-specific TLS backend
if(MSVC)
  set(_CURL_TLS_OPTION "-DCURL_USE_SCHANNEL=ON")
elseif(APPLE)
  set(_CURL_TLS_OPTION "-DCURL_USE_SECTRANSP=ON")
else()
  set(_CURL_TLS_OPTION "-DCURL_USE_OPENSSL=ON")
endif()

if(APPLE)
  set(_CURL_EXTRA_ARGS
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
      "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
      "-DCMAKE_MACOSX_RPATH=TRUE"
    )
else()
  set(_CURL_EXTRA_ARGS "")
endif()

message(STATUS "Generating curl build system .. ")
execute_process(COMMAND ${CMAKE_COMMAND}
                -G "${CMAKE_GENERATOR}"
                ${ARCHITECTURE_OPTION_CMAKE}
                -D CMAKE_BUILD_TYPE=Release
                -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                -D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
                -D CMAKE_POSITION_INDEPENDENT_CODE=ON
                -D BUILD_CURL_EXE=OFF
                -D BUILD_TESTING=OFF
                -D CURL_DISABLE_LDAP=ON
                -D CURL_USE_LIBPSL=OFF
                ${_CURL_TLS_OPTION}
                ${_CURL_EXTRA_ARGS}
                ${CURL_DIR}
                WORKING_DIRECTORY ${_CURL_NATIVE_BUILD_DIR}
                OUTPUT_VARIABLE _CURL_CMAKE_OUT
                ERROR_VARIABLE _CURL_CMAKE_ERR
                RESULT_VARIABLE _CURL_CMAKE_SUCCESS)

# output to logfile
file(APPEND ${LOGFILE} ${_CURL_CMAKE_OUT})
file(APPEND ${LOGFILE} ${_CURL_CMAKE_ERR})

if (NOT _CURL_CMAKE_SUCCESS EQUAL 0)
  message(STATUS "Generating curl build system .. failed")
  message(STATUS "Output: ${_CURL_CMAKE_OUT}")
  message(STATUS "Error: ${_CURL_CMAKE_ERR}")
  message(FATAL_ERROR "curl configuration failed. Check the log file for details: ${LOGFILE}")
else()
  message(STATUS "Generating curl build system .. done")
endif()

# the install target on windows has a different name than on mac/lnx
if(MSVC)
    set(_CURL_INSTALL_TARGET "INSTALL")
else()
    set(_CURL_INSTALL_TARGET "install")
endif()

message(STATUS "Building curl (Release) .. ")
execute_process(COMMAND ${CMAKE_COMMAND} --build ${_CURL_NATIVE_BUILD_DIR} --target ${_CURL_INSTALL_TARGET} --config Release
                WORKING_DIRECTORY ${_CURL_NATIVE_BUILD_DIR}
                OUTPUT_VARIABLE _CURL_BUILD_OUT
                ERROR_VARIABLE _CURL_BUILD_ERR
                RESULT_VARIABLE _CURL_BUILD_SUCCESS)

# output to logfile
file(APPEND ${LOGFILE} ${_CURL_BUILD_OUT})
file(APPEND ${LOGFILE} ${_CURL_BUILD_ERR})

if (NOT _CURL_BUILD_SUCCESS EQUAL 0)
  message(STATUS "Building curl (Release) .. failed")
  message(STATUS "Output: ${_CURL_BUILD_OUT}")
  message(STATUS "Error: ${_CURL_BUILD_ERR}")
  message(FATAL_ERROR "curl build failed. Check the log file for details: ${LOGFILE}")
else()
  message(STATUS "Building curl (Release) .. done")
endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_CURL )
