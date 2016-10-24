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
##   the original developer. In some cases you need to rely on third party packages, e.g. the gsl-win project, which provides solution files.
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
## SEQAN:  headers only library, no compilation necessary for OpenMS
## LibSVM: comes with a Makefile.win, but libsvm needed some serious tweaking to support debug mode and to build a lib (instead of object files only)
## XERCES-C: they offer a VS version on their website (http://xerces.apache.org/xerces-c/), usually not for bleeding edge release though - bad luck for us.
## GSL:    get the src package from http://gnuwin32.sourceforge.net/packages/gsl.htm,
##         This should still contain the Linux Makefiles.
## GLPK:   download from http://ftp.gnu.org/gnu/glpk/glpk-4.46.tar.gz
## COIN-OR: we use the CoinMP package available from
##         http://www.coin-or.org/download/source/CoinMP/CoinMP-1.3.3.tgz


## some words:
## Patching: We do not (by intention) use a ".is_patched" file, but let patch(.exe) handle create a .orig file, which is in the same location as the patched file

## required software:
## Windows: 7-Zip & GNUWin32-patch
## Linux&MinGW: Tar & patch
## (these are searched for and an appropriate error message is given when not found)


## NOTE: remove "exec_program" calls and substitute with exec_process (see http://www.cmake.org/cmake/help/cmake2.6docs.html#command:execute_process)
##       - however: exec_process seems to handle our arguments incorrectly (at least on Windows). Check functionality before you commit!

# Determine what to build (all or single library)
set( BUILD_TYPE LIST CACHE STRING "Can be used to restrict building to a single library: ALL,SEQAN,LIBSVM,XERCESC,BOOST,GSL,COINOR,BZIP2,ZLIB,GLPK")
set( VALID_BUILD_TYPES "ALL" "SEQAN" "LIBSVM" "XERCESC" "BOOST" "GSL" "COINOR" "BZIP2" "ZLIB" "GLPK" "EIGEN" "WILDMAGIC")
# check build type
if (BUILD_TYPE STREQUAL "HELP" OR BUILD_TYPE STREQUAL "LIST")
  message(STATUS "===========================================================================")
  message(STATUS " OpenMS contrib (dependency packages) installation.")
  message(STATUS " This program will allow you to compile and install all of the OpenMS")
  message(STATUS " dependencies. Select the package you wish to install using the the command")
  message(STATUS " -DBUILD_TYPE= or install all of them with -DBUILD_TYPE=ALL.")
  message(STATUS "===========================================================================")
  message(STATUS "Valid BUILD_TYPEs are:")
  foreach( BT ${VALID_BUILD_TYPES} )
    message(STATUS " * ${BT}")
  endforeach( BT VALID_BUILD_TYPES )
  return(0)
endif()

PROJECT("OpenMS_CONTRIB")

# Heart of the BUILD system : only edit when you know what you are doing (we don't)
# quick manual for most commands: http://www.cmake.org/cmake/help/cmake2.6docs.html
# useful predefined variables: http://www.paraview.org/Wiki/CMake_Useful_Variables

cmake_minimum_required(VERSION 2.8.3 FATAL_ERROR)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS true)

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
set(ZLIB_DIR ${CONTRIB_BIN_SOURCE_DIR}/zlib-1.2.5)
set(BOOST_DIR ${CONTRIB_BIN_SOURCE_DIR}/boost_1_52_0)
set(XERCES_DIR ${CONTRIB_BIN_SOURCE_DIR}/xerces-c-3.1.1)
set(GSL_DIR ${CONTRIB_BIN_SOURCE_DIR}/gsl-1.13)
set(LIBSVM_DIR ${CONTRIB_BIN_SOURCE_DIR}/libsvm-3.12)
set(SEQAN_DIR ${CONTRIB_BIN_SOURCE_DIR}/seqan-1.4.1)
set(GLPK_DIR ${CONTRIB_BIN_SOURCE_DIR}/glpk-4.46)
set(COINOR_DIR ${CONTRIB_BIN_SOURCE_DIR}/CoinMP-1.3.3)
set(EIGEN_DIR ${CONTRIB_BIN_SOURCE_DIR}/eigen-eigen-ffa86ffb5570)
set(WILDMAGIC_DIR ${CONTRIB_BIN_SOURCE_DIR}/WildMagic5)

