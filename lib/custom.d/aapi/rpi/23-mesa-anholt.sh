#
# Build and deploy MESA 3D library (RaspberryPi)
#

#MESA_REPO_URL="https://github.com/anholt/mesa.git"
MESA_REPO_URL="https://gitlab.freedesktop.org/mesa/mesa.git"
MESA_BRANCH="master"
# MESA_RELEASE="18.2.0"
# MESA_TAG="mesa-${MESA_RELEASE}"

MESA_FORCE_UPDATE="no"
MESA_FORCE_REBUILD="yes"

MESA_SRC_DIR=$EXTRADIR/mesa-anholt
MESA_OUT_DIR=$MESA_SRC_DIR/build/$LINUX_PLATFORM

MESA_PREFIX="/usr"


# -----------------------------------------------------------------------------

mesa_update()
{
	echo "Prepare MESA sources..."

	if [ "${MESA_FORCE_UPDATE}" = yes ] ; then
		echo "Force MESA update"
		rm -rf $MESA_SRC_DIR
	fi

	if [ -d $MESA_SRC_DIR ] && [ -d $MESA_SRC_DIR/.git ] ; then
		local OLD_URL=$(git -C $MESA_SRC_DIR config --get remote.origin.url)
		if [ "${OLD_URL}" != "${MESA_REPO_URL}" ] ; then
			rm -rf $MESA_SRC_DIR
		fi
	fi
	if [ -d $MESA_SRC_DIR ] && [ -d $MESA_SRC_DIR/.git ] ; then
		# update sources
		git -C $MESA_SRC_DIR fetch origin --tags

		git -C $MESA_SRC_DIR reset --hard
		git -C $MESA_SRC_DIR clean -fd

		echo "Checking out branch: ${MESA_BRANCH}"
		git -C $MESA_SRC_DIR checkout -B $MESA_BRANCH origin/$MESA_BRANCH
		git -C $MESA_SRC_DIR pull
	else
		[[ -d $MESA_SRC_DIR ]] && rm -rf $MESA_SRC_DIR

		# clone sources
		git clone $MESA_REPO_URL -b $MESA_BRANCH $MESA_SRC_DIR
	fi

	if [ ! -z "${MESA_TAG}" ] ; then
		echo "Checking out tag: tags/${MESA_TAG}"
		git -C $MESA_SRC_DIR checkout tags/$MESA_TAG

		MESA_DEB_VER="${MESA_RELEASE}-tag"
	else
		MESA_RELEASE=$(head -n 1 ${MESA_SRC_DIR}/VERSION)
		LAST_COMMIT_ID=$(git -C $MESA_SRC_DIR log --format="%h" -n 1)
		MESA_DEB_VER="${MESA_RELEASE}-${LAST_COMMIT_ID}"
	fi

	MESA_DEB_PKG_VER="${MESA_DEB_VER}-${DEBIAN_RELEASE_ARCH}-${SOC_FAMILY}"
	MESA_DEB_PKG="mesa-${MESA_DEB_PKG_VER}"
	MESA_DEB_DIR="${DEBS_DIR}/${MESA_DEB_PKG}-deb"

	echo "Sources ready."
}

mesa_make()
{
	cd $MESA_SRC_DIR

	if [ "${MESA_FORCE_REBUILD}" = yes ] ; then
		echo "Force MESA rebuild"
		rm -rf $MESA_OUT_DIR
		rm -f ./configure
        fi
	if [ ! -f ./configure ] ; then
		NOCONFIGURE=y ./autogen.sh
	fi

	mkdir -p $MESA_OUT_DIR
	cd $MESA_OUT_DIR

	mkdir -p ./dist
	rm -rf ./dist/*

	if [ ! -f ./Makefile ] ; then
		echo "Configure MESA..."

		$MESA_SRC_DIR/configure \
			--prefix=$MESA_PREFIX \
			--enable-gles2 \
			--enable-gles1 \
			--enable-egl \
			--disable-glx \
			--disable-dri3 \
			--with-gallium-drivers=vc4 \
			--with-dri-drivers=swrast \
			--with-platforms=drm \
			--disable-xvmc \
			--disable-vdpau \
			--host="${LINUX_PLATFORM}" \
			--with-sysroot="${SYSROOT_DIR}" \
			--enable-shared=yes \
			CC="${DEV_GCC}" \
			CXX="${DEV_CXX}" \
			CFLAGS="--sysroot=${SYSROOT_DIR}" \
			CXXFLAGS="--sysroot=${SYSROOT_DIR}"
		[ $? -eq 0 ] || exit $?;

		echo "Done."
	else
		make distclean
	fi

	echo "Making MESA..."

	chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	make DESTDIR="${MESA_OUT_DIR}/dist" install

	echo "Done."
}

mesa_deb_pkg()
{
	echo "Create MESA deb package..."

	mkdir -p $MESA_DEB_DIR
	rm -rf ${MESA_DEB_DIR}/*

	mkdir ${MESA_DEB_DIR}/DEBIAN

	cat <<-EOF > ${MESA_DEB_DIR}/DEBIAN/control
Package: $MESA_DEB_PKG
Version: $MESA_DEB_PKG_VER
Maintainer: $MAINTAINER_NAME <$MAINTAINER_EMAIL>
Architecture: all
Priority: optional
Description: This package provides Mesa 3D libraries
EOF

	mkdir -p ${MESA_DEB_DIR}${MESA_PREFIX}
	rsync -az ${MESA_OUT_DIR}/dist${MESA_PREFIX}/  ${MESA_DEB_DIR}${MESA_PREFIX}

        dpkg-deb -z0 -b $MESA_DEB_DIR  ${BASEDIR}/debs/${MESA_DEB_PKG}.deb
        [ $? -eq 0 ] || exit $?;

        rm -rf $MESA_DEB_DIR

        echo "Done."
}

mesa_deploy()
{
	echo "Deploying MESA..."

	mkdir -p ${MESA_DEB_DIR}
        dpkg -x ${BASEDIR}/debs/${MESA_DEB_PKG}.deb  ${MESA_DEB_DIR}  2> /dev/null
        mkdir -p ${SYSROOT_DIR}${MESA_PREFIX}
        rsync -az ${MESA_DEB_DIR}${MESA_PREFIX}/  ${SYSROOT_DIR}${MESA_PREFIX}
	${LIBDIR}/make-relativelinks.sh ${SYSROOT_DIR}${MESA_PREFIX}/lib
        rm -rf ${MESA_DEB_DIR}

        cp ${BASEDIR}/debs/${MESA_DEB_PKG}.deb	${R}/tmp/
        chroot_exec dpkg -i /tmp/${MESA_DEB_PKG}.deb
        rm -f ${R}/tmp/${MESA_DEB_PKG}.deb

	echo "Done."
}

# -----------------------------------------------------------------------------

echo "Building MESA..."

mesa_update

if [[ $CLEAN =~ (^|,)"mesa"(,|$) ]] ; then
	rm -f ${BASEDIR}/debs/${MESA_DEB_PKG}.deb
fi

if [ ! -f ${BASEDIR}/debs/${MESA_DEB_PKG}.deb ] ; then
	mesa_make
	mesa_deb_pkg
fi

mesa_deploy

echo "MESA build finished."
