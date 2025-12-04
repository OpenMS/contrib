# --------------------------------------------------------------------------
#                   OpenMS -- Open-Source Mass Spectrometry
# --------------------------------------------------------------------------
# Copyright The OpenMS Team -- Eberhard Karls University Tuebingen,
# ETH Zurich, and Freie Universitaet Berlin 2002-2016.
#
# This software is released under a three-clause BSD license:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of any author or any participating institution
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# For a full list of authors, refer to the file AUTHORS.
# --------------------------------------------------------------------------
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL ANY OF THE AUTHORS OR THE CONTRIBUTING
# INSTITUTIONS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# --------------------------------------------------------------------------
# $Maintainer: Stephan Aiche, Chris Bielow $
# $Authors: Stephan Aiche, Chris Bielow $
# --------------------------------------------------------------------------

## contrib installation file for OpenMS

## *** IMPORTANT ***
## when updating the contrib with new packages:
## GENERAL:
## - make sure to adopt the following variables for each library <LIBNAME>, currently we have
##    * <LIBNAME>_DIR
##    * ARCHIVE_<LIBNAME>
##    * ARCHIVE_<LIBNAME>_TAR
##    * INCLUDE_DIR_<LIBNAME> (or INCLUDE_FILES_<LIBNAME> in the case that there are just files copied to include/ [LIBSVM])
##
## WINDOWS ONLY: [the information below applies only to WINDOWS, but when you update the contrib you MUST do both Linux, Mac OS X and Windows - so read carefully!]
## - usually each package contains a build-system for Windows (solution [*.sln] files or NMake files [Makefile.win] ) and Linux(Makefiles) already provided by
##   the original developer. In some cases you need to rely on third party packages which provides solution files.
##   HOWEVER, for Windows they are usually not complete (e.g. missing 64bit targets, or even whole solution files
##   for a certain Visual Studio version (we support 8 and above).
##   Case a: 64bit targets are missing in Solution file
##    Solution: open the VS solution and add x64 solution platform using the Configuration Manager
##                (you can build the x64 target by adding "|64" to the Build option of devenv.exe - see examples below)
##   Case b: Solution files for a certain Visual Studio Version (usually 9) are missing.
##      Solution: copy the VS8 solution (including vcproj files) - usually this is a separate folder
##          using the VS9 IDE, open the copied VS8 solution (a converter tool should automatically open) and follow the steps.
##          (optionally rename the converted solution e.g. from xerces_vs8.sln to xerces_vs9.sln)
## Remember: in the end, you need three solution files (VS8 & VS9 & VS10), each supporting 32 and 64 bit platforms.
##
## Making sure linking is consistent:
##    - when combining external libs with our own, Microsoft's linker can only handle one type of reference to the C(++) standard libs, which is either
##      dynamic (/MD(d)) or static (/MT(d)), but not both (you will get multiply defined symbols and tons of linker errors).
##      Note that this does not mean you cannot mix static and dynamic external libraries (you can), it rather means you cannot mix static and dynamic CRT's.
##      Thus, make sure to check every new solution file you add is linking to the *dynamic* CRT with /MD(d).
##
##
## Alternatively, some projects use NMake-files (libsvm does). There it is easier, because you only need one Makefile.win file for all four cases.
## Be aware though that including object files (*.obj) in Visual Studio is not supported by OpenMS/CMake, you thus will need to create a lib
## (see libsvm Makefile.win for an example)
##
##
## Where do I get Windows-packages with at least partially complete solution files?
## Boost:  NA, Boost uses its in-house Boost-Jam which supports everything we need
## LibSVM: comes with a Makefile.win, but libsvm needed some serious tweaking to support debug mode and to build a lib (instead of object files only)
## XERCES-C: they offer a VS version on their website (http://xerces.apache.org/xerces-c/), usually not for bleeding edge release though - bad luck for us.
## GLPK:   download from http://ftp.gnu.org/gnu/glpk/glpk-4.46.tar.gz
## COIN-OR: we use the CoinMP package available from
##         http://www.coin-or.org/download/source/CoinMP/CoinMP-1.3.3.tgz


## some words:
## Patching: We do not (by intention) use a ".is_patched" file, but let patch(.exe) handle create a .orig file, which is in the same location as the patched file