## source(archive) paths
## PLEASE upload all source archives to
##     https://sourceforge.net/projects/open-ms/files/contrib/
## and provide the necessary information below
##  ARCHIVE_<LIBNAME> the name of the archive as it was uploaded
##  ARCHIVE_<LIBNAME>_TAR the name of the tar in the tar.gz
##  ARCHIVE_<LIBNAME>_SHA1 the sha1 of the file uploaded to sourceforge
## e.g.
##  set(ARCHIVE_ZLIB zlib.tar.gz)
##  set(ARCHIVE_ZLIB_TAR zlib.tar)
##  set(ARCHIVE_ZLIB_SHA1 "8e8b93fa5eb80df1afe5422309dca42964562d7e")
## NOTE: for local development you can simply place the *.tar.gz in the binary
##       directory to prevent the download and sha1 verification

set(ARCHIVE_BZIP2 bzip2-1.0.5.tar.gz)
set(ARCHIVE_BZIP2_TAR bzip2-1.0.5.tar)
set(ARCHIVE_BZIP2_SHA1 "8b02713ea0c8eb501cc8bdac4432d7f29700f767")

set(ARCHIVE_ZLIB zlib-1.2.5.tar.gz)
set(ARCHIVE_ZLIB_TAR  zlib-1.2.5.tar)
set(ARCHIVE_ZLIB_SHA1 "8e8b93fa5eb80df1afe5422309dca42964562d7e")

set(ARCHIVE_BOOST boost_1_52_0.tar.gz)
set(ARCHIVE_BOOST_TAR  boost_1_52_0.tar)
set(ARCHIVE_BOOST_SHA1 "7cddbfd33fc99ed69343cd5cf8461648f8eae75a")

set(ARCHIVE_XERCES xerces-c-3.1.1.tar.gz)
set(ARCHIVE_XERCES_TAR  xerces-c-3.1.1.tar)
set(ARCHIVE_XERCES_SHA1 "9ec2c6993a9c72b73b2819b2ad33856ad39089d9")

set(ARCHIVE_GSL gsl-1.13.tar.gz)
set(ARCHIVE_GSL_TAR  gsl-1.13.tar)
set(ARCHIVE_GSL_SHA1 "704845d46d4a1fd807543a42a58b3fb17f13dfaa")

set(ARCHIVE_LIBSVM libsvm-3.12.tar.gz)
set(ARCHIVE_LIBSVM_TAR  libsvm-3.12.tar)
set(ARCHIVE_LIBSVM_SHA1 "6ee77eb3d89af07fe48058dba0dcc24c85020b85")

set(ARCHIVE_SEQAN seqan-mini-1.4.1.tar.gz)
set(ARCHIVE_SEQAN_TAR  seqan-mini-1.4.1.tar)
set(ARCHIVE_SEQAN_SHA1 "1aecb390311a12330c5a1c8d91cb9ac4cd8e1718")

set(ARCHIVE_GLPK glpk-4.46.tar.gz)
set(ARCHIVE_GLPK_TAR  glpk-4.46.tar)
set(ARCHIVE_GLPK_SHA1 "73d589452dc1d8d6a784b3f86f4268cae37420d7")

set(ARCHIVE_COINOR CoinMP-1.3.3.tar.gz)
set(ARCHIVE_COINOR_TAR  CoinMP-1.3.3.tar)
set(ARCHIVE_COINOR_SHA1 "28d29dae6abf6cdef027dcfa4961bb10b7f540cb")

