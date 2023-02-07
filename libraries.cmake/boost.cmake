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
    set(ZIP_ARGS "x -y -osrc")
  else()
    set(ZIP_ARGS "xzf")
  endif()
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_BOOST "BOOST" "index.htm")
  
  if(MSVC) ## build boost library for windows
    
    ## omitting the version (i.e. 'toolset=msvc'), causes Boost to use the latest(!) VS it can find the system -- irrespective of the current env (and its cl.exe)
    set(TOOLSET "toolset=msvc-${CONTRIB_MSVC_TOOLSET_VERSION}") 
    
    if (NOT QUICKBUILD)
      ## not a Visual Studio project .. just build by hand
      message(STATUS "Bootstrapping Boost libraries (bootstrap.bat) ...")
      execute_process(COMMAND bootstrap.bat
                      WORKING_DIRECTORY ${BOOST_DIR}
                      OUTPUT_VARIABLE BOOST_BOOTSTRAP_OUT
                      ERROR_VARIABLE BOOST_BOOTSTRAP_OUT   # use same variable for stderr as stdout to merge streams
                      RESULT_VARIABLE BOOST_BOOTSTRAP_SUCCESS)
      
      file(APPEND  ${LOGFILE} ${BOOST_BOOTSTRAP_OUT})
      
      ## check for failed bootstrapping. Even if failing the return code can be 0 (indicating success), so we additionally check the output 
      if ((NOT BOOST_BOOTSTRAP_SUCCESS EQUAL 0) OR (BOOST_BOOTSTRAP_OUT MATCHES "[fF]ailed"))
        message(STATUS "Bootstrapping Boost libraries (bootstrap.bat) ... failed\nOutput was:\n ${BOOST_BOOTSTRAP_OUT}\nEnd of output.\n")
        message(STATUS "Renaming bootstrap.log to bootstrap_firstTry.log")
        file(RENAME ${BOOST_DIR}/bootstrap.log ${BOOST_DIR}/bootstrap_firstTry.log)
        ### on some command lines bootstrapping fail (e.g. the toolset is too new) or will give:
        # "Building Boost.Build engine. The input line is too long."
        ## ,thus we provide a backup bjam.exe(32bit), which hopefully works on all target systems.
        ## However this bjam results in a version mismatch and a warning (that you can ignore).
        message(STATUS " ... trying fallback with backup bjam.exe ...")
        configure_file("${PROJECT_SOURCE_DIR}/patches/boost/bjam.exe" "${BOOST_DIR}/bjam.exe" COPYONLY)
      else()
        message(STATUS "Bootstrapping Boost libraries (bootstrap.bat) ... done")
      endif()

      set(BOOST_CMD_ARGS "${BOOST_ARG}" 
                         "install" 
                         "-j${NUMBER_OF_JOBS}" 
                         "--prefix=${PROJECT_BINARY_DIR}" 
                         "--layout=tagged"                   # create libnames without vcXXX in filename; include dir is /include/boost (as opposed to "versioned" where /include/boost-1.52/boost plus ...vc110.lib
                         "--with-math" 
                         "--with-date_time" 
                         "--with-iostreams" 
                         "--with-regex"
                         "--with-system"
                         "--with-thread"
                         "--build-type=complete"
                         "--disable-icu"
                         "-s"
                         "NO_LZMA=1" 
                         "-s" 
                         "NO_ZSTD=1"
                         "runtime-link=shared"
                         "link=${BOOST_BUILD_TYPE}" 
                         "${TOOLSET}")

     ## WARNING: boost call is not "space in path" save yet (the easy way of using \" does not work out of the box
     message(STATUS "Building Boost library (bjam ${BOOST_CMD_ARGS}) .. ")
     execute_process(COMMAND b2.exe ${BOOST_CMD_ARGS}
                     WORKING_DIRECTORY ${BOOST_DIR}
                     OUTPUT_VARIABLE BUILD_BOOST_OUT
                     ERROR_VARIABLE BUILD_BOOST_ERR
                     RESULT_VARIABLE BUILD_BOOST)
      
     # output to logfile
     file(APPEND ${LOGFILE} ${BUILD_BOOST_OUT})

     if (NOT BUILD_BOOST EQUAL 0)
       message(STATUS "Building Boost library (bjam ${BOOST_CMD_ARGS}) .. failed")
       message(STATUS "BUILD_BOOST_OUT = ${BUILD_BOOST_OUT}")
       message(STATUS "BUILD_BOOST_ERR = ${BUILD_BOOST_ERR}")
       message(STATUS "BUILD_BOOST = ${BUILD_BOOST}")
       message(FATAL_ERROR ${BUILD_BOOST_OUT})
     else()
       message(STATUS "Building Boost library (bjam ${BOOST_CMD_ARGS}) .. done")
     endif()
    
   endif() ## end quickbuild
 
  else() ## LINUX/MAC

    # we need to know the compiler version for proper formating boost user-config.jam
    determine_compiler_version()

    # use proper toolchain (random guesses. There is not proper documentation)
    if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
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
    message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-toolset=${_boost_bootstrap_toolchain} --with-libraries=date_time,iostreams,math,regex,system,thread) ...")
    execute_process(COMMAND ./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=iostreams,math,date_time,regex,system,thread
                    WORKING_DIRECTORY ${BOOST_DIR}
                    OUTPUT_VARIABLE BOOST_BOOTSTRAP_OUT
                    ERROR_VARIABLE BOOST_BOOTSTRAP_OUT
                    RESULT_VARIABLE BOOST_BOOTSTRAP_SUCCESS)

    # logfile
    file(APPEND ${LOGFILE} ${BOOST_BOOTSTRAP_OUT})
    if (NOT BOOST_BOOTSTRAP_SUCCESS EQUAL 0)
      message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=iostreams,math,date_time,regex,system,thread) ... failed")
      message(FATAL_ERROR ${BOOST_BOOTSTRAPPING_OUT})
    else()
      message(STATUS "Bootstrapping Boost libraries (./bootstrap.sh --prefix=${PROJECT_BINARY_DIR} --with-libraries=iostreams,math,date_time,regex,system,thread) ... done")
    endif()


    set (BOOST_DEBUG_FLAGS "")
    if (BOOST_DEBUG)
      set(BOOST_DEBUG_FLAGS "--debug-configuration -d+2")
    endif()
    # boost cmd (use b2 since sometimes the copying/symlinking from b2 to bjam fails)
    set (BOOST_CMD "./b2 ${BOOST_DEBUG_FLAGS} architecture=x86 toolset=${_boost_toolchain} -j ${NUMBER_OF_JOBS} --disable-icu link=${BOOST_BUILD_TYPE} cxxflags=-fPIC ${OSX_LIB_FLAG} ${OSX_DEPLOYMENT_FLAG} ${BOOST_LINKER_FLAGS} install --build-type=complete --layout=tagged --threading=single,multi")
    
    # boost install
    message(STATUS "Installing Boost libraries (${BOOST_CMD}) ...")
    execute_process(COMMAND ./b2 ${BOOST_DEBUG_FLAGS} architecture=x86 toolset=${_boost_toolchain} 
                    -j ${NUMBER_OF_JOBS} 
                    --disable-icu
                    -s NO_LZMA=1
                    -s NO_ZSTD=1
                    link=${BOOST_BUILD_TYPE} "cxxflags=-fPIC ${OSX_LIB_FLAG} ${OSX_DEPLOYMENT_FLAG}" ${BOOST_LINKER_FLAGS}  install 
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
