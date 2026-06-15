##################################################
###       BOOST                                ###
##################################################

MACRO( OPENMS_CONTRIB_BUILD_BOOST)
  OPENMS_LOGHEADER_LIBRARY("BOOST")
  
  set( BOOST_BUILD_TYPE "static")
  if (BUILD_SHARED_LIBRARIES)
    set( BOOST_BUILD_TYPE "shared")
  endif()
  
  ## extract boost library
  if(MSVC)
    set(ZIP_ARGS x -y -osrc)
  else()
    set(ZIP_ARGS xzf)
  endif()
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_BOOST "BOOST" "index.htm")

  # Determine number of parallel jobs (fallback to 2 if not set)
  if(DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL} AND NOT "$ENV{CMAKE_BUILD_PARALLEL_LEVEL}" STREQUAL "")
    set(_BOOST_PARALLEL_JOBS $ENV{CMAKE_BUILD_PARALLEL_LEVEL})
  else()
    set(_BOOST_PARALLEL_JOBS 2)
  endif()
  
  if(MSVC) ## build boost library for windows (Boost CMake superproject)

    ## ------------------------------------------------------------------------
    ## Boost is built via its native CMake "superproject" (the boost-1.87.0
    ## archive ships tools/cmake + per-library CMakeLists.txt since 1.82) instead
    ## of bootstrap.bat + b2/bjam. This removes the Boost.Build engine bootstrap
    ## entirely, which is what breaks on Visual Studio 2026 (b2's build.bat does
    ## not know the vc145 toolset and aborts with "Unknown toolset: vcunk").
    ##
    ## We re-invoke cmake with the SAME generator + the SAME architecture token
    ## (${ARCHITECTURE_OPTION_CMAKE}, i.e. "-A;x64" / "-A;Win32") that the sibling
    ## nested builds zlib.cmake/bzip2.cmake already use. The MSVC toolset is thus
    ## inherited from the parent contrib configure (no toolset= pinning, no silent
    ## fallback to a newer VS than the active cl.exe), and the platform handling is
    ## byte-for-byte identical to the zlib/bzip2 trees Boost depends on.
    ## NOTE: we deliberately do NOT use CMAKE_GENERATOR_PLATFORM here -- it is never
    ## set anywhere in the contrib and would be passed as an empty "-A" argument.
    ##
    ## CRT contract: OpenMS uses the dynamic CRT (Boost_USE_STATIC_RUNTIME OFF in
    ## build_system_macros.cmake). We pin /MD,/MDd explicitly via
    ## CMAKE_MSVC_RUNTIME_LIBRARY so Boost matches regardless of BOOST_RUNTIME_LINK
    ## defaults; this reproduces the old "runtime-link=shared".
    ## ------------------------------------------------------------------------

    ## fresh out-of-source build dir for the nested configure
    set(BOOST_CMAKE_BUILD_DIR "${BOOST_DIR}/build-openms")
    file(MAKE_DIRECTORY "${BOOST_CMAKE_BUILD_DIR}")

    ## static libs by default; shared only if the contrib was asked for shared libs.
    ## BUILD_SHARED_LIBS is ORTHOGONAL to the CRT: static .lib + dynamic CRT (/MD)
    ## is exactly the old link=static + runtime-link=shared.
    set(BOOST_BUILD_SHARED OFF)
    if (BUILD_SHARED_LIBRARIES)
      set(BOOST_BUILD_SHARED ON)
    endif()

    ## NOTE: we build the FULL Boost (no BOOST_INCLUDE_LIBRARIES restriction). Downstream
    ## contrib consumers (Arrow + its bundled Thrift) and OpenMS itself pull in many
    ## header-only Boost libraries (uuid, multiprecision, locale, scope_exit, ...), so the
    ## install must carry the COMPLETE header tree -- exactly what the old b2 "install"
    ## produced. Restricting to a handful of libs only installs their headers and breaks
    ## those consumers. Python/MPI stay off (boost-cmake superproject defaults).

    ## ------------------------------------------------------------------------
    ## Boost.Iostreams compression backends: ALL OFF.
    ## A single nested configure cannot supply per-config (Debug /MDd vs Release
    ## /MD) external zlib/bzip2 to a multi-config VS generator -- find_package(ZLIB)
    ## / find_package(BZip2) inside Boost.Iostreams runs ONCE and would freeze one
    ## .lib path, mixing a Release /MD libbz2.lib into the Debug /MDd Boost build
    ## (the exact mixed-CRT corruption cmake_findExternalLibs.cmake warns against).
    ## This is behavior-equivalent for OpenMS: OpenMS uses no iostreams compression
    ## filter (only filtering_ostream + null_sink in src/topp/FileInfo.cpp) and
    ## links ZLIB::ZLIB / BZip2::BZip2 directly. (Subsumes the old NO_LZMA/NO_ZSTD.)
    ## ------------------------------------------------------------------------

    message(STATUS "Configuring Boost (CMake superproject) .. ")
    execute_process(COMMAND ${CMAKE_COMMAND}
                            -G "${CMAKE_GENERATOR}"
                            ${ARCHITECTURE_OPTION_CMAKE}
                            -S "${BOOST_DIR}"
                            -B "${BOOST_CMAKE_BUILD_DIR}"
                            "-DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}"
                            ## let an even-newer CMake still configure Boost 1.87's
                            ## cmake_minimum_required(3.5...) (harmless otherwise)
                            -D CMAKE_POLICY_VERSION_MINIMUM=3.5
                            ## pin dynamic CRT (/MD,/MDd), matching Boost_USE_STATIC_RUNTIME OFF
                            "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
                            ## static .lib archives unless contrib was asked for shared
                            -D BUILD_SHARED_LIBS=${BOOST_BUILD_SHARED}
                            ## dynamic CRT == old runtime-link=shared (belt-and-suspenders
                            ## with CMAKE_MSVC_RUNTIME_LIBRARY above)
                            -D BOOST_RUNTIME_LINK=shared
                            ## tagged lib names (-mt/-gd/-x64, no vcXXX) + flat include/boost
                            ## dir == old --layout=tagged (cosmetic under CONFIG-mode consumption)
                            -D BOOST_INSTALL_LAYOUT=tagged
                            ## BoostConfig.cmake -> ${PROJECT_BINARY_DIR}/lib/cmake/Boost-1.87.0
                            -D BOOST_INSTALL_CMAKEDIR=lib/cmake
                            ## regex without ICU (== old --disable-icu): keep the COMPILED
                            ## Boost::regex target but make find_package(ICU) impossible
                            -D BOOST_REGEX_STANDALONE=OFF
                            -D BOOST_LOCALE_ENABLE_ICU=OFF
                            -D CMAKE_DISABLE_FIND_PACKAGE_ICU=ON
                            "-DICU_ROOT=${PROJECT_BINARY_DIR}/no-icu"
                            ## iostreams: all compression backends OFF (see comment above)
                            -D BOOST_IOSTREAMS_ENABLE_ZLIB=OFF
                            -D BOOST_IOSTREAMS_ENABLE_BZIP2=OFF
                            -D BOOST_IOSTREAMS_ENABLE_LZMA=OFF
                            -D BOOST_IOSTREAMS_ENABLE_ZSTD=OFF
                    WORKING_DIRECTORY ${BOOST_DIR}
                    OUTPUT_VARIABLE BOOST_CMAKE_OUT
                    ERROR_VARIABLE BOOST_CMAKE_ERR
                    RESULT_VARIABLE BOOST_CMAKE_SUCCESS)

    file(APPEND ${LOGFILE} "${BOOST_CMAKE_OUT}")
    file(APPEND ${LOGFILE} "${BOOST_CMAKE_ERR}")

    if (NOT BOOST_CMAKE_SUCCESS EQUAL 0)
      message(STATUS "Configuring Boost (CMake superproject) .. failed")
      message(FATAL_ERROR "Configuring Boost failed:\n${BOOST_CMAKE_OUT}\n${BOOST_CMAKE_ERR}")
    else()
      message(STATUS "Configuring Boost (CMake superproject) .. done")
    endif()

    ## Build + install BOTH Debug and Release into the SAME prefix (multi-config VS
    ## generator). This reproduces b2 --build-type=complete: the two install passes
    ## MERGE, so each per-component *-config.cmake imported target carries both
    ## IMPORTED_LOCATION_DEBUG (the -gd libs) and IMPORTED_LOCATION_RELEASE, and
    ## config-mode find_package picks the right variant per consumer. Do NOT prune
    ## either config: dropping Debug breaks Debug OpenMS builds (missing -mt-gd libs).
    foreach(_BOOST_CFG Debug Release)
      message(STATUS "Building Boost library (${_BOOST_CFG}) .. ")
      execute_process(COMMAND ${CMAKE_COMMAND} --build "${BOOST_CMAKE_BUILD_DIR}"
                              --config ${_BOOST_CFG}
                              -j ${_BOOST_PARALLEL_JOBS}
                      WORKING_DIRECTORY ${BOOST_DIR}
                      OUTPUT_VARIABLE BOOST_BUILD_OUT
                      ERROR_VARIABLE BOOST_BUILD_ERR
                      RESULT_VARIABLE BOOST_BUILD_SUCCESS)

      file(APPEND ${LOGFILE} "${BOOST_BUILD_OUT}")
      file(APPEND ${LOGFILE} "${BOOST_BUILD_ERR}")

      if (NOT BOOST_BUILD_SUCCESS EQUAL 0)
        message(STATUS "Building Boost library (${_BOOST_CFG}) .. failed")
        message(FATAL_ERROR "Building Boost (${_BOOST_CFG}) failed:\n${BOOST_BUILD_OUT}\n${BOOST_BUILD_ERR}")
      else()
        message(STATUS "Building Boost library (${_BOOST_CFG}) .. done")
      endif()

      message(STATUS "Installing Boost library (${_BOOST_CFG}) .. ")
      execute_process(COMMAND ${CMAKE_COMMAND} --install "${BOOST_CMAKE_BUILD_DIR}"
                              --config ${_BOOST_CFG}
                      WORKING_DIRECTORY ${BOOST_DIR}
                      OUTPUT_VARIABLE BOOST_INSTALL_OUT
                      ERROR_VARIABLE BOOST_INSTALL_ERR
                      RESULT_VARIABLE BOOST_INSTALL_SUCCESS)

      file(APPEND ${LOGFILE} "${BOOST_INSTALL_OUT}")
      file(APPEND ${LOGFILE} "${BOOST_INSTALL_ERR}")

      if (NOT BOOST_INSTALL_SUCCESS EQUAL 0)
        message(STATUS "Installing Boost library (${_BOOST_CFG}) .. failed")
        message(FATAL_ERROR "Installing Boost (${_BOOST_CFG}) failed:\n${BOOST_INSTALL_OUT}\n${BOOST_INSTALL_ERR}")
      else()
        message(STATUS "Installing Boost library (${_BOOST_CFG}) .. done")
      endif()
    endforeach()

    ## Fail LOUDLY at contrib-build time (not later at OpenMS configure) if the
    ## a core compiled component failed to install: assert each
    ## expected per-component config dir exists under the install prefix.
    foreach(_BOOST_COMP date_time iostreams regex system thread)
      file(GLOB _BOOST_COMP_CFG "${PROJECT_BINARY_DIR}/lib/cmake/boost_${_BOOST_COMP}-*")
      if (NOT _BOOST_COMP_CFG)
        message(FATAL_ERROR "Boost component '${_BOOST_COMP}' did not install a CMake config dir "
                            "under ${PROJECT_BINARY_DIR}/lib/cmake/boost_${_BOOST_COMP}-* -- "
                            "the Boost build is incomplete.")
      endif()
    endforeach()
 
  else() ## LINUX/MAC

    # we need to know the compiler version for proper formating boost user-config.jam
    determine_compiler_version()

    # Set architecture based on CMake's processor detection
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|i386|i686")
      set(BOOST_ARCHITECTURE "architecture=x86")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64")
      set(BOOST_ARCHITECTURE "architecture=arm")
    else()
      message(WARNING "Unknown architecture '${CMAKE_SYSTEM_PROCESSOR}'. Letting Boost auto-detect architecture. This may cause build issues.")
      set(BOOST_ARCHITECTURE "")
    endif()

    # use proper toolchain (random guesses. There is not proper documentation)
    if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
      # Modern Clang chokes on boost 1.78 unless we pass this (https://github.com/boostorg/mpl/issues/74)
      set(BOOST_EXTRA_CXXFLAGS "-Wno-enum-constexpr-conversion")
      # since around boost 1.70 there is not bootstrap toolset called darwin anymore
      set(_boost_bootstrap_toolchain "clang")
      if(APPLE)
        set(_boost_toolchain "darwin")
      else()
        set(_boost_toolchain "clang")
      endif()
    elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
      set(_boost_booststrap_toolchain "gcc")
      if(APPLE)
        ## For Apples old GCC (tag in lib name will be xgcc)
        set(_boost_toolchain "darwin") 
      else()
        set(_boost_toolchain "gcc")
      endif()
    endif()

    ## In case CMake picked up / or you specified a different compiler than the default in the path
    ## (which the boost toolset "gcc" will use) we need to add the specific version to the user config.
    ## Do not use on macOS as we did not figure out how to inherit all the compiler flags from the darwin
    ## or clang-darwin toolset
    if (NOT APPLE)
      file(REMOVE ${BOOST_DIR}/tools/build/src/user-config.jam)
      file(APPEND ${BOOST_DIR}/tools/build/src/user-config.jam
        "using ${_boost_toolchain} : ${CXX_COMPILER_VERSION_MAJOR}.${CXX_COMPILER_VERSION_MINOR} : \"${CMAKE_CXX_COMPILER}\" ;\n")
    endif()
    
    if(APPLE AND CMAKE_OSX_DEPLOYMENT_TARGET)
      ## Note: We do not use the official boost darwin feature "macosx-version-min" anymore, since it does not work.
      ## We pass it as usual flags now.
        ## Boost looks for installed SDKs, but sometimes you dont have them. Add them still to not fail. Clang will handle it.
        #file(APPEND ${BOOST_DIR}/tools/build/src/tools/darwin.jam
        #  "feature.extend macosx-version-min : ${CMAKE_OSX_DEPLOYMENT_TARGET} ;\n")

      ## Add corresponding linker flags (e.g. a different stdlib for macOS <10.9. Empty is not possible, therefore the if.
      if(OSX_LIB_FLAG)
        set(BOOST_LINKER_FLAGS linkflags=${OSX_LIB_FLAG})
      endif()
    endif()

    # bootstrap boost
    message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-toolset=${_boost_bootstrap_toolchain} --with-libraries=date_time,filesystem,iostreams,math,regex,system,thread) ...")
    execute_process(COMMAND ./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=filesystem,iostreams,math,date_time,regex,system,thread
                    WORKING_DIRECTORY ${BOOST_DIR}
                    OUTPUT_VARIABLE BOOST_BOOTSTRAP_OUT
                    ERROR_VARIABLE BOOST_BOOTSTRAP_OUT
                    RESULT_VARIABLE BOOST_BOOTSTRAP_SUCCESS)

    # logfile
    file(APPEND ${LOGFILE} ${BOOST_BOOTSTRAP_OUT})
    if (NOT BOOST_BOOTSTRAP_SUCCESS EQUAL 0)
      message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=filesystem,iostreams,math,date_time,regex,system,thread) ... failed")
      message(FATAL_ERROR ${BOOST_BOOTSTRAPPING_OUT})
    else()
      message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=filesystem,iostreams,math,date_time,regex,system,thread) ... done")
    endif()


    set (BOOST_DEBUG_FLAGS "")
    if (BOOST_DEBUG)
      set(BOOST_DEBUG_FLAGS "--debug-configuration -d+2")
    endif()

    # boost cmd (use b2 since sometimes the copying/symlinking from b2 to bjam fails)
    set (BOOST_CMD "./b2 ${BOOST_DEBUG_FLAGS} ${BOOST_ARCHITECTURE} toolset=${_boost_toolchain} -j ${_BOOST_PARALLEL_JOBS} --disable-icu link=${BOOST_BUILD_TYPE} cxxflags=-fPIC ${BOOST_EXTRA_CXXFLAGS} ${OSX_LIB_FLAG} ${OSX_DEPLOYMENT_FLAG} ${BOOST_LINKER_FLAGS} install --build-type=complete --layout=tagged --threading=single,multi")

    # boost install
    message(STATUS "Installing Boost libraries (${BOOST_CMD}) ...")
    execute_process(COMMAND ./b2 ${BOOST_DEBUG_FLAGS} ${BOOST_ARCHITECTURE} toolset=${_boost_toolchain}
                    -j ${_BOOST_PARALLEL_JOBS}
                    --disable-icu
                    -s NO_LZMA=1
                    -s NO_ZSTD=1
                    link=${BOOST_BUILD_TYPE} "cxxflags=-fPIC ${BOOST_EXTRA_CXXFLAGS} ${OSX_LIB_FLAG} ${OSX_DEPLOYMENT_FLAG}" ${BOOST_LINKER_FLAGS}  install 
                    --build-type=complete
                    --layout=tagged
                    --threading=single,multi
                    WORKING_DIRECTORY ${BOOST_DIR}
                    OUTPUT_VARIABLE BOOST_INSTALL_OUT
                    ERROR_VARIABLE BOOST_INSTALL_OUT
                    RESULT_VARIABLE BOOST_INSTALL_SUCCESS)

    # logfile 
    file(APPEND ${LOGFILE} ${BOOST_INSTALL_OUT})
    if (NOT BOOST_INSTALL_SUCCESS EQUAL 0)
      message(STATUS "Installing Boost libraries (${BOOST_CMD}) ... failed")
      message(FATAL_ERROR ${BOOST_INSTALL_OUT})
    else()
      message(STATUS "Installing Boost libraries (${BOOST_CMD}) ... done")
    endif()
  endif()

ENDMACRO(OPENMS_CONTRIB_BUILD_BOOST)
