##################################################
###       Arrow   							   ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_ARROW )
OPENMS_LOGHEADER_LIBRARY("arrow")
#extract: (takes very long.. so skip if possible)
if(MSVC)
  set(ZIP_ARGS "x -y -osrc")
else()
  set(ZIP_ARGS "xzf")
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_ARROW "ARROW" "README")

## build the obj/lib
if (MSVC)
  message(STATUS "Generating arrow build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          -D ARROW_BUILD_SHARED=${BUILD_SHARED_LIBRARIES}
                          -D CMAKE_INSTALL_BINDIR=${PROJECT_BINARY_DIR}/lib
                          -G "${CMAKE_GENERATOR}"
                          ${ARCHITECTURE_OPTION_CMAKE}
                          -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                          -D ARROW_CSV=ON
                          -D ARROW_PARQUET=ON
                          ${ARROW_EXTRA_CMAKE_FLAG}
                          .
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_CMAKE_OUT
                  ERROR_VARIABLE ARROW_CMAKE_ERR
                  RESULT_VARIABLE ARROW_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_ERR})

  if(NOT ARROW_CMAKE_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Generating arrow build system .. failed")
  else()
    message(STATUS "Generating arrow build system .. done")
  endif()

  message(STATUS "Building arrow lib (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${ARROW_DIR} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_BUILD_OUT
                  ERROR_VARIABLE ARROW_BUILD_ERR
                  RESULT_VARIABLE ARROW_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_BUILD_OUT})
  file(APPEND ${LOGFILE} ${ARROW_BUILD_ERR})

  if(NOT ARROW_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building arrow lib (Debug) .. failed")
  else()
    message(STATUS "Building arrow lib (Debug) .. done")
  endif()

  # rebuild as release
  message(STATUS "Building arrow lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${ARROW_DIR} --target INSTALL --config Release
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_BUILD_OUT
                  ERROR_VARIABLE ARROW_BUILD_ERR
                  RESULT_VARIABLE ARROW_BUILD_SUCCESS)
  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_BUILD_OUT})
  file(APPEND ${LOGFILE} ${ARROW_BUILD_ERR})

  if(NOT ARROW_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building arrow lib (Release) .. failed")
  else()
    message(STATUS "Building arrow lib (Release) .. done")
  endif()

else() ## Linux/MacOS

  if(APPLE)
    set(_ARROW_CMAKE_ARGS
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
        "-DCMAKE_MACOSX_RPATH=TRUE"
      )
  else()
    set(_ARROW_CMAKE_ARGS "")
  endif()

  # CFLAGS for libsvm compiler (see libsvm Makefile)
  set(ARROW_CFLAGS "-Wall -O3 -fPIC")

  message(STATUS "Generating arrow build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_ARROW_CMAKE_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          -D CMAKE_BUILD_TYPE=Release
                          -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                          -D CMAKE_C_FLAGS=${ARROW_CFLAGS}
                          -D ARROW_CSV=ON
                          -D ARROW_PARQUET=ON
                          .
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_CMAKE_OUT
                  ERROR_VARIABLE ARROW_CMAKE_ERR
                  RESULT_VARIABLE ARROW_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_ERR})

  if(NOT ARROW_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "Generating arrow build system .. failed")
    message(STATUS "Output: ${ARROW_CMAKE_OUT}")
    message(STATUS "Error: ${ARROW_CMAKE_ERR}")
    message(FATAL_ERROR "Arrow configuration failed. Check the log file for details: ${LOGFILE}")
  else()
    message(STATUS "Generating arrow build system .. done")
  endif()

  # rebuild as release
  message(STATUS "Building arrow lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                  --build ${ARROW_DIR}
                  --target install
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_BUILD_OUT
                  ERROR_VARIABLE ARROW_BUILD_ERR
                  RESULT_VARIABLE ARROW_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_BUILD_OUT})
  file(APPEND ${LOGFILE} ${ARROW_BUILD_ERR})

  if(NOT ARROW_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building arrow lib (Release) .. failed")
  else()
    message(STATUS "Building arrow lib (Release) .. done")
  endif()

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_ARROW )