## required software:
## Windows: 7-Zip & GNUWin32-patch
## Linux & MinGW: Tar & patch
## (these are searched for and an appropriate error message is given when not found)


## NOTE: remove "exec_program" calls and substitute with exec_process (see http://www.cmake.org/cmake/help/cmake2.6docs.html#command:execute_process)
##       - however: exec_process seems to handle our arguments incorrectly (at least on Windows). Check functionality before you commit!

# Determine what to build (all or single library)
set( BUILD_TYPE LIST CACHE STRING "Can be used to restrict building to a single library: ALL,LIBSVM,XERCESC,BOOST,COINOR,BZIP2,ZLIB,GLPK,KISSFFT,OPENMP,ARROW")
set( VALID_BUILD_TYPES "ALL" "LIBSVM" "XERCESC" "BOOST" "COINOR" "BZIP2" "ZLIB" "GLPK" "EIGEN" "KISSFFT" "HDF5" "OPENMP" "ARROW")

# check build type
if (BUILD_TYPE STREQUAL "HELP" OR BUILD_TYPE STREQUAL "LIST")
  message(STATUS "===========================================================================")
  message(STATUS " OpenMS contrib (dependency packages) installation.")
  message(STATUS " This program will allow you to compile and install all of the OpenMS")
  message(STATUS " dependencies. Select the packages you wish to install using the the command")
  message(STATUS " -DBUILD_TYPE=$SEMICOLON_SEP_LIST or install all of them with -DBUILD_TYPE=ALL.")
  message(STATUS "===========================================================================")
  message(STATUS "Valid BUILD_TYPEs are:")
  foreach( BT ${VALID_BUILD_TYPES} )
    message(STATUS " * ${BT}")
  endforeach( BT VALID_BUILD_TYPES )
  return(0)
endif()

# This is a hack since CMake translates the compiler given via environment variables to its full path.
# On MacOS though, we want the wrapper executable in /usr/bin/clang++ since it automatically
# finds and links the right system headers/libraries and we implicitly pass this command to e.g. boost
# since CMake resets the CXX env var to its resolved path and boosts bootstrap uses that.
# Therefore we skip the resolution of the full path here by explicitly defining it. Only downside:
# If you use xcodeselect and change the clang underneath, CMake wont notice/reconfigure.
if (NOT DEFINED CMAKE_CXX_COMPILER)
  if (DEFINED ENV{CXX})
    set(CMAKE_CXX_COMPILER $ENV{CXX})
  endif()
endif()
if (NOT DEFINED CMAKE_C_COMPILER)
  if (DEFINED ENV{CC})
    set(CMAKE_C_COMPILER $ENV{CC})
  endif()
endif()

# Heart of the BUILD system : only edit when you know what you are doing (we don't)
# quick manual for most commands: https://cmake.org/cmake/help/v3.3/manual/cmake-commands.7.html
# useful predefined variables: http://www.paraview.org/Wiki/CMake_Useful_Variables

# force cmake > 3.10 to force enable c++20 support
cmake_minimum_required(VERSION 3.10.0 FATAL_ERROR)

PROJECT("OpenMS_CONTRIB")

SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS true)

# Set C++ version (does only work if we had a target-based CMake script)
SET(CMAKE_CXX_STANDARD 20)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
# Until then, check again manually. MSVC is checked separately later
# Update compiler version requirements for C++20 support
if (UNIX)
  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10.0.0")
      message(FATAL_ERROR "clang++: OpenMS-contrib requires version 10.0.0 or later to build but found ${CMAKE_CXX_COMPILER_VERSION}")
    endif()  
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "12.0.0")
      message(FATAL_ERROR "appleclang: OpenMS-contrib requires version 12.0.0 or later to build but found ${CMAKE_CXX_COMPILER_VERSION}")
    endif()  
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "10.0.0")
      message(FATAL_ERROR "g++: OpenMS-contrib requires version 10.0.0 or later to build but found ${CMAKE_CXX_COMPILER_VERSION}")
    endif()  
  endif()
endif()

## sanity checks:

## no MSYS/MINGW
if (MINGW OR MSYS) ## only happens on Windows
  message(FATAL_ERROR "MSYS and/or MinGW are not supported! Please use a Visual Studio environment! See Windows build instructions for further information!")
endif()

