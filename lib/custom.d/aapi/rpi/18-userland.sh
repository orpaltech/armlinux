#
# Build and deploy userland libs (RaspberryPi)
#

USERLAND_URL="https://github.com/raspberrypi/userland.git"
USERLAND_BRANCH="master"
USERLAND_DIR=$EXTRADIR/userland
# fake version required by deb package
USERLAND_VER="1.0.0"

USERLAND_FORCE_UPDATE="no"

userland_update()
{
	if [ "${USERLAND_FORCE_UPDATE}" = yes ] ; then
		echo "Force userland update"
		rm -rf $USERLAND_DIR
	fi

	if [ -d $USERLAND_DIR/.git ] ; then
		local OLD_URL=$(git -C $USERLAND_DIR config --get remote.origin.url)
		if [ "${OLD_URL}" != "${USERLAND_URL}" ] ; then
			rm -rf $USERLAND_DIR
		fi
	fi
        if [ -d $USERLAND_DIR/.git ] ; then
                # update sources
		git -C $USERLAND_DIR fetch origin --tags

		git -C $USERLAND_DIR reset --hard
		git -C $USERLAND_DIR clean -fd

		echo "Checking out branch: ${USERLAND_BRANCH}"
		git -C $USERLAND_DIR checkout -B $USERLAND_BRANCH origin/$USERLAND_BRANCH
		git -C $USERLAND_DIR pull
        else
                [[ -d $USERLAND_DIR ]] && rm -rf $USERLAND_DIR

                git clone $USERLAND_URL -b $USERLAND_BRANCH  $USERLAND_DIR
        fi

        LAST_COMMIT_ID=$(git -C ${USERLAND_DIR} log --format="%h" -n 1)
        USERLAND_DEB_VER="${USERLAND_VER}-${LAST_COMMIT_ID}"
	USERLAND_DEB_PKG_VER="${USERLAND_DEB_VER}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}"
        USERLAND_DEB_PKG="userland-${USERLAND_DEB_PKG_VER}"
        USERLAND_DEB_DIR="${DEBS_DIR}/${USERLAND_DEB_PKG}-deb"
}

userland_make()
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

	cmake -DCMAKE_TOOLCHAIN_FILE="../../makefiles/cmake/toolchains/${BOARD}-linux-gnueabihf.cmake" \
		-DCMAKE_BUILD_TYPE="Release" ../..

        chrt -i 0 make -j${NUM_CPU_CORES}
        [ $? -eq 0 ] || exit $?;

	mkdir -p ./dist
	make install DESTDIR="${USERLAND_DIR}/build/${BOARD}/dist"

}

userland_deb_pkg()
{
	echo "Create Userland deb package..."

	mkdir -p $USERLAND_DEB_DIR
        rm -rf ${USERLAND_DEB_DIR}/*

        mkdir ${USERLAND_DEB_DIR}/DEBIAN

        cat <<-EOF > ${USERLAND_DEB_DIR}/DEBIAN/control
Package: $USERLAND_DEB_PKG
Version: $USERLAND_DEB_PKG_VER
Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
Architecture: all
Priority: optional
Description: This package provides RaspberryPi Userland libraries
EOF

	cat <<-EOF > ${USERLAND_DEB_DIR}/DEBIAN/postinst
#!/bin/sh

set -e

case "\$1" in
  configure)
    echo "/opt/vc/lib" > /etc/ld.so.conf.d/00-vmcs.conf
    ldconfig -X
    ;;
esac

exit 0
EOF
	chmod +x ${USERLAND_DEB_DIR}/DEBIAN/postinst

	rsync -az ${USERLAND_DIR}/build/${BOARD}/dist/  ${USERLAND_DEB_DIR}

	dpkg-deb -z0 -b $USERLAND_DEB_DIR  ${BASEDIR}/debs/${USERLAND_DEB_PKG}.deb
	[ $? -eq 0 ] || exit $?;

	rm -rf $USERLAND_DEB_DIR

	echo "Done."
}

userland_deploy()
{
	echo "Deploying Userland..."

	mkdir -p ${USERLAND_DEB_DIR}
        dpkg -x ${BASEDIR}/debs/${USERLAND_DEB_PKG}.deb  ${USERLAND_DEB_DIR} 2> /dev/null
	mkdir -p ${SYSROOT_DIR}/opt
        rsync -az ${USERLAND_DEB_DIR}/opt/  ${SYSROOT_DIR}/opt
        ${LIBDIR}/make-relativelinks.sh  ${SYSROOT_DIR}/opt/vc/lib
        rm -rf ${USERLAND_DEB_DIR}

        cp ${BASEDIR}/debs/${USERLAND_DEB_PKG}.deb  ${R}/tmp/
        chroot_exec dpkg -i /tmp/${USERLAND_DEB_PKG}.deb
        rm -f ${R}/tmp/${USERLAND_DEB_PKG}.deb

        echo "Done."
}

if [ "${SOC_ARCH}" = "arm" ] ; then

	userland_update

	if [[ $CLEAN =~ (^|,)"userland"(,|$) ]] ; then
		rm -f ${BASEDIR}/debs/${USERLAND_DEB_PKG}.deb
	fi

	if [ ! -f ${BASEDIR}/debs/${USERLAND_DEB_PKG}.deb ] ; then
		userland_make
		userland_deb_pkg
	fi

	userland_deploy
else
	echo "Skip userland build for ${SOC_ARCH}"
fi