set(ARCHIVE_EIGEN eigen-3.2.0.tar.gz)
set(ARCHIVE_EIGEN_TAR  eigen-3.2.0.tar)
set(ARCHIVE_EIGEN_SHA1 "7134378dd56608f67dd66ff6d5a2dfb077ef52a4")

set(ARCHIVE_WILDMAGIC WildMagic5.tar.gz)
set(ARCHIVE_WILDMAGIC_TAR  WildMagic5.tar)
set(ARCHIVE_WILDMAGIC_SHA1 "e30b6f7f955c640dadfea09385a0a0ddec5b2997")

## necessary for clean up .. change if install process of library changes
set(INCLUDE_DIR_BOOST ${CONTRIB_BIN_INCLUDE_DIR}/boost)
set(INCLUDE_DIR_XERCES ${CONTRIB_BIN_INCLUDE_DIR}/xercesc)
set(INCLUDE_DIR_GSL ${CONTRIB_BIN_INCLUDE_DIR}/gsl)
set(INCLUDE_DIR_SEQAN ${CONTRIB_BIN_INCLUDE_DIR}/seqan)
set(INCLUDE_DIR_GLPK ${CONTRIB_BIN_INCLUDE_DIR}/GLPK)
set(INCLUDE_DIR_COINOR ${CONTRIB_BIN_INCLUDE_DIR}/coin)
set(INCLUDE_DIR_EIGEN ${CONTRIB_BIN_INCLUDE_DIR}/eigen3)
set(INCLUDE_DIR_WILDMAGIC ${CONTRIB_BIN_INCLUDE_DIR}/WildMagic5)

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
message(STATUS "ADDRESSMODEL IS: ${CONTRIB_ADDRESSMODEL} bit")
if (NOT CONTRIB_ADDRESSMODEL MATCHES "32|64")
  Message(FATAL_ERROR "CONTRIB_ADDRESSMODEL is neither 32 nor 64! Please correct this!")
endif()

# logfile
set(LOGFILE "${PROJECT_BINARY_DIR}/contrib_build.log")

if (MSVC)
  ## guess MSVC Version (we need this in order to correctly guess the names of the VS solution targets.
  if (CMAKE_GENERATOR MATCHES ".*Visual Studio 8 2005.*")
    set(TMP_MSVC_VERSION "8")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 9 2008.*")
    set(TMP_MSVC_VERSION "9")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 10.*")
    set(TMP_MSVC_VERSION "10")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 11.*")
    set(TMP_MSVC_VERSION "11")
  elseif (CMAKE_GENERATOR MATCHES ".*Visual Studio 12.*")
    set(TMP_MSVC_VERSION "12")
  else()
    message(FATAL_ERROR "Please use 'Visual Studio ?? [Win64]' (??={8 2005, 9 2008, 10, 11, 12}) as Generator - identical to the MSVC toolchain you plan to use for OpenMS! Note that you must not use NMake or alike for the contrib (nor for OpenMS). There will be errors (mostly missing libraries).")
  endif()
  set(CONTRIB_MSVC_VERSION ${TMP_MSVC_VERSION} CACHE INTERNAL "Microsoft Visual Studio Version used. Valid values: 8 and above")
  ## parameter validity check
  message(STATUS "MSVC Version is: ${CONTRIB_MSVC_VERSION}")

  ## some settings for Building the libs
  if (CONTRIB_ADDRESSMODEL MATCHES 32)
    set(BOOST_ARG "")
    set(WIN_PLATFORM_ARG "Win32")
  else()
    set(BOOST_ARG "address-model=64")
    set(WIN_PLATFORM_ARG "x64")
  endif()

  find_program(PROGRAM_ZIP "7z.exe" PATHS "C:/Program Files/7-Zip" "C:/Programme/7-Zip")
  if (NOT PROGRAM_ZIP)
    message(FATAL_ERROR "Cannot find '7z.exe' on your system. Please install 7-zip and add the directory to your PATH environment variable!")
  endif()

  ## http://gnuwin32.sourceforge.net/packages/patch.htm
  find_program(PROGRAM_PATCH "patch.exe" PATHS "C:/Program Files/gnuwin32/bin" "C:/Program Files/patch/bin")
  if (NOT PROGRAM_PATCH)
    message(FATAL_ERROR "Cannot find 'patch.exe' on your system. Please install gnuwin32-patch and add the directory to your PATH environment variable!")
  endif()