## do not allow source or binary directories with spaces
## The contrib can basically handle those (make sure to wrap calls in quotes where appropriate) but e.g. BOOST under windows cannot

string(REPLACE " " "" PROJECT_BINARY_DIR_NOSPACES ${PROJECT_BINARY_DIR})
if (NOT ${PROJECT_BINARY_DIR} STREQUAL ${PROJECT_BINARY_DIR_NOSPACES})
  message(FATAL_ERROR "The current contrib binary directory contains spaces, which are not allowed. Build the contrib in another directory!")
endif()
string(REPLACE " " "" PROJECT_SOURCE_DIR_NOSPACES ${PROJECT_SOURCE_DIR})
if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_SOURCE_DIR_NOSPACES})
  message(FATAL_ERROR "The current contrib binary directory contains spaces, which are not allowed. Build the contrib in another directory!")
endif()

## target directories
set (CONTRIB_BIN_SOURCE_DIR "${PROJECT_BINARY_DIR}/src" CACHE STRING "Directory inside the binary tree where the (extracted) contrib sources are located")
set (CONTRIB_BIN_INCLUDE_DIR "${PROJECT_BINARY_DIR}/include" CACHE STRING "Directory inside the binary tree where the contrib includes are located")
set (CONTRIB_BIN_LIB_DIR "${PROJECT_BINARY_DIR}/lib" CACHE STRING "Directory inside the binary tree where the contrib libs are located")
set (PATCH_DIR "${PROJECT_SOURCE_DIR}/patches/" CACHE STRING "Directory containing all the patch files")

# project specific source directories
## Warning: ensure these are all upper-case names!
set(BZIP2_DIR ${CONTRIB_BIN_SOURCE_DIR}/bzip2-1.0.5)
set(ZLIB_DIR ${CONTRIB_BIN_SOURCE_DIR}/zlib-1.3.1)
set(BOOST_DIR ${CONTRIB_BIN_SOURCE_DIR}/boost-1.81.0)
set(XERCES_DIR ${CONTRIB_BIN_SOURCE_DIR}/Xerces-C_3_2_0)
set(LIBSVM_DIR ${CONTRIB_BIN_SOURCE_DIR}/libsvm-3.12)
set(GLPK_DIR ${CONTRIB_BIN_SOURCE_DIR}/glpk-4.46)
set(COINOR_DIR ${CONTRIB_BIN_SOURCE_DIR}/CoinMP-1.8.3)
set(EIGEN_DIR ${CONTRIB_BIN_SOURCE_DIR}/eigen-3.4.0)
set(KISSFFT_DIR ${CONTRIB_BIN_SOURCE_DIR}/kissfft)
set(HDF5_DIR ${CONTRIB_BIN_SOURCE_DIR}/hdfsrc)
set(OPENMP_DIR ${CONTRIB_BIN_SOURCE_DIR}/openmp-12.0.1.src)
set(ARROW_DIR ${CONTRIB_BIN_SOURCE_DIR}/arrow-apache-arrow-22.0.0/cpp)

## source(archive) paths
## PLEASE upload all source archives to
##     https://github.com/OpenMS/contrib-sources/
##  and provide the necessary information below
##  ARCHIVE_<LIBNAME> the name of the archive as it was uploaded
##  ARCHIVE_<LIBNAME>_TAR the name of the tar in the tar.gz
##  ARCHIVE_<LIBNAME>_SHA256 the sha256 of the file uploaded
## e.g.
##  set(ARCHIVE_ZLIB zlib.tar.gz)
##  set(ARCHIVE_ZLIB_TAR zlib.tar)
##  set(ARCHIVE_ZLIB_SHA256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
## NOTE: for local development you can simply place the *.tar.gz in the binary
##       directory to prevent the download and sha256 verification
## LIBRARIES: BZIP2, ZLIB, BOOST, XERCES, LIBSVM, GLPK, COINOR, EIGEN, KISSFFT, HDF5, OPENMP, ARROW

set(ARCHIVE_BZIP2 bzip2-1.0.5.tar.gz)
set(ARCHIVE_BZIP2_TAR bzip2-1.0.5.tar)
set(ARCHIVE_BZIP2_SHA256 "f7bf5368309d76e5daf3a89d4d1bea688dac7780742e7a0ae1af19be9316fe22")

