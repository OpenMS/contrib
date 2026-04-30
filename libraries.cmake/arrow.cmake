##################################################
###       Arrow   							   ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_ARROW )
OPENMS_LOGHEADER_LIBRARY("arrow")
#extract: (takes very long.. so skip if possible)
if(MSVC)
  # Arrow's archive contains symbolic links (e.g., python/cmake_modules -> ../cpp/cmake_modules).
  # 7-Zip cannot create symlinks on Windows without admin privileges (issue #177).
  # Use cmake -E tar instead, which handles symlinks gracefully by copying target content.
  download_contrib_archive(ARROW)
  if(NOT EXISTS ${ARROW_DIR}/CMakeLists.txt)
    message(STATUS "Extracting ARROW ..")
    file(MAKE_DIRECTORY "${CONTRIB_BIN_SOURCE_DIR}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf "${PROJECT_BINARY_DIR}/archives/${ARCHIVE_ARROW}"
      WORKING_DIRECTORY "${CONTRIB_BIN_SOURCE_DIR}"
      OUTPUT_VARIABLE ZIP_OUT
      ERROR_VARIABLE ZIP_ERR
      RESULT_VARIABLE EXTRACT_SUCCESS
    )
    if(NOT EXTRACT_SUCCESS EQUAL 0)
      message(STATUS "Extracting ARROW .. failed")
      message(STATUS "${ZIP_ERR}")
      message(FATAL_ERROR "${ZIP_OUT}")
    else()
      message(STATUS "Extracting ARROW .. done")
    endif()
  else()
    message(STATUS "Extracting ARROW .. skipped (already exists)")
  endif()
else()
  set(ZIP_ARGS xzf)
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_ARROW "ARROW" "README")
endif()

## Arrow dependencies not built by the contrib (Snappy, zstd, Thrift, xsimd, RapidJSON)
## are fetched and built as bundled dependencies by Arrow's own build system.
## This avoids requiring these as system packages (fixes build on e.g. Debian 12).
## Dependencies already provided by contrib (zlib, bzip2, boost) are found via CMAKE_PREFIX_PATH.
## Note: building Arrow requires internet access for the bundled dependency downloads.