else() ## linux/Mingw/macos
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

# see if we use GNU CXX/CC -- this one is required for CGAL etc.
# TODO: check if this one is really working
#if(NOT MSVC AND NOT CMAKE_COMPILER_IS_GNUCXX)
#  message(FATAL_ERROR "Please specify the GNU CXX (g++) as C++ compiler")
#elseif(NOT MSVC AND NOT CMAKE_COMPILER_IS_GNUCC)
#  message(FATAL_ERROR "Please specify the GNU C (gcc) as C compiler")
#endif()


## prepare
file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
file(MAKE_DIRECTORY "${CONTRIB_BIN_SOURCE_DIR}")
file(MAKE_DIRECTORY "${CONTRIB_BIN_INCLUDE_DIR}")

## initial log values
file(WRITE ${LOGFILE} "-- Starting to build contrib --\n\r")
file(APPEND ${LOGFILE} "CXX: ${CMAKE_CXX_COMPILER}\n\r")
file(APPEND ${LOGFILE} "CC: ${CMAKE_C_COMPILER}\n\r")

## include extract/patch/build macros
include ("${CMAKE_SOURCE_DIR}/macros.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/seqan.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/libsvm.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/xercesc.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/boost.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/gsl.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/glpk.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/bzip2.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/zlib.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/coinor.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/eigen.cmake")
include ("${CMAKE_SOURCE_DIR}/libraries.cmake/wildmagic.cmake")

## build mac os x specific C/C++ flags
set( OPENMS_CONTRIB_MACOSX_MIXED_MODE 0 CACHE INTERNAL "building multiple architectures on MacOSX" FORCE)
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CXX_OSX_FLAGS "-mmacosx-version-min=10.6")
  message(STATUS "Using custom OS X architecture flags for CXX compiler: \"${CXX_OSX_FLAGS}\"")
  file(APPEND ${LOGFILE} "Using custom OS X architecture flags for CXX compiler: \"${CXX_OSX_FLAGS}\"\n\r")

  # check ich c++ is used; if, switch to g++ for some strange
  # incompatibility reasons
  if (${CMAKE_CXX_COMPILER} MATCHES "/c[+][+]")
    set(MACOSX_COMPILER ${CMAKE_CXX_COMPILER})
    string(REPLACE "c++" "g++" MACOSX_FIXED_COMPILER ${MACOSX_COMPILER})
    message(WARNING "Using '${CMAKE_CXX_COMPILER}' may cause problems, automatically replacing by '${MACOSX_FIXED_COMPILER}'!")
    set(CMAKE_CXX_COMPILER ${MACOSX_FIXED_COMPILER} CACHE INTERNAL "Forcing '${CMAKE_CXX_COMPILER}' compiler (replacing '${CMAKE_CXX_COMPILER}' compiler)." FORCE)
  endif()

  # force cmake > 2.8.1 to avoid bugs with OSX_DEPLOYMENT_TARGET
  cmake_minimum_required(VERSION 2.8.1 FATAL_ERROR)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")

list(FIND VALID_BUILD_TYPES ${BUILD_TYPE} list_pos)
if( ${list_pos} EQUAL -1 )
  message(STATUS "The BUILD_TYPE ${BUILD_TYPE} is invalid")
  message(STATUS "Valid BUILD_TYPEs are:")
  foreach( BT ${VALID_BUILD_TYPES} )
    message(STATUS " * ${BT}")
  endforeach( BT VALID_BUILD_TYPES )
  message(FATAL_ERROR "Aborting contrib build!")