set(ARCHIVE_ZLIB zlib-1.3.1.tar.gz)
set(ARCHIVE_ZLIB_TAR  zlib-1.3.1.tar)
set(ARCHIVE_ZLIB_SHA256 "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")

set(ARCHIVE_BOOST boost-1.81.0.tar.gz)
set(ARCHIVE_BOOST_TAR  boost-1.81.0.tar)
set(ARCHIVE_BOOST_SHA256 "121da556b718fd7bd700b5f2e734f8004f1cfa78b7d30145471c526ba75a151c")

set(ARCHIVE_XERCES Xerces-C_3_2_0.tar.gz)
set(ARCHIVE_XERCES_TAR  Xerces-C_3_2_0.tar)
set(ARCHIVE_XERCES_SHA256 "68cca38aa0db168fa8ccce1f470a89d91104c4586e2635e0cd6602baf55e4eb8")

set(ARCHIVE_LIBSVM libsvm-3.12.tar.gz)
set(ARCHIVE_LIBSVM_TAR  libsvm-3.12.tar)
set(ARCHIVE_LIBSVM_SHA256 "9dcd7a301665d2cbd8c109bba0e8cc2d47b5cc2a9c46aeb359f2dab67be69f74")

set(ARCHIVE_GLPK glpk-4.46.tar.gz)
set(ARCHIVE_GLPK_TAR  glpk-4.46.tar)
set(ARCHIVE_GLPK_SHA256 "fbbe438262f06813850837afd0cd55ed66f17f2004e2ce4f0078754f089e3242")

set(ARCHIVE_COINOR CoinMP-1.8.3-vs22.tar.gz)
set(ARCHIVE_COINOR_TAR  CoinMP-1.8.3-vs22.tar)
set(ARCHIVE_COINOR_SHA256 "75eefc0b0e06dc11a1e5004222f69766366c1e08d3b739f25f53c756ae28a309")

set(ARCHIVE_EIGEN eigen-3.4.0.tar.gz)
set(ARCHIVE_EIGEN_TAR  eigen-3.4.0.tar)
set(ARCHIVE_EIGEN_SHA256 "8586084f71f9bde545ee7fa6d00288b264a2b7ac3607b974e54d13e7162c1c72")

set(ARCHIVE_KISSFFT kissfft-130.tar.gz)
set(ARCHIVE_KISSFFT_TAR kissfft-130.tar)
set(ARCHIVE_KISSFFT_SHA256 "d846005b3a4b45202f3b288b2d6b5b1df544526ae6aaffe8707770bd09093064")

set(ARCHIVE_HDF5 hdf5-1_14_3.tar.gz)
set(ARCHIVE_HDF5_TAR hdf5-1_14_3.tar)
set(ARCHIVE_HDF5_SHA256 "126b800e9b87f65e7e7ffa58ee006607bab03a8e11e5209ea3d5c0c331321d43")

set(ARCHIVE_OPENMP openmp-12.0.1.src.tar.xz)
set(ARCHIVE_OPENMP_TAR openmp-12.0.1.src.tar)
set(ARCHIVE_OPENMP_SHA256 "60fe79440eaa9ebf583a6ea7f81501310388c02754dbe7dc210776014d06b091")

set(ARCHIVE_ARROW arrow-apache-arrow-22.0.0.tar.gz )
set(ARCHIVE_ARROW_TAR arrow-apache-arrow-22.0.0.tar )
set(ARCHIVE_ARROW_SHA256 "8a95e6c7b9bec2bc0058feb73efe38ad6cfd49a0c7094db29b37ecaa8ab16051")

## necessary for clean up .. change if install process of library changes
set(INCLUDE_DIR_BOOST ${CONTRIB_BIN_INCLUDE_DIR}/boost)
set(INCLUDE_DIR_XERCES ${CONTRIB_BIN_INCLUDE_DIR}/xercesc)
set(INCLUDE_DIR_GLPK ${CONTRIB_BIN_INCLUDE_DIR}/GLPK)
set(INCLUDE_DIR_COINOR ${CONTRIB_BIN_INCLUDE_DIR}/coin)
set(INCLUDE_DIR_EIGEN ${CONTRIB_BIN_INCLUDE_DIR}/eigen3)
set(INCLUDE_DIR_KISSFFT ${CONTRIB_BIN_INCLUDE_DIR}/kissfft)
set(INCLUDE_DIR_OPENMP ${CONTRIB_BIN_INCLUDE_DIR}/openmp.src)
set(INCLUDE_DIR_ARROW ${CONTRIB_BIN_INCLUDE_DIR}/arrow)