## build the obj/lib
if (MSVC)
  set(ARROW_CXXFLAGS "/I${PROJECT_BINARY_DIR}/include")

  # Use separate build directories for Debug and Release so that the bundled
  # ExternalProject dependencies (Snappy, zstd, Thrift, etc.) are compiled with
  # the correct runtime (/MDd for Debug, /MD for Release).  Arrow's build system
  # derives ARROW_EP_BUILD_TYPE from CMAKE_BUILD_TYPE; passing CMAKE_BUILD_TYPE
  # explicitly therefore controls the runtime used for the bundled deps.
  set(ARROW_BUILD_DIR_DEBUG   "${ARROW_DIR}/build_debug")
  set(ARROW_BUILD_DIR_RELEASE "${ARROW_DIR}/build_release")

  # Patch ArrowConfig.cmake.in so the installed config file references
  # arrow_bundled_dependenciesd.lib for the Debug configuration and
  # arrow_bundled_dependencies.lib for Release.  This is necessary because the
  # merged bundled-dependencies library is not a regular CMake target and
  # therefore does not automatically gain a debug postfix.
  #
  # Two targeted single-line replacements are used to avoid fragile multiline
  # string matching that may break with different line-ending conventions:
  #   1. Add the if/else postfix variable inside the foreach loop header.
  #   2. Insert ${_arrow_bundled_dep_postfix} into the IMPORTED_LOCATION path.
  set(_ARROW_CONFIG_TEMPLATE "${ARROW_DIR}/src/arrow/ArrowConfig.cmake.in")
  if(EXISTS "${_ARROW_CONFIG_TEMPLATE}")
    file(READ "${_ARROW_CONFIG_TEMPLATE}" _ARROW_CFG_CONTENT)
    if(NOT "${_ARROW_CFG_CONTENT}" MATCHES "_arrow_bundled_dep_postfix")
      # Step 1: after "foreach(CONFIGURATION ...)" inject the postfix variable.
      string(REPLACE
        "foreach(CONFIGURATION \${arrow_static_configurations})"
        "foreach(CONFIGURATION \${arrow_static_configurations})\n    if(CONFIGURATION STREQUAL \"DEBUG\")\n      set(_arrow_bundled_dep_postfix \"d\")\n    else()\n      set(_arrow_bundled_dep_postfix \"\")\n    endif()"
        _ARROW_CFG_CONTENT "${_ARROW_CFG_CONTENT}")
      # Step 2: insert the postfix variable before ${CMAKE_STATIC_LIBRARY_SUFFIX}
      # in the IMPORTED_LOCATION for arrow_bundled_dependencies.
      string(REPLACE
        "arrow_bundled_dependencies\${CMAKE_STATIC_LIBRARY_SUFFIX}"
        "arrow_bundled_dependencies\${_arrow_bundled_dep_postfix}\${CMAKE_STATIC_LIBRARY_SUFFIX}"
        _ARROW_CFG_CONTENT "${_ARROW_CFG_CONTENT}")
      file(WRITE "${_ARROW_CONFIG_TEMPLATE}" "${_ARROW_CFG_CONTENT}")
      message(STATUS "Patched ArrowConfig.cmake.in for debug bundled-dependency postfix")
    else()
      message(STATUS "ArrowConfig.cmake.in already patched for debug bundled-dependency postfix (skipped)")
    endif()
  endif()

  # Common CMake arguments shared by both Debug and Release configurations
  set(ARROW_COMMON_CMAKE_ARGS
      -D ARROW_BUILD_SHARED=${BUILD_SHARED_LIBRARIES}
      -D ARROW_BUILD_STATIC=ON
      -D CMAKE_INSTALL_BINDIR=lib
      -G "${CMAKE_GENERATOR}"
      ${ARCHITECTURE_OPTION_CMAKE}
      -D CMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
      -D CMAKE_PREFIX_PATH=${PROJECT_BINARY_DIR}
      -D CMAKE_INSTALL_LIBDIR=lib
      -D BOOST_ROOT=${PROJECT_BINARY_DIR}
      -D Boost_DIR=${PROJECT_BINARY_DIR}
      -D CMAKE_CXX_FLAGS=${ARROW_CXXFLAGS}
      -D ARROW_CSV=ON
      -D ARROW_PARQUET=ON
      -D ARROW_WITH_ZLIB=ON
      -D ARROW_WITH_BZIP2=ON
      -D ARROW_WITH_ZSTD=ON
      -D ARROW_WITH_SNAPPY=ON
      -D ARROW_S3=OFF
      -D Snappy_SOURCE=BUNDLED
      -D zstd_SOURCE=BUNDLED
      -D Thrift_SOURCE=BUNDLED
      -D xsimd_SOURCE=BUNDLED
      -D RapidJSON_SOURCE=BUNDLED
      # CMAKE_DEBUG_POSTFIX=d ensures arrow_static, parquet_static and other
      # regular CMake library targets install as e.g. arrow_staticd.lib in Debug.
      -D CMAKE_DEBUG_POSTFIX=d)

  # ---- Debug build ----
  message(STATUS "Generating arrow build system (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${ARROW_COMMON_CMAKE_ARGS}
                          # Setting CMAKE_BUILD_TYPE causes Arrow to propagate this
                          # value to its bundled ExternalProject dependencies via
                          # ARROW_EP_BUILD_TYPE, ensuring they use the Debug MSVC
                          # runtime (/MDd).
                          -D CMAKE_BUILD_TYPE=Debug
                          -S ${ARROW_DIR}
                          -B ${ARROW_BUILD_DIR_DEBUG}
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_CMAKE_OUT
                  ERROR_VARIABLE ARROW_CMAKE_ERR
                  RESULT_VARIABLE ARROW_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_ERR})

  if(NOT ARROW_CMAKE_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Generating arrow build system (Debug) .. failed")
  else()
    message(STATUS "Generating arrow build system (Debug) .. done")
  endif()

  message(STATUS "Building arrow lib (Debug) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${ARROW_BUILD_DIR_DEBUG} --target INSTALL --config Debug
                  WORKING_DIRECTORY ${ARROW_BUILD_DIR_DEBUG}
                  OUTPUT_VARIABLE ARROW_BUILD_OUT
                  ERROR_VARIABLE ARROW_BUILD_ERR
                  RESULT_VARIABLE ARROW_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_BUILD_OUT})
  file(APPEND ${LOGFILE} ${ARROW_BUILD_ERR})

  if(NOT ARROW_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building arrow lib (Debug) .. failed")
    message(STATUS "Output: ${ARROW_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${ARROW_BUILD_ERR}")
  else()
    message(STATUS "Building arrow lib (Debug) .. done")
  endif()

  # Rename the debug bundled-dependencies library so it coexists with the
  # release version.  Arrow's arrow_bundled_dependencies merged static library
  # is installed via install(FILES ...) and therefore does not automatically
  # respect CMAKE_DEBUG_POSTFIX.  We rename it here so that the Debug build
  # installs as arrow_bundled_dependenciesd.lib and the subsequent Release build
  # installs as arrow_bundled_dependencies.lib.
  if(EXISTS "${PROJECT_BINARY_DIR}/lib/arrow_bundled_dependencies.lib")
    file(RENAME
         "${PROJECT_BINARY_DIR}/lib/arrow_bundled_dependencies.lib"
         "${PROJECT_BINARY_DIR}/lib/arrow_bundled_dependenciesd.lib")
    message(STATUS "Renamed debug arrow_bundled_dependencies.lib -> arrow_bundled_dependenciesd.lib")
  endif()

  # ---- Release build ----
  message(STATUS "Generating arrow build system (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${ARROW_COMMON_CMAKE_ARGS}
                          -D CMAKE_BUILD_TYPE=Release
                          -S ${ARROW_DIR}
                          -B ${ARROW_BUILD_DIR_RELEASE}
                  WORKING_DIRECTORY ${ARROW_DIR}
                  OUTPUT_VARIABLE ARROW_CMAKE_OUT
                  ERROR_VARIABLE ARROW_CMAKE_ERR
                  RESULT_VARIABLE ARROW_CMAKE_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_OUT})
  file(APPEND ${LOGFILE} ${ARROW_CMAKE_ERR})

  if(NOT ARROW_CMAKE_SUCCESS EQUAL 0)
    message(FATAL_ERROR "Generating arrow build system (Release) .. failed")
  else()
    message(STATUS "Generating arrow build system (Release) .. done")
  endif()

  message(STATUS "Building arrow lib (Release) .. ")
  execute_process(COMMAND ${CMAKE_COMMAND} --build ${ARROW_BUILD_DIR_RELEASE} --target INSTALL --config Release
                  WORKING_DIRECTORY ${ARROW_BUILD_DIR_RELEASE}
                  OUTPUT_VARIABLE ARROW_BUILD_OUT
                  ERROR_VARIABLE ARROW_BUILD_ERR
                  RESULT_VARIABLE ARROW_BUILD_SUCCESS)

  # output to logfile
  file(APPEND ${LOGFILE} ${ARROW_BUILD_OUT})
  file(APPEND ${LOGFILE} ${ARROW_BUILD_ERR})

  if(NOT ARROW_BUILD_SUCCESS EQUAL 0)
    message(STATUS "Building arrow lib (Release) .. failed")
    message(STATUS "Output: ${ARROW_BUILD_OUT}")
    message(FATAL_ERROR "Error: ${ARROW_BUILD_ERR}")
  else()
    message(STATUS "Building arrow lib (Release) .. done")
  endif()

  # Fix Arrow CMake config files to be relocatable
  # Arrow generates absolute paths in ArrowTargets.cmake and ArrowTargets-*.cmake 
  # which breaks when the package is moved to a different location.
  set(ARROW_CMAKE_DIR "${PROJECT_BINARY_DIR}/lib/cmake/Arrow")
  set(PARQUET_CMAKE_DIR "${PROJECT_BINARY_DIR}/lib/cmake/Parquet")
  
  # Normalize path separators for replacement
  file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}" PROJECT_BINARY_DIR_NORMALIZED)

  # Ensure ArrowTargets.cmake (installed from the Release build tree) also
  # includes the Debug target definitions installed from the Debug build tree.
  # Modern CMake (>= 3.22) generates a GLOB-based umbrella file so both configs
  # are picked up automatically; the block below is a safety net for older CMake
  # or edge cases where the GLOB is absent.
  set(_ARROW_TARGETS_FILE "${ARROW_CMAKE_DIR}/ArrowTargets.cmake")
  if(EXISTS "${ARROW_CMAKE_DIR}/ArrowTargets-debug.cmake" AND
     EXISTS "${_ARROW_TARGETS_FILE}")
    file(READ "${_ARROW_TARGETS_FILE}" _ARROW_TARGETS_CONTENT)
    if(NOT "${_ARROW_TARGETS_CONTENT}" MATCHES "ArrowTargets-debug")
      file(APPEND "${_ARROW_TARGETS_FILE}"
           "\n# Include Debug configuration targets\n"
           "if(EXISTS \"\${CMAKE_CURRENT_LIST_DIR}/ArrowTargets-debug.cmake\")\n"
           "  include(\"\${CMAKE_CURRENT_LIST_DIR}/ArrowTargets-debug.cmake\")\n"
           "endif()\n")
      message(STATUS "Added ArrowTargets-debug.cmake include to ArrowTargets.cmake")
    endif()
  endif()
  set(_PARQUET_TARGETS_FILE "${PARQUET_CMAKE_DIR}/ParquetTargets.cmake")
  if(EXISTS "${PARQUET_CMAKE_DIR}/ParquetTargets-debug.cmake" AND
     EXISTS "${_PARQUET_TARGETS_FILE}")
    file(READ "${_PARQUET_TARGETS_FILE}" _PARQUET_TARGETS_CONTENT)
    if(NOT "${_PARQUET_TARGETS_CONTENT}" MATCHES "ParquetTargets-debug")
      file(APPEND "${_PARQUET_TARGETS_FILE}"
           "\n# Include Debug configuration targets\n"
           "if(EXISTS \"\${CMAKE_CURRENT_LIST_DIR}/ParquetTargets-debug.cmake\")\n"
           "  include(\"\${CMAKE_CURRENT_LIST_DIR}/ParquetTargets-debug.cmake\")\n"
           "endif()\n")
      message(STATUS "Added ParquetTargets-debug.cmake include to ParquetTargets.cmake")
    endif()
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
                          "-DARROW_BUILD_SHARED=${BUILD_SHARED_LIBRARIES}"
                          "-DARROW_BUILD_STATIC=ON"
                          "-DARROW_CSV=ON"
                          "-DCMAKE_INSTALL_LIBDIR=${PROJECT_BINARY_DIR}/lib"
                          "-DARROW_PARQUET=ON"
                          "-DARROW_WITH_ZLIB=ON"
                          "-DARROW_WITH_BZIP2=ON"
                          "-DARROW_WITH_ZSTD=ON"
                          "-DARROW_WITH_SNAPPY=ON"
                          "-DARROW_S3=ON"
                          "-DAWSSDK_SOURCE=BUNDLED"
                          "-DSnappy_SOURCE=BUNDLED"
                          "-Dzstd_SOURCE=BUNDLED"
                          "-DThrift_SOURCE=BUNDLED"
                          "-Dxsimd_SOURCE=BUNDLED"
                          "-DRapidJSON_SOURCE=BUNDLED"
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

  # Fix Arrow CMake config files to be relocatable
  # Arrow generates absolute paths in ArrowTargets.cmake and ArrowTargets-*.cmake 
  # which breaks when the package is moved to a different location.
  set(ARROW_CMAKE_DIR "${PROJECT_BINARY_DIR}/lib/cmake/Arrow")
  set(PARQUET_CMAKE_DIR "${PROJECT_BINARY_DIR}/lib/cmake/Parquet")
  
  # Fix 1: Replace hardcoded _IMPORT_PREFIX in ArrowTargets.cmake
  set(ARROW_RELOCATABLE_REPLACEMENT "get_filename_component(_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_DIR}/../../..\" ABSOLUTE)")
  set(ARROW_ORIGINAL_PATTERN "set(_IMPORT_PREFIX \"${PROJECT_BINARY_DIR}\")")
  
  message(STATUS "Arrow relocatability fix:")
  message(STATUS "  Build dir: ${PROJECT_BINARY_DIR}")
  
  # Process all Arrow cmake files (ArrowTargets.cmake and ArrowTargets-*.cmake)
  file(GLOB ARROW_TARGET_FILES "${ARROW_CMAKE_DIR}/ArrowTargets*.cmake")
  foreach(TARGET_FILE ${ARROW_TARGET_FILES})
    file(READ "${TARGET_FILE}" TARGET_CONTENT)
    
    # Fix the _IMPORT_PREFIX definition (in ArrowTargets.cmake)
    string(REPLACE "${ARROW_ORIGINAL_PATTERN}" "${ARROW_RELOCATABLE_REPLACEMENT}" TARGET_CONTENT "${TARGET_CONTENT}")
    
    # Fix hardcoded paths in IMPORTED_LOCATION and other properties (in ArrowTargets-*.cmake)
    # Replace absolute paths with ${_IMPORT_PREFIX} relative paths
    string(REPLACE "\"${PROJECT_BINARY_DIR}/" "\"\${_IMPORT_PREFIX}/" TARGET_CONTENT "${TARGET_CONTENT}")
    
    file(WRITE "${TARGET_FILE}" "${TARGET_CONTENT}")
    message(STATUS "  Fixed: ${TARGET_FILE}")
  endforeach()
  
  # Process all Parquet cmake files
  file(GLOB PARQUET_TARGET_FILES "${PARQUET_CMAKE_DIR}/ParquetTargets*.cmake")
  foreach(TARGET_FILE ${PARQUET_TARGET_FILES})
    file(READ "${TARGET_FILE}" TARGET_CONTENT)
    string(REPLACE "${ARROW_ORIGINAL_PATTERN}" "${ARROW_RELOCATABLE_REPLACEMENT}" TARGET_CONTENT "${TARGET_CONTENT}")
    string(REPLACE "\"${PROJECT_BINARY_DIR}/" "\"\${_IMPORT_PREFIX}/" TARGET_CONTENT "${TARGET_CONTENT}")
    file(WRITE "${TARGET_FILE}" "${TARGET_CONTENT}")
    message(STATUS "  Fixed: ${TARGET_FILE}")
  endforeach()
  
  message(STATUS "Fixed Arrow/Parquet CMake configs for relocatability")

endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_ARROW )