else( ${list_pos} EQUAL -1 )
  message(STATUS "BUILD_TYPE: ${BUILD_TYPE} (one of: ${VALID_BUILD_TYPES})")
endif( ${list_pos} EQUAL -1 )

set( FORCE_REBUILD OFF CACHE BOOL "All installation and build traces of the contrib packages will be removed before building.")
message(STATUS "FORCE_REBUILD: ${FORCE_REBUILD}")

set( NUMBER_OF_JOBS 2 CACHE STRING "Number of jobs executed in parallel during the build process if the build system supports multi-job builds (e.g., make, bjam)")
if("${NUMBER_OF_JOBS}" STREQUAL "")
  set( NUMBER_OF_JOBS 1 )
endif("${NUMBER_OF_JOBS}" STREQUAL "")
message(STATUS "NUMBER_OF_JOBS: ${NUMBER_OF_JOBS} (maximal number of concurrent compile jobs)")

## define building of shared or unshared versions of the contrib libraries
set( BUILD_SHARED_LIBRARIES Off CACHE BOOL "Builds all contrib libraries as shared libraries.")

##################################################
###       SEQAN                                ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "SEQAN")
  OPENMS_CLEAN_LIB("SEQAN")
  OPENMS_CONTRIB_BUILD_SEQAN()
endif()

##################################################
###       LIBSVM                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "LIBSVM")
  OPENMS_CLEAN_LIB("LIBSVM")
  OPENMS_CONTRIB_BUILD_LIBSVM()
endif()

##################################################
###       XERCES                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "XERCESC")
  OPENMS_CLEAN_LIB("XERCES")
  OPENMS_CONTRIB_BUILD_XERCESC()
  OPENMS_COPY_LIBS("XERCES")
endif()

##################################################
###       BZIP2                                ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "BZIP2")
  OPENMS_CLEAN_LIB("BZIP2")
  OPENMS_CONTRIB_BUILD_BZIP2()
endif()

##################################################
###       ZLIB                                 ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "ZLIB")
  OPENMS_CLEAN_LIB("ZLIB")
  OPENMS_CONTRIB_BUILD_ZLIB()
endif()

##################################################
###       BOOST                                ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "BOOST")
  OPENMS_CLEAN_LIB("BOOST")
  OPENMS_CONTRIB_BUILD_BOOST()
endif()

##################################################
###       GSL                                  ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "GSL")
  OPENMS_CLEAN_LIB("GSL")
  OPENMS_CONTRIB_BUILD_GSL()
  OPENMS_COPY_LIBS("GSL")
endif()


##################################################
###       GLPK                                 ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "GLPK")
  OPENMS_CLEAN_LIB("GLPK")
  OPENMS_CONTRIB_BUILD_GLPK()
  OPENMS_COPY_LIBS("GLPK")
endif()

##################################################
###       COIN-OR                              ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "COINOR")
  OPENMS_CLEAN_LIB("COINOR")
  OPENMS_CONTRIB_BUILD_COINOR()
  OPENMS_COPY_LIBS("COINOR")
endif()

##################################################
###       EIGEN3                               ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "EIGEN")
  OPENMS_CLEAN_LIB("EIGEN")
  OPENMS_CONTRIB_BUILD_EIGEN()
  OPENMS_COPY_LIBS("EIGEN")
endif()

##################################################
###       WILDMAGIC                            ###
##################################################

if (BUILD_TYPE STREQUAL "ALL" OR BUILD_TYPE STREQUAL "WILDMAGIC")
  OPENMS_CLEAN_LIB("WILDMAGIC")
  OPENMS_CONTRIB_BUILD_WILDMAGIC()
  OPENMS_COPY_LIBS("WILDMAGIC")
endif()

## finally copy README.txt to project-binary directory to mark process complete
configure_file("${PROJECT_SOURCE_DIR}/README.md" "${PROJECT_BINARY_DIR}/README_contrib1.7.txt"  COPYONLY)

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
