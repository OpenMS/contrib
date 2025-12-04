##################################################
###                  Eigen3                    ###
##################################################

## build and install eigen
macro( OPENMS_CONTRIB_BUILD_EIGEN )

  OPENMS_LOGHEADER_LIBRARY("eigen")
  
  if(MSVC)
    set(ZIP_ARGS x -y -osrc)
  else()
    set(ZIP_ARGS xzf)
  endif()
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_EIGEN "EIGEN" "CMakeLists.txt")

  # eigen doesn't allow insource builds
  set(_EIGEN_BUILD_DIR "${EIGEN_DIR}/build")
  file(TO_NATIVE_PATH "${_EIGEN_BUILD_DIR}" _EIGEN_NATIVE_BUILD_DIR)

  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${_EIGEN_NATIVE_BUILD_DIR})

  message(STATUS "Generating eigen build system .. ")
  message(STATUS "  CMake generator: ${CMAKE_GENERATOR}")
  message(STATUS "  Source dir: ${EIGEN_DIR}")
  message(STATUS "  Build dir: ${_EIGEN_NATIVE_BUILD_DIR}")

  # Use CMAKE_COMMAND to create an empty file for stdin redirection
  # This prevents child processes from inheriting stdin (which changed from exec_program to execute_process)
  set(_EIGEN_NULL_INPUT "${_EIGEN_BUILD_DIR}/null_input.txt")
  file(WRITE "${_EIGEN_NULL_INPUT}" "")

  execute_process(COMMAND ${CMAKE_COMMAND}
                  -G "${CMAKE_GENERATOR}"
                  ${ARCHITECTURE_OPTION_CMAKE}
                  -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                  -D BUILD_TESTING:BOOL=OFF
                  -D EIGEN_TEST_NOQT=ON
                  -D CMAKE_Fortran_COMPILER=NOTFOUND
                  ${EIGEN_DIR}
                  WORKING_DIRECTORY ${_EIGEN_NATIVE_BUILD_DIR}
                  INPUT_FILE ${_EIGEN_NULL_INPUT}
                  OUTPUT_VARIABLE _EIGEN_CMAKE_OUT
                  ERROR_VARIABLE _EIGEN_CMAKE_ERR
                  RESULT_VARIABLE _EIGEN_CMAKE_SUCCESS
                  TIMEOUT 600)

  # output to logfile
  file(APPEND ${LOGFILE} ${_EIGEN_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${_EIGEN_CMAKE_ERR})

  if (NOT _EIGEN_CMAKE_SUCCESS EQUAL 0)
    message(STATUS "CMake stdout: ${_EIGEN_CMAKE_OUT}")
    message(STATUS "CMake stderr: ${_EIGEN_CMAKE_ERR}")
    message(FATAL_ERROR "Generating eigen build system .. failed (exit code: ${_EIGEN_CMAKE_SUCCESS})")
  else()
    message(STATUS "Generating eigen build system .. done")
  endif()

  # the install target on windows has a different name then on mac/lnx
  if(MSVC)
      set(_EIGEN_INSTALL_TARGET "INSTALL")
  else()
      set(_EIGEN_INSTALL_TARGET "install")
  endif()

  message(STATUS "Installing eigen headers .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${_EIGEN_NATIVE_BUILD_DIR} --target ${_EIGEN_INSTALL_TARGET} --config Release
                  WORKING_DIRECTORY ${_EIGEN_NATIVE_BUILD_DIR}
                  OUTPUT_VARIABLE _EIGEN_BUILD_OUT
                  ERROR_VARIABLE _EIGEN_BUILD_ERR
                  RESULT_VARIABLE _EIGEN_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${_EIGEN_BUILD_OUT})
  file(APPEND ${LOGFILE} ${_EIGEN_BUILD_ERR})

  if (NOT _EIGEN_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Build stdout: ${_EIGEN_BUILD_OUT}")
    message(STATUS "Build stderr: ${_EIGEN_BUILD_ERR}")
    message(FATAL_ERROR "Installing eigen headers .. failed (exit code: ${_EIGEN_BUILD_SUCCESS})")
  else()
    message(STATUS "Installing eigen headers .. done")
  endif()
endmacro( OPENMS_CONTRIB_BUILD_EIGEN )
