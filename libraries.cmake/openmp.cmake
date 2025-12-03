##################################################
###       OPENMP                               ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_OPENMP )
OPENMS_LOGHEADER_LIBRARY("libomp")
# extract: (takes very long.. so skip if possible)
if(MSVC)
  set(ZIP_ARGS x -y -osrc)
else()
  set(ZIP_ARGS xJf)
endif()
OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_OPENMP "OPENMP" "README")

if (APPLE)
  # see https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/libomp.rb
  # Disable LIBOMP_INSTALL_ALIASES, otherwise the library is installed as
  # libgomp alias which can conflict with GCC's libgomp.

  set(_OPENMP_CMAKE_ARGS
      "-DLIBOMP_INSTALL_ALIASES=OFF"
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
      "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
      "-DCMAKE_MACOSX_RPATH=TRUE"
      )

# CFLAGS for openmp compiler
set(OPENMP_CFLAGS "-Wall -O3 -fPIC")

message(STATUS "Generating libomp build system .. ")
execute_process(COMMAND ${CMAKE_COMMAND}
                        ${_OPENMP_CMAKE_ARGS}
                        -G "${CMAKE_GENERATOR}"
                        -D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
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
  message(FATAL_ERROR "Building libomp .. failed")
else()
  message(STATUS "Building libomp .. done")
endif()

else()
  message(STATUS "libomp will only be compiled on macOS")

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_OPENMP )
