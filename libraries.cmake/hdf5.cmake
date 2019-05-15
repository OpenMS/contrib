##################################################
###       HDF5                                 ###
##################################################
MACRO( OPENMS_CONTRIB_BUILD_HDF5 )

  # Minimal cmake requirement for building HDF5 1.10.5
  cmake_minimum_required(VERSION 3.10.0 FATAL_ERROR)

  OPENMS_LOGHEADER_LIBRARY("HDF5")
  #extract: (takes very long.. so skip if possible)
  if(MSVC)
    set(ZIP_ARGS "x -y -osrc")
  else()
    set(ZIP_ARGS "xzf")
  endif(MSVC)
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_HDF5 "HDF5" "INSTALL")

  message( STATUS "Building HDF5 library in  ${HDF5_DIR}")

  # we want out-of-source builds
  set(_HDF5_BUILD_DIR "${HDF5_DIR}/build")
  file(TO_NATIVE_PATH "${_HDF5_BUILD_DIR}" _HDF5_NATIVE_BUILD_DIR)

  if(APPLE)
    set( _HDF5_CMAKE_ARGS
        "-D CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}"
        "-D CMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-D CMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
    )
  else()
    set( _HDF5_CMAKE_ARGS "")
  endif()

  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${_HDF5_NATIVE_BUILD_DIR})

  message(STATUS "Generating HDF5 build system .. in ${_HDF5_NATIVE_BUILD_DIR}")
  message(STATUS "Build shared libs .. in ${BUILD_SHARED_LIBRARIES}")
  message(STATUS "Generating HDF5 build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                        -G "${CMAKE_GENERATOR}"
                        -D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
                        -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
                        -D BUILD_TESTING=Off
                        -D HDF5_BUILD_EXAMPLES=Off
                        -D HDF5_BUILD_TOOLS=Off
                        ${_HDF5_CMAKE_ARGS}
                        ${HDF5_DIR}
                        WORKING_DIRECTORY ${_HDF5_NATIVE_BUILD_DIR}
                        OUTPUT_VARIABLE _HDF5_CMAKE_OUT
                        ERROR_VARIABLE _HDF5_CMAKE_ERR
                        RESULT_VARIABLE _HDF5_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${_HDF5_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${_HDF5_CMAKE_ERR})

  if (NOT _HDF5_CMAKE_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Generating HDF5 build system .. failed")
  else()
    message(STATUS "Generating HDF5 build system .. done")
  endif()


  # the install target on windows has a different name then on mac/lnx
  if(MSVC)
    set(_HDF5_INSTALL_TARGET "INSTALL")
  else()
    set(_HDF5_INSTALL_TARGET "install")
  endif()

  # build release first
  message(STATUS "Building HDF5 library (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${_HDF5_NATIVE_BUILD_DIR} --target ${_HDF5_INSTALL_TARGET} --config Release
                          WORKING_DIRECTORY ${_HDF5_NATIVE_BUILD_DIR}
                          OUTPUT_VARIABLE _HDF5_BUILD_OUT
                          ERROR_VARIABLE _HDF5_BUILD_ERR
                          RESULT_VARIABLE _HDF5_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${_HDF5_BUILD_OUT})
  file(APPEND ${LOGFILE} ${_HDF5_BUILD_ERR})

  if (NOT _HDF5_BUILD_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Building HDF5 library (Release) .. failed")
  else()
    message(STATUS "Building HDF5 library (Release) .. done")
  endif()

  # we also want the debug lib on windows
  if(MSVC)
    # build debug
    message(STATUS "Building HDF5 library (Debug) .. ")
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${_HDF5_NATIVE_BUILD_DIR} --target ${_HDF5_INSTALL_TARGET} --config Debug
                            WORKING_DIRECTORY ${_HDF5_NATIVE_BUILD_DIR}
                            OUTPUT_VARIABLE _HDF5_BUILD_OUT
                            ERROR_VARIABLE _HDF5_BUILD_ERR
                            RESULT_VARIABLE _HDF5_BUILD_SUCCESS)

    # output to logfile
    file(APPEND ${LOGFILE} ${_HDF5_BUILD_OUT})
    file(APPEND ${LOGFILE} ${_HDF5_BUILD_ERR})

    if (NOT _HDF5_BUILD_SUCCESS EQUAL 0)
      message(FATAL_ERROR "Building HDF5 library (Debug) .. failed")
    else()
      message(STATUS "Building HDF5 library (Debug) .. done")
    endif()
  endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_HDF5 )

