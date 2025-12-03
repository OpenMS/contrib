##################################################
###       COIN-OR															 ###
##################################################
## COIN-OR from http://www.coin-or.org/download/source/CoinMP/CoinMP-1.3.3.tgz
## repacked installed files and created VisualStudio 2008 files

MACRO( OPENMS_CONTRIB_BUILD_COINOR)
  OPENMS_LOGHEADER_LIBRARY("COINOR")
  ## extract: (takes very long.. so skip if possible)
  if(MSVC)
    set(ZIP_ARGS "x -y -osrc")
  else()
    set(ZIP_ARGS "xzf")
  endif()
  OPENMS_SMARTEXTRACT(ZIP_ARGS ARCHIVE_COINOR "COINOR" "AUTHORS")

  set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Idiot.cpp.diff")
  set(PATCHED_FILE "${COINOR_DIR}/Clp/src/Idiot.cpp")
  OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)
  
  if (MSVC)
		## changes made to COIN-MP solution files (for all 6 libs):
		## - in Properties -> Librarian -> OutputFile: output lib in debug mode X64 (!!!) from $(OutDir)\$(ProjectName).lib to $(OutDir)\$(ProjectName)d.lib
    ##    or in VS2017: $(OutDir)$(TargetName)$(TargetExt) to $(OutDir)$(TargetName)d$(TargetExt)
		## - changed used runtime library to dynamic version (Release & Debug mode)
		## - deleted contents of CoinMP-1.3.3\CoinMP\MSVisualStudio\v8\release (there were precompiled dll's and lib's)
		## - in all vcxproj files: replace
		##   '<WindowsTargetPlatformVersion> ...some version ... </WindowsTargetPlatformVersion>' with '<WindowsTargetPlatformVersion>$(WindowsSDKVersion)</WindowsTargetPlatformVersion>
		## which will use the environment variable %WindowsSDKVersion%
		## Omitting this step will fix the Sln to a certain SDK and force other users to install this very SDK or retarget their solution manually
		## This problem has (hopefully) been fixed in VS2019...

	
	if (NOT DEFINED ENV{WindowsSDKVersion} AND ${CONTRIB_VS_VERSION} EQUAL 15)
	  ## make sure the SDK version is set, because it's used inside the vcxproj files (see above)
	  MESSAGE(MESSAGE "Contrib-Error: Could not determine WindowsSDK version installed. Please make sure the environment variable %WindowsSDKVersion% is set to the version of your installed SDK. The Visual Studio installer should have taken care of that. We are falling back to SDK '10.0.17763.0', but this is likely not correct (you will see an error message right after if this did not work.")
	  set(ENV{WindowsSDKVersion} "10.0.17763.0") # fallback, just to have a value. If this is incorrect, at least VS will tell you what to use
	endif()
	
    set(MSBUILD_ARGS_SLN "${COINOR_DIR}/CoinMP/MSVisualStudio/v${CONTRIB_VS_VERSION}/CoinMP.sln")
    set(MSBUILD_ARGS_TARGET "libCbc")
    OPENMS_BUILDLIB("CoinOR-Cbc (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-Cbc (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)

    set(MSBUILD_ARGS_TARGET "libCgl")
    OPENMS_BUILDLIB("CoinOR-Cgl (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-Cgl (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)

    set(MSBUILD_ARGS_TARGET "libClp")
    OPENMS_BUILDLIB("CoinOR-Clp (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-Clp (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)

    set(MSBUILD_ARGS_TARGET "libCoinUtils")
    OPENMS_BUILDLIB("CoinOR-CoinUtils (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-CoinUtils (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)

    set(MSBUILD_ARGS_TARGET "libOsi")
    OPENMS_BUILDLIB("CoinOR-Osi (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-Osi (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)

    set(MSBUILD_ARGS_TARGET "libOsiClp")
    OPENMS_BUILDLIB("CoinOR-OsiClp (Debug)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Debug" COINOR_DIR)
    OPENMS_BUILDLIB("CoinOR-OsiClp (Release)" MSBUILD_ARGS_SLN MSBUILD_ARGS_TARGET "Release" COINOR_DIR)
    
    ###################
    ## copy includes ##
    ###################
		Message(STATUS "Copying include files to ./include/coin ... ")
		file(GLOB_RECURSE INC_FILES "${COINOR_DIR}/*.h" "${COINOR_DIR}/*.hpp")
		
		## create the target directory (coin)
		execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "${PROJECT_BINARY_DIR}/include/coin/"
											OUTPUT_VARIABLE MAKE_DIR_OUT
											RESULT_VARIABLE MAKE_DIR_SUCCESS)
		if( NOT MAKE_DIR_SUCCESS EQUAL 0)
			message( STATUS "creating ./include/coin .. failed")
			message( FATAL_ERROR ${MAKE_DIR_OUT})
		endif()
		
		## copying
		foreach (FFF ${INC_FILES})
			execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${FFF}" "${PROJECT_BINARY_DIR}/include/coin/"
											OUTPUT_VARIABLE COPY_INC_OUT
											RESULT_VARIABLE COPY_INC_SUCCESS)
			if( NOT COPY_INC_SUCCESS EQUAL 0)
				message( STATUS "Copying ${FFF} to ./include/coin .. failed")
				message( FATAL_ERROR ${COPY_INC_OUT})
			endif()
		endforeach()		

	else()  ## LINUX & Mac
    #set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/CbcEventHandler.hpp.diff")
    #set(PATCHED_FILE "${COINOR_DIR}/Cbc/src/CbcEventHandler.hpp")
    #OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    #set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/CoinTypes.hpp.diff")
    #set(PATCHED_FILE "${COINOR_DIR}/CoinUtils/src/CoinTypes.hpp")
    #OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    # set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Makefile.in.diff")
    # set(PATCHED_FILE "${COINOR_DIR}/Makefile.in")
    # OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    # set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/MakefileCoinMP.in.diff")
    # set(PATCHED_FILE "${COINOR_DIR}/CoinMP/Makefile.in")
    # OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)  

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/CoinUtils.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/CoinUtils/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Clp.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/Clp/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Cgl.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/Cgl/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/CoinMP.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/CoinMP/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Cbc.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/Cbc/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)

    set(PATCH_FILE "${PROJECT_SOURCE_DIR}/patches/coinor/Osi.configure.diff")
    set(PATCHED_FILE "${COINOR_DIR}/Osi/configure")
    OPENMS_PATCH( PATCH_FILE COINOR_DIR PATCHED_FILE)
  
    # configure -- 
    if( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )
      set(COINOR_CXXFLAGS "${OSX_LIB_FLAG} ${OSX_DEPLOYMENT_FLAG} ${OSX_SYSROOT_FLAG} -fPIC -std=c++14")
      set(COINOR_CFLAGS "${OSX_DEPLOYMENT_FLAG} ${OSX_SYSROOT_FLAG}")
      set(COINOR_FFLAGS "${OSX_DEPLOYMENT_FLAG}")
      set(COINOR_EXTRA_ARGS "--disable-dependency-tracking")
    else()
      set(COINOR_CXXFLAGS "-fPIC -std=c++14")
      set(COINOR_CFLAGS "")
      set(COINOR_FFLAGS "")
      set(COINOR_EXTRA_ARGS "")
    endif()

    # Determine build triplet for configure (only needed for Linux with old config.guess)
    if(CMAKE_SYSTEM_NAME MATCHES "Linux")
      if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64")
        set(BUILD_TRIPLET "--build=arm-linux-gnu")
      elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
        set(BUILD_TRIPLET "--build=x86_64-linux-gnu")
      else()
        set(BUILD_TRIPLET "")
      endif()
    else()
      # macOS can auto-detect, no need to specify build triplet
      set(BUILD_TRIPLET "")
    endif()

    # check if we prefer shared or static libs
    if (BUILD_SHARED_LIBRARIES)
      set(STATIC_BUILD "--enable-static=no")
      set(SHARED_BUILD "--enable-shared=yes")
    else()
      set(STATIC_BUILD "--enable-static=yes")
      set(SHARED_BUILD "--enable-shared=no")		
    endif()
    
    message( STATUS "Configure COIN-OR library (./configure -C --prefix=${PROJECT_BINARY_DIR} ${BUILD_TRIPLET} ${STATIC_BUILD} ${SHARED_BUILD} --with-lapack=no --with-blas=no ${COINOR_EXTRA_ARGS} CXX=${CMAKE_CXX_COMPILER} CC=${CMAKE_C_COMPILER} CXXFLAGS=${COINOR_CXXFLAGS})")

    # Set environment variables for configure
    set(ENV{CXXFLAGS} "${COINOR_CXXFLAGS}")
    set(ENV{CFLAGS} "${COINOR_CFLAGS}")
    set(ENV{FFLAGS} "${COINOR_FFLAGS}")

    execute_process(
      COMMAND 
        ./configure 
        -C 
        --prefix=${PROJECT_BINARY_DIR}
        ${STATIC_BUILD}
        ${SHARED_BUILD}
        ${BUILD_TRIPLET}
        --with-lapack=no
        --with-blas=no
        ${COINOR_EXTRA_ARGS}
        CXX=${CMAKE_CXX_COMPILER}
        CC=${CMAKE_C_COMPILER}
      WORKING_DIRECTORY ${COINOR_DIR}
      OUTPUT_VARIABLE COINOR_CONFIGURE_OUT
      ERROR_VARIABLE COINOR_CONFIGURE_ERR
      RESULT_VARIABLE COINOR_CONFIGURE_SUCCESS
    )
    ## logfile
    file(APPEND ${LOGFILE} ${COINOR_CONFIGURE_OUT})

    if( NOT COINOR_CONFIGURE_SUCCESS EQUAL 0)
      message( STATUS "Configure COIN-OR library .. failed")
      message( STATUS ${COINOR_CONFIGURE_ERR})
      message( FATAL_ERROR ${COINOR_CONFIGURE_OUT})
    else()
      message( STATUS "Configure COIN-OR library .. done")
    endif()

    ## make install
    message( STATUS "Building and installing COIN-OR library (make install).. ")
    execute_process(
      COMMAND 
      ${CMAKE_MAKE_PROGRAM}
      install
      WORKING_DIRECTORY ${COINOR_DIR} 
        # Explicitly pass as one argument
      OUTPUT_VARIABLE COINOR_MAKE_OUT
      RESULT_VARIABLE COINOR_MAKE_SUCCESS
    )
    ## logfile
    file(APPEND ${LOGFILE} ${COINOR_MAKE_OUT})

    if( NOT COINOR_MAKE_SUCCESS EQUAL 0)
      message( STATUS "Building and installing COIN-OR library (make install) .. failed")
      message( FATAL_ERROR ${COINOR_MAKE_OUT})
    else()
      message( STATUS "Building and installing COIN-OR library (make install) .. done")
    endif()
  endif()

ENDMACRO( OPENMS_CONTRIB_BUILD_COINOR )
