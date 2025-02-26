# generic toolchain file for cross-compile
set(CMAKE_SYSTEM_NAME Linux)

# which compilers to use for C and C++
set(CMAKE_C_COMPILER		${CROSS_COMPILE}gcc)
set(CMAKE_CXX_COMPILER		${CROSS_COMPILE}g++)
set(CMAKE_LINKER		${CROSS_COMPILE}ld)
set(CMAKE_AR			${CROSS_COMPILE}ar)
set(CMAKE_RANLIB		${CROSS_COMPILE}ranlib)

# location of the target environment
set(CMAKE_FIND_ROOT_PATH	${CROSS_SYSROOT})

# adjust the default behavior of the FIND_XXX() commands:
# search for headers and libraries in the target environment,
# search for programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM	NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY	ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE	ONLY)
