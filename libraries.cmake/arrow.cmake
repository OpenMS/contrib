##################################################
###       Arrow   							   ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_ARROW )
OPENMS_LOGHEADER_LIBRARY("arrow")
#extract: (takes very long.. so skip if possible)
if(MSVC)
  # -snl allows dangerous symlinks (Arrow has symlinks like python/cmake_modules -> ../cpp/cmake_modules)
  set(ZIP_ARGS x -y -snld20 -osrc)
else()
  set(ZIP_ARGS xzf)
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
                          -D CMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}
                          -D CMAKE_INSTALL_LIBDIR=${PROJECT_BINARY_DIR}/lib
                          -D BOOST_ROOT=${PROJECT_BINARY_DIR}
                          -D Boost_DIR=${PROJECT_BINARY_DIR}
                          -D ARROW_CSV=ON
                          -D ARROW_PARQUET=ON
                          -D ARROW_WITH_ZLIB=ON
                          -D ARROW_WITH_BZIP2=ON
                          -D ARROW_WITH_ZSTD=ON
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

  # Build list of platform-specific CMake args
  set(_ARROW_CMAKE_ARGS)
  if(APPLE)
    list(APPEND _ARROW_CMAKE_ARGS
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
        "-DCMAKE_MACOSX_RPATH=TRUE"
      )
  endif()

  # CFLAGS for arrow compiler
  set(ARROW_CFLAGS "-Wall -O3 -fPIC")
  set(ARROW_CXXFLAGS "-Wall -O3 -fPIC -I${PROJECT_BINARY_DIR}/include")

  message(STATUS "Generating arrow build system .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${_ARROW_CMAKE_ARGS}
                          -G "${CMAKE_GENERATOR}"
                          "-DCMAKE_BUILD_TYPE=Release"
                          "-DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}"
                          "-DCMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}"
                          "-DCMAKE_C_FLAGS=${ARROW_CFLAGS}"
                          "-DCMAKE_CXX_FLAGS=${ARROW_CXXFLAGS}"
                          "-DBOOST_ROOT=${PROJECT_BINARY_DIR}"
                          "-DBoost_DIR=${PROJECT_BINARY_DIR}"
                          "-DARROW_CSV=ON"
                          "-DARROW_PARQUET=ON"
                          "-DARROW_WITH_ZLIB=ON"
                          "-DARROW_WITH_BZIP2=ON"
                          "-DARROW_WITH_ZSTD=ON"
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
    message(STATUS "Output: ${ARROW_BUILD_OUT}")
    message(STATUS "Error: ${ARROW_BUILD_ERR}")
    message(FATAL_ERROR "Building arrow lib (Release) .. failed")
  else()
    message(STATUS "Building arrow lib (Release) .. done")
  endif()

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_ARROW )