## hack for simple libs that do not have include directories
set(INCLUDE_FILES_LIBSVM ${CONTRIB_BIN_INCLUDE_DIR}/svm.h)
set(INCLUDE_FILES_BZIP2 ${CONTRIB_BIN_INCLUDE_DIR}/bzlib.h ${CONTRIB_BIN_INCLUDE_DIR}/bzlib_private.h)
set(INCLUDE_FILES_ZLIB ${CONTRIB_BIN_INCLUDE_DIR}/zlib.h)

## address model of contrib
if (CMAKE_SIZEOF_VOID_P MATCHES "8")
  set(CONTRIB_ADDRESSMODEL 64 CACHE INTERNAL "Architecture-bits")
else()
  set(CONTRIB_ADDRESSMODEL 32 CACHE INTERNAL "Architecture-bits")
endif()
message(STATUS "ADDRESSMODEL is: ${CONTRIB_ADDRESSMODEL}-bit")
if (NOT CONTRIB_ADDRESSMODEL MATCHES "32|64")
  Message(FATAL_ERROR "CONTRIB_ADDRESSMODEL is neither 32 nor 64! Please correct this!")
endif()

# logfile
set(LOGFILE "${PROJECT_BINARY_DIR}/contrib_build.log")

if (MSVC)
  
  ## check that the console environment has a cl.exe architecture which is identical to the VS Generator
  ## If cl.exe builds 32-bit libs and VS Generator is Win64, we'd end up with mixed 32bit/64bit libraries, depending on how each lib is build (Cmake, bjam, nmake)
  execute_process(COMMAND "cl.exe" OUTPUT_VARIABLE cl_out ERROR_VARIABLE cl_out)
  ##message(STATUS "Cl.exe said: ${cl_out}")
  if (cl_out MATCHES ".*x64.*")
    message(STATUS "Cl.exe produces: 64-bit")
    set(CL_ADDRESSMODEL 64)
  elseif (cl_out MATCHES ".*x86.*")
    message(STATUS "Cl.exe produces: 32-bit")
    set(CL_ADDRESSMODEL 32)
  else()
    message(FATAL_ERROR "Could not determine if cl.exe builds x86 or x64 apps. Make sure cl.exe is available in your environment!")
  endif()
  if (NOT (CL_ADDRESSMODEL EQUAL CONTRIB_ADDRESSMODEL))
    message(FATAL_ERROR "cl.exe (${CL_ADDRESSMODEL}-bit) and Visual Studio Generator (${CONTRIB_ADDRESSMODEL}-bit) do not match. Please fix your PATH environment to find the proper cl.exe or use an appropriate generator by adding -A Win32/x64 to your CMake call.")
  endif()


  ## use the standard MSVC Toolset Version for each Visual Studio version
  ## TODO we can make use of the new CMake toolset (-T) option and associated variables
  if (CMAKE_GENERATOR MATCHES ".*Visual Studio 14.*") ## VS2015
    set(TMP_VS_VERSION "14")
    set(TMP_MSVC_TOOLSET_VERSION "14.0")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 15.*") ## VS2017
    set(TMP_VS_VERSION "15")
    set(TMP_MSVC_TOOLSET_VERSION "14.1")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 16.*") ## VS2019
    set(TMP_VS_VERSION "16")
    set(TMP_MSVC_TOOLSET_VERSION "14.2")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 17.*") ## VS2022
    set(TMP_VS_VERSION "17")
    set(TMP_MSVC_TOOLSET_VERSION "14.3")
  else()
    if (OVERRIDE_GENERATOR)
      message(FATAL_ERROR "Chosen to override the Generator check, proceed with caution.")
    else()
      message(FATAL_ERROR "Please use 'Visual Studio ??' (??={14, 15, 16, 17}) as Generator - identical to the MSVC toolchain you plan to use for OpenMS! Note that you must not use NMake or alike for the contrib (nor for OpenMS). There will be errors (mostly missing libraries). Under very special circumstances, you can override this with -DOVERRIDE_GENERATOR=On.")
    endif()
  endif()
  ## For coinor to find the correct names of the VS solutions
  set(CONTRIB_VS_VERSION ${TMP_VS_VERSION} CACHE INTERNAL "Microsoft Visual Studio Version used. Valid values: 14 and above")
  ## For boost to pass to the b2 build system so it doesnt just take the newest compiler available
  set(CONTRIB_MSVC_TOOLSET_VERSION ${TMP_MSVC_TOOLSET_VERSION} CACHE INTERNAL "Microsoft Visual C++ Toolset Version used (we currently use the default for the given Visual Studio version)")
  ## parameter validity check
  message(STATUS "Microsoft Visual C++ Toolset Version is: ${CONTRIB_MSVC_TOOLSET_VERSION}")

  ## some settings for Building the libs
  if (CONTRIB_ADDRESSMODEL MATCHES 32)
    set(BOOST_ARG "")
    set(WIN_PLATFORM_ARG "Win32")
    set(ARCHITECTURE_OPTION_CMAKE "-A" "Win32")
  else()
    # Only set address-model for x86_64, not for ARM64
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
      set(BOOST_ARG "address-model=64")
    else()
      set(BOOST_ARG "")
    endif()
    set(WIN_PLATFORM_ARG "x64")
    # Fix bug #95 (compile with MSVS 2015)
    if (NOT CMAKE_GENERATOR MATCHES ".*Win64.*")
      set(ARCHITECTURE_OPTION_CMAKE "-A" "x64")
    endif()
  endif()

  find_program(PROGRAM_ZIP "7z.exe" PATHS "C:/Program Files/7-Zip" "C:/Programme/7-Zip")
  if (NOT PROGRAM_ZIP)
    message(FATAL_ERROR "Cannot find '7z.exe' on your system. Please install 7-zip and add the directory to your PATH environment variable!")
  endif()

  ## see contrib/tools/README_patch.txt. We do not want any other patch.exe (since ours does not require elevation, i.e. admin rights)
  find_program(PROGRAM_PATCH "patch.exe" PATHS "${PROJECT_SOURCE_DIR}/tools" NO_DEFAULT_PATH)
  if (PROGRAM_PATCH)
    message(STATUS "Found patch.exe at '${PROGRAM_PATCH}'")
  else()	
    message(FATAL_ERROR "Cannot find 'patch.exe' in '${PROJECT_SOURCE_DIR}/tools' on your system. Please make sure its available!")
  endif()

  find_program(MSBUILD_EXECUTABLE MSBuild PATHS "C:/Program Files (x86)/MSBuild/${CONTRIB_MSVC_VERSION}.0/Bin/")
  if (MSBUILD_EXECUTABLE)
    message(STATUS "Finding MSBuild.exe (usually installed along with .NET or VS [since 12] ) ... success")
  else()
    message(STATUS "Finding MSBuild.exe (usually installed along with .NET or VS [since 12]) ... failed")
    message(STATUS "\n\nIf not shipped with your Visual Studio version (e.g. <12), please install Microsoft .NET (3.5 or above) and/or make sure MSBuild.exe is in your PATH!\n")
	message(STATUS "More recent versions of Visual Studio will install MSBuild in its own directory, e.g. 'C:\Program Files (x86)\MSBuild\${CONTRIB_MSVC_VERSION}.0\Bin\'. We looked there, but maybe it's slightly different...\n")
    message(FATAL_ERROR ${MSBUILD_EXECUTABLE})
  endif()
  
  ## just check if nmake is present -- if not later package calls will fail
  find_program(NMAKE_EXECUTABLE nmake.exe)
  if (NMAKE_EXECUTABLE)
    message(STATUS "Finding nmake.exe (as part of VS) ... success")
  else()
    message(STATUS "Finding nmake.exe (usually installed along with VS ... failed")
    message(STATUS "\n\nAre you sure you are using a VS developer(!) command line (which has more entries in %PATH%) and not just a normal command line?\n")
    message(FATAL_ERROR ${NMAKE_EXECUTABLE})
  endif()
  
