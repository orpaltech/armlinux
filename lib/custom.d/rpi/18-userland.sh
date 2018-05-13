#
# Build and deploy userland libs (RPi 2/3 script)
#

USERLAND_URL=https://github.com/raspberrypi/userland.git
USERLAND_BRANCH="master"
USERLAND_DIR=$EXTRADIR/userland

get_userland_source()
{
        if [ -d $USERLAND_DIR ] && [ -d $USERLAND_DIR/.git ] ; then
                # update sources
		git -C $USERLAND_DIR fetch origin
                git -C $USERLAND_DIR reset --hard origin/$USERLAND_BRANCH
                git -C $USERLAND_DIR clean -fd
        else
                rm -rf $USERLAND_DIR

                git clone $USERLAND_URL -b $USERLAND_BRANCH $USERLAND_DIR
        fi
}

make_userland_libs()
{
	cd $USERLAND_DIR

cat << EOF > ./makefiles/cmake/toolchains/${BOARD}-linux-gnueabihf.cmake
#
# CMake defines to cross-compile to ARM/Linux on BCM2835 using glibc.
#

SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_C_COMPILER ${CROSS_COMPILE}gcc)
SET(CMAKE_CXX_COMPILER ${CROSS_COMPILE}g++)
SET(CMAKE_ASM_COMPILER ${CROSS_COMPILE}gcc)
SET(CMAKE_SYSTEM_PROCESSOR arm)

# rdynamic means the backtrace should work
IF (CMAKE_BUILD_TYPE MATCHES "Debug")
   add_definitions(-rdynamic)
ENDIF()

# avoids annoying and pointless warnings from gcc
SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -U_FORTIFY_SOURCE")
SET(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -c")
EOF

	# Cross compile on a more capable machine
	rm -rf ./build
	mkdir -p ./build/${BOARD}
	cd ./build/${BOARD}

	cmake -DCMAKE_TOOLCHAIN_FILE="../../makefiles/cmake/toolchains/${BOARD}-linux-gnueabihf.cmake" -DCMAKE_BUILD_TYPE="Release" ../..

	make -j${NUM_CPU_CORES}
	make install DESTDIR=${R}
}

if [ "${SOC_ARCH}" = "arm" ] ; then

	get_userland_source

	make_userland_libs


	echo "/opt/vc/lib" > "${ETC_DIR}/ld.so.conf.d/00-vmcs.conf"
else
	echo "Skip userland compilation for [${SOC_ARCH}]"
fi
