# generic toolchain file for cross-compile
set(CMAKE_SYSTEM_NAME Linux)
include_guard(GLOBAL)

# these two are initialized from env variables
# or can be updated with real values by the scripts
set(TARGET_SYSROOT	$ENV{QT_CROSS_SYSROOT})
set(CROSS_COMPILE	$ENV{QT_CROSS_COMPILE})

# which compilers to use for C and C++
set(CMAKE_C_COMPILER		${CROSS_COMPILE}gcc)
set(CMAKE_CXX_COMPILER		${CROSS_COMPILE}g++)
set(CMAKE_LINKER		${CROSS_COMPILE}ld)
set(CMAKE_AR			${CROSS_COMPILE}ar)

set(ENV{PKG_CONFIG_LIBDIR}	${TARGET_SYSROOT}/lib/pkgconfig:${TARGET_SYSROOT}/usr/lib/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR}	${TARGET_SYSROOT})

# location of the target environment
set(CMAKE_FIND_ROOT_PATH	${TARGET_SYSROOT})

set(CMAKE_SYSROOT               "")

# adjust the default behavior of the FIND_XXX() commands:
# search for headers and libraries in the target environment,
# search for programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM	NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY	ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE	ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE	ONLY)

# use, i.e. don't skip the full RPATH for the build tree
set(CMAKE_SKIP_BUILD_RPATH      FALSE)
# when building, don't use the install RPATH already
# (but later on when installing)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
# the RPATH to be used when installing
set(CMAKE_INSTALL_RPATH         "")
# don't add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