else() ## linux/Mingw/macos

  # except Visual Studio, no other generator supports the architecture option
  set(ARCHITECTURE_OPTION_CMAKE )

  # tar
  find_program(PROGRAM_ZIP "tar")
  if (NOT PROGRAM_ZIP)
    message(FATAL_ERROR "Cannot find 'tar' on your system. Please install the tar program and add the directory to your PATH environment variable!")
  endif()

  # patch
  find_program(PROGRAM_PATCH "patch")
  if (NOT PROGRAM_PATCH)
    message(FATAL_ERROR "Cannot find 'patch' on your system. Please install patch and add the directory to your PATH environment variable!")
  endif()

  ## following progs are required for xerces-c, since we build from svn and not a release
  # autoconf
  find_program(PROGRAM_AUTOCONF "autoconf")
  if (NOT PROGRAM_AUTOCONF)
    message(FATAL_ERROR "Cannot find 'autoconf' on your system. Please install autoconf and add the directory to your PATH environment variable!")
  endif()

  # automake
  find_program(PROGRAM_AUTOMAKE "automake")
  if (NOT PROGRAM_AUTOMAKE)
    message(FATAL_ERROR "Cannot find 'automake' on your system. Please install automake and add the directory to your PATH environment variable!")
  endif()

  # libtoolize
  find_program(PROGRAM_LIBTOOLIZE NAMES "libtoolize" "glibtoolize")
  if (NOT PROGRAM_LIBTOOLIZE)
    message(FATAL_ERROR "Cannot find '(g)libtoolize' on your system. Please install libtoolize and add the directory to your PATH environment variable!")
  endif()

  # touch
  find_program(PROGRAM_TOUCH "touch")
  if (NOT PROGRAM_TOUCH)
    message(FATAL_ERROR "Cannot find 'touch' on your system. Please install touch and add the directory to your PATH environment variable!")
  endif()

