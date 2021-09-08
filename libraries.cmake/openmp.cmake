##################################################
###       OPENMP                               ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_OPENMP )
OPENMS_LOGHEADER_LIBRARY("libomp")
# extract: (takes very long.. so skip if possible)
if(MSVC)
  set(ZIP_ARGS "x -y -osrc")
else()
  set(ZIP_ARGS "xzf")
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_OPENMP "OPENMP" "README")

if (MSVC)
  message(STATUS "Generating openmp build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          -D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
                          -D INSTALL_BIN_DIR=${PROJECT_BINARY_DIR}/lib
                          -G "${CMAKE_GENERATOR}"
                          ${ARCHITECTURE_OPTION_CMAKE}
                          -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                          ${OPENMP_EXTRA_CMAKE_FLAG}
                          .
                  WORKING_DIRECTORY ${OPENMP_DIR}
                  OUTPUT_VARIABLE OPENMP_CMAKE_OUT
                  ERROR_VARIABLE OPENMP_CMAKE_ERR
                  RESULT_VARIABLE OPENMP_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${OPENMP_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${OPENMP_CMAKE_ERR})

  if(NOT OPENMP_CMAKE_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Generating libomp build system .. failed")
  else()
    message(STATUS "Generating libomp build system .. done")
  endif()

  message(STATUS "Building libomp (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${OPENMP_DIR} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${OPENMP_DIR}
                  OUTPUT_VARIABLE OPENMP_BUILD_OUT
                  ERROR_VARIABLE OPENMP_BUILD_ERR
                  RESULT_VARIABLE OPENMP_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_ERR})

  if(NOT OPENMP_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building libomp (Debug) .. failed")
  else()
    message(STATUS "Building libomp (Debug) .. done")
  endif()

  # rebuild as release
  message(STATUS "Building libomp (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${OPENMP_DIR} --target INSTALL --config Release
                  WORKING_DIRECTORY ${OPENMP_DIR}
                  OUTPUT_VARIABLE OPENMP_BUILD_OUT
                  ERROR_VARIABLE OPENMP_BUILD_ERR
                  RESULT_VARIABLE OPENMP_BUILD_SUCCESS)
  # output to logfile
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_ERR})

  if(NOT OPENMP_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building libomp lib (Release) .. failed")
  else()
    message(STATUS "Building libomp lib (Release) .. done")
  endif()

else()
  if (APPLE)
    set(_OPENMP_CMAKE_ARGS
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
        "-DCMAKE_MACOSX_RPATH=TRUE"
       )
  else()
    set(_OPENMP_CMAKE_ARGS "")
  endif()

  # CFLAGS for openmp compiler
  set(OPENMP_CFLAGS "-Wall -O3 -fPIC")

  message(STATUS "Generating libomp build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_OPENMP_CMAKE_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          -D CMAKE_BUILD_TYPE=Release
                          -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                          -D CMAKE_C_FLAGS=${OPENMP_CFLAGS}
                          .
                  WORKING_DIRECTORY ${OPENMP_DIR}
                  OUTPUT_VARIABLE OPENMP_CMAKE_OUT
                  ERROR_VARIABLE OPENMP_CMAKE_ERR
                  RESULT_VARIABLE OPENMP_CMAKE_SUCCESS)

  # rebuild as release
  message(STATUS "Building libomp (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                  --build ${OPENMP_DIR}
                  --target install
                  WORKING_DIRECTORY ${OPENMP_DIR}
                  OUTPUT_VARIABLE OPENMP_BUILD_OUT
                  ERROR_VARIABLE OPENMP_BUILD_ERR
                  RESULT_VARIABLE OPENMP_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_OUT})
  file(APPEND ${LOGFILE} ${OPENMP_BUILD_ERR})

  if(NOT OPENMP_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building libomp (Release) .. failed")
  else()
    message(STATUS "Building libomp (Release) .. done")
  endif()

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_OPENMP )
