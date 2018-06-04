MESA_REPO_URL="https://github.com/anholt/mesa.git"
MESA_BRANCH="master"

MESA_SRC_DIR=$EXTRADIR/mesa-anholt
MESA_OUT_DIR=$MESA_SRC_DIR
#$MESA_SRC_DIR/build/$LINUX_PLATFORM

# -----------------------------------------------------------------------------

mesa_get_source()
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
		git -C $MESA_SRC_DIR fetch origin
		git -C $MESA_SRC_DIR reset --hard
		git -C $MESA_SRC_DIR clean -fd

		echo "Checking out branch: ${MESA_BRANCH}"
		git -C $MESA_SRC_DIR checkout -B $MESA_BRANCH
                git -C $MESA_SRC_DIR pull
	else
		rm -rf $MESA_SRC_DIR

		# clone sources
		git clone $MESA_REPO_URL -b $MESA_BRANCH $MESA_SRC_DIR
	fi

	echo "Sources ready."
}

mesa_make()
{
	cd $MESA_SRC_DIR

	[[ -f ./Makefile ]] && make distclean
	[[ ! -f ./configure ]] && ./autogen.sh NOCONFIGURE=y

#	mkdir -p $MESA_OUT_DIR
	cd $MESA_OUT_DIR

#	[[ -f ./Makefile ]] && make distclean

#	if [ "${MESA_FORCE_REBUILD}" = yes ] ; then
#		echo "Force MESA rebuild"
#		rm -rf ./*
#	fi

	rm -rf ./dist
	mkdir ./dist

	echo "Configure MESA..."

	$MESA_SRC_DIR/configure \
			--prefix=/usr \
			--enable-gles2 --enable-gles1 --disable-glx \
			--enable-egl --enable-gallium-egl \
			--with-gallium-drivers=vc4 \
			--with-dri-drivers=swrast \
			--with-platforms=drm  \
			--disable-xvmc --disable-vdpau \
			--host="${LINUX_PLATFORM}" \
			--with-sysroot="${SYSROOT_DIR}" \
			CC="${DEV_GCC}" \
			CXX="${DEV_CXX}" \
			CFLAGS="--sysroot=${SYSROOT_DIR}" \
			CXXFLAGS="--sysroot=${SYSROOT_DIR}" \
			--enable-shared=yes
	echo "Done."

	echo "Making MESA..."

	chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	make DESTDIR="${MESA_OUT_DIR}/dist" install

	echo "Done."
}

mesa_deploy()
{
	echo "Deploying MESA..."

	rsync -az ${MESA_OUT_DIR}/dist/usr/	$SYSROOT_DIR/usr
	rsync -az ${MESA_OUT_DIR}/dist/usr/	${R}/usr

	echo "Done."
}

# -----------------------------------------------------------------------------

echo "Building MESA..."

mesa_get_source

mesa_make

mesa_deploy

echo "MESA build finished."