endif()

## prepare
file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
file(MAKE_DIRECTORY "${CONTRIB_BIN_SOURCE_DIR}")
file(MAKE_DIRECTORY "${CONTRIB_BIN_INCLUDE_DIR}")

## initial log values
file(WRITE ${LOGFILE} "-- Starting to build contrib --\n\r")
file(APPEND ${LOGFILE} "CXX: ${CMAKE_CXX_COMPILER}\n\r")
file(APPEND ${LOGFILE} "CC: ${CMAKE_C_COMPILER}\n\r")

## macOS specifics.
if(APPLE)
  if( CMAKE_OSX_DEPLOYMENT_TARGET )
  message(STATUS "Deployment target for OSX was set to ${CMAKE_OSX_DEPLOYMENT_TARGET}. Adding the following flags whenever possible/needed:\n\r")
    set( OSX_DEPLOYMENT_TARGET_STRING "macosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    set( OSX_DEPLOYMENT_FLAG "-m${OSX_DEPLOYMENT_TARGET_STRING}")
    if( NOT (${CMAKE_SYSTEM_VERSION} LESS 13))
      ## Later than OSX 10.9 when they switched to libc++ as standard library
      set( OSX_LIB_FLAG "-stdlib=libc++")
    else()
      set( OSX_LIB_FLAG "-stdlib=libstdc++")
    endif()
    message(STATUS "${OSX_DEPLOYMENT_FLAG} ${OSX_LIB_FLAG}")
  endif()

  if( CMAKE_OSX_SYSROOT )
    message(STATUS "Sysroot for OSX was set to ${CMAKE_OSX_SYSROOT}. Adding the following flags whenever possible/needed:\n\r")
    set( OSX_SYSROOT_STRING "sysroot=${CMAKE_OSX_SYSROOT}")
    set( OSX_SYSROOT_FLAG "--${OSX_SYSROOT_STRING}")
    message(STATUS "${OSX_SYSROOT_FLAG}")
  endif()

  # force cmake > 3.10 to force enable c++20 support
cmake_minimum_required(VERSION 3.10.0 FATAL_ERROR)
endif()

## include extract/patch/build macros
include ("${CMAKE_SOURCE_DIR}/macros.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/libsvm.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/xercesc.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/boost.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/glpk.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/bzip2.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/zlib.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/coinor.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/eigen.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/kissfft.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/hdf5.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/openmp.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/arrow.cmake")

## build mac os x specific C/C++ flags
set( OPENMS_CONTRIB_MACOSX_MIXED_MODE 0 CACHE INTERNAL "building multiple architectures on MacOSX" FORCE)

cmake_policy(SET CMP0057 NEW)
foreach(BTG IN LISTS BUILD_TYPE)
  list(FIND VALID_BUILD_TYPES ${BTG} list_pos)
  if( ${list_pos} EQUAL -1 )
    message(STATUS "The BUILD_TYPE ${BUILD_TYPE} is invalid")
    message(STATUS "Valid BUILD_TYPEs are:")
    foreach( BT ${VALID_BUILD_TYPES} )
      message(STATUS " * ${BT}")
    endforeach( BT VALID_BUILD_TYPES )
    message(FATAL_ERROR "Aborting contrib build!")
  else( ${list_pos} EQUAL -1 )
    message(STATUS "BUILD_TYPE: ${BTG} (one of: ${VALID_BUILD_TYPES})")
  endif( ${list_pos} EQUAL -1 )
endforeach()



set( FORCE_REBUILD OFF CACHE BOOL "All installation and build traces of the contrib packages will be removed before building.")
message(STATUS "FORCE_REBUILD: ${FORCE_REBUILD}")

## define building of shared or unshared versions of the contrib libraries
set( BUILD_SHARED_LIBRARIES Off CACHE BOOL "Builds all contrib libraries as shared libraries.")

##################################################
###       ZLIB                                 ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "ZLIB" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("ZLIB")
  OPENMS_CONTRIB_BUILD_ZLIB()
endif()

##################################################
###       BZIP2                                ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "BZIP2" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("BZIP2")
  OPENMS_CONTRIB_BUILD_BZIP2()
endif()

##################################################
###       BOOST                                ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "BOOST" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("BOOST")
  OPENMS_CONTRIB_BUILD_BOOST()
endif()

##################################################
###       ARROW                                ###
##################################################
if (BUILD_TYPE STREQUAL "ALL" OR "ARROW" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("ARROW")
  OPENMS_CONTRIB_BUILD_ARROW()
  OPENMS_COPY_LIBS("ARROW")
endif()

##################################################
###       LIBSVM                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "LIBSVM" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("LIBSVM")
  OPENMS_CONTRIB_BUILD_LIBSVM()
endif()

##################################################
###       XERCES                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "XERCESC" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("XERCES")
  OPENMS_CONTRIB_BUILD_XERCESC()
endif()

##################################################
###       GLPK                                 ###
##################################################
# COIN-OR is the default
if ("GLPK" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("GLPK")
  OPENMS_CONTRIB_BUILD_GLPK()
  OPENMS_COPY_LIBS("GLPK")
endif()

##################################################
###       COIN-OR                              ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "COINOR" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("COINOR")
  OPENMS_CONTRIB_BUILD_COINOR()
  OPENMS_COPY_LIBS("COINOR")
endif()

##################################################
###       EIGEN3                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "EIGEN" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("EIGEN")
  OPENMS_CONTRIB_BUILD_EIGEN()
  OPENMS_COPY_LIBS("EIGEN")
endif()

##################################################
###       KISSFFT                              ###
##################################################

if ("KISSFFT" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("KISSFFT")
  OPENMS_CONTRIB_BUILD_KISSFFT()
  OPENMS_COPY_LIBS("KISSFFT")
endif()

##################################################
###       HDF5                                 ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR "HDF5" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("HDF5")
  OPENMS_CONTRIB_BUILD_HDF5()
  OPENMS_COPY_LIBS("HDF5")
endif()

##################################################
###       OPENMP                               ###
##################################################
if ("OPENMP" IN_LIST BUILD_TYPE)
  OPENMS_CLEAN_LIB("OPENMP")
  OPENMS_CONTRIB_BUILD_OPENMP()
  OPENMS_COPY_LIBS("OPENMP")
endif()

## finally copy README.txt to project-binary directory to mark process complete
configure_file("${PROJECT_SOURCE_DIR}/README.md" "${PROJECT_BINARY_DIR}/README_contrib.txt"  COPYONLY)

message(STATUS "")
message(STATUS "")
if (BUILD_TYPE STREQUAL "ALL")
  message(STATUS "  The contrib package has been built!")
  message(STATUS "  You can now configure and build OpenMS!")
else()
  message(STATUS "  ${BUILD_TYPE} has been built! Some parts of the contrib might still need (re)building.")
  message(STATUS "  Configure and build OpenMS at your discretion!")
endif()
message(STATUS "")
message(STATUS "")
message(STATUS "")
