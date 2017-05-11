##################################################
###       KISSFFT   														 ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_KISSFFT )
  OPENMS_LOGHEADER_LIBRARY("kissfft")

  if(MSVC)
    set(ZIP_ARGS "x -y -osrc")
  else()
    set(ZIP_ARGS "xzf")
  endif()
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_KISSFFT "kissfft" "README")
  
  #patch
  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftnd.h.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftnd.h")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftndr.h.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftndr.h")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftndr.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftndr.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftr.h.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftr.h")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftr.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftr.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kfc.h.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kfc.h")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/fftutil.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/fftutil.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/psdpng.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/psdpng.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fastfir.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fastfir.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/kissfft/kiss_fftnd.c.patch")
  set(PATCHED_FILE "${KISSFFT_DIR}/tools/kiss_fftnd.c")
  OPENMS_PATCH( PATCH_FILE KISSFFT_DIR PATCHED_FILE)  


  ## we use our own CMakeLists.txt for kissfft
  configure_file(${PROJECT_SOURCE_DIR}/patches/kissfft/CMakeLists.txt ${KISSFFT_DIR}/CMakeLists.txt COPYONLY)



  ## build the obj/lib
  if (MSVC)
		message(STATUS "Generating kissfft build system .. ")
    execute_process(COMMAND ${CMAKE_COMMAND}
													-D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
													-G "${CMAKE_GENERATOR}"
													-D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
													.
										WORKING_DIRECTORY ${KISSFFT_DIR}
										OUTPUT_VARIABLE KISSFFT_CMAKE_OUT
										ERROR_VARIABLE KISSFFT_CMAKE_ERR
										RESULT_VARIABLE KISSFFT_CMAKE_SUCCESS)

		# output to logfile
		file(APPEND ${LOGFILE} ${KISSFFT_CMAKE_OUT})
		file(APPEND ${LOGFILE} ${KISSFFT_CMAKE_ERR})

		if (NOT KISSFFT_CMAKE_SUCCESS EQUAL 0)
			message(FATAL_ERROR "Generating kissfft build system .. failed")
		else()
			message(STATUS "Generating kissfft build system .. done")
		endif()

		message(STATUS "Building kissfft lib (Debug) .. ")
		execute_process(COMMAND ${CMAKE_COMMAND} --build ${KISSFFT_DIR} --target INSTALL --config Debug
										WORKING_DIRECTORY ${KISSFFT_DIR}
										OUTPUT_VARIABLE KISSFFT_BUILD_OUT
										ERROR_VARIABLE KISSFFT_BUILD_ERR
										RESULT_VARIABLE KISSFFT_BUILD_SUCCESS)

		# output to logfile
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_OUT})
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_ERR})

		if (NOT KISSFFT_BUILD_SUCCESS EQUAL 0)
			message(FATAL_ERROR "Building kissfft lib (Debug) .. failed")
		else()
			message(STATUS "Building kissfft lib (Debug) .. done")
		endif()

		## rebuild as release
		message(STATUS "Building kissfft lib (Release) .. ")
		execute_process(COMMAND ${CMAKE_COMMAND} --build ${KISSFFT_DIR} --target INSTALL --config Release
										WORKING_DIRECTORY ${KISSFFT_DIR}
										OUTPUT_VARIABLE KISSFFT_BUILD_OUT
										ERROR_VARIABLE KISSFFT_BUILD_ERR
										RESULT_VARIABLE KISSFFT_BUILD_SUCCESS)
		# output to logfile
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_OUT})
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_ERR})

		if (NOT KISSFFT_BUILD_SUCCESS EQUAL 0)
			message(FATAL_ERROR "Building kissfft lib (Release) .. failed")
		else()
			message(STATUS "Building kissfft lib (Release) .. done")
		endif()

  else()

    # CFLAGS for kissfft compiler (see libsvm Makefile)
    set(KISSFFT_CFLAGS "-Wall -O3 -pedantic -ffast-math -fomit-frame-pointer")

    # add OS X specific flags
    if( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )
      set(KISSFFT_CFLAGS "${KISSFFT_CFLAGS} ${OSX_DEPLOYMENT_FLAG}")
    endif( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )

		message(STATUS "Generating kissfft build system .. ")
		if (APPLE)
			execute_process(COMMAND ${CMAKE_COMMAND}
														-D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
														-D CMAKE_C_COMPILER=${CMAKE_C_COMPILER}
														-D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
														-D CMAKE_C_FLAGS='${KISSFFT_CFLAGS}'
														-G "${CMAKE_GENERATOR}"
														-D CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
														-D CMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
														-D CMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
														.
											WORKING_DIRECTORY ${KISSFFT_DIR}
											OUTPUT_VARIABLE KISSFFT_CMAKE_OUT
											ERROR_VARIABLE KISSFFT_CMAKE_ERR
											RESULT_VARIABLE KISSFFT_CMAKE_SUCCESS)
		else()
			execute_process(COMMAND ${CMAKE_COMMAND}
												-D BUILD_SHARED_LIBS=${BUILD_SHARED_LIBRARIES}
												-D CMAKE_C_COMPILER=${CMAKE_C_COMPILER}
												-D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
												-D CMAKE_C_FLAGS='${KISSFFT_CFLAGS}'
												-G "${CMAKE_GENERATOR}"
												.
									WORKING_DIRECTORY ${KISSFFT_DIR}
									OUTPUT_VARIABLE KISSFFT_CMAKE_OUT
									ERROR_VARIABLE KISSFFT_CMAKE_ERR
									RESULT_VARIABLE KISSFFT_CMAKE_SUCCESS)
		endif()
		# output to logfile
		file(APPEND ${LOGFILE} ${KISSFFT_CMAKE_OUT})
		file(APPEND ${LOGFILE} ${KISSFFT_CMAKE_ERR})

		if (NOT KISSFFT_CMAKE_SUCCESS EQUAL 0)
			message(FATAL_ERROR "Generating kissfft build system .. failed")
		else()
			message(STATUS "Generating kissfft build system .. done")
		endif()

		message(STATUS "Building kissfft lib (Release) .. ")
		execute_process(COMMAND ${CMAKE_COMMAND} --build ${KISSFFT_DIR} --target install --config Release
										WORKING_DIRECTORY ${KISSFFT_DIR}
										OUTPUT_VARIABLE KISSFFT_BUILD_OUT
										ERROR_VARIABLE KISSFFT_BUILD_ERR
										RESULT_VARIABLE KISSFFT_BUILD_SUCCESS)
		# output to logfile
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_OUT})
		file(APPEND ${LOGFILE} ${KISSFFT_BUILD_ERR})

		if (NOT KISSFFT_BUILD_SUCCESS EQUAL 0)
			message(FATAL_ERROR "Building kissfft lib (Release) .. failed")
		else()
			message(STATUS "Building kissfft lib (Release) .. done")
		endif()
endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_KISSFFT )
