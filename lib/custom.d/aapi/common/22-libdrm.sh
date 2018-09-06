LIBDRM_VER="2.4.93"
LIBDRM_SRC_DIR=$EXTRADIR/libdrm-$LIBDRM_VER
LIBDRM_OUT_DIR=$LIBDRM_SRC_DIR/build/$LINUX_PLATFORM

LIBDRM_TAR_URL="https://dri.freedesktop.org/libdrm/libdrm-${LIBDRM_VER}.tar.gz"

LIBDRM_FORCE_UPDATE="no"
LIBDRM_FORCE_REBUILD="yes"

LIBDRM_PREFIX=/usr

# ----------------------------------------------------------------------------

libdrm_get_src()
{
	if [ ! -d $LIBDRM_SRC_DIR ] || [ "${LIBDRM_FORCE_UPDATE}" = yes ] ; then
		echo "Download LIBDRM sources..."

		rm -rf $LIBDRM_SRC_DIR
		local TAR_PATH="${LIBDRM_SRC_DIR}.tar.gz"
		[ ! -f $TAR_PATH ] && wget -O $TAR_PATH $LIBDRM_TAR_URL
		tar -xvf $TAR_PATH -C "${EXTRADIR}/"
		rm -f $TAR_PATH

		echo "Done."
	fi
}

libdrm_make()
{
	mkdir -p $LIBDRM_OUT_DIR
        cd $LIBDRM_OUT_DIR

	if [ "${LIBDRM_FORCE_REBUILD}" = yes ] ; then
                echo "Forcing LIBDRM rebuild"
                rm -rf ./*
        fi

	mkdir -p ./dist
	rm -rf ./dist/*

        echo "Configure LIBDRM..."

        $LIBDRM_SRC_DIR/configure \
			--prefix="${LIBDRM_PREFIX}" \
			--host="${LINUX_PLATFORM}" \
			--with-sysroot="${SYSROOT_DIR}" \
			--verbose \
			--enable-shared \
			--enable-vc4 \
			--disable-install-test-programs \
			--disable-cairo-tests \
			CC="${DEV_GCC}" \
			CXX="${DEV_CXX}" \
			CFLAGS="--sysroot=${SYSROOT_DIR}" \
			CXXFLAGS="--sysroot=${SYSROOT_DIR}"
	echo "Done."

	echo "Making LIBDRM..."

	chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	make DESTDIR="${LIBDRM_OUT_DIR}/dist" install

	echo "Make finished."
}

libdrm_deploy()
{
	echo "Deploying LIBDRM..."

	rsync -az ${LIBDRM_OUT_DIR}/dist${LIBDRM_PREFIX}/	${SYSROOT_DIR}${LIBDRM_PREFIX}
	${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}${LIBDRM_PREFIX}/lib

	rsync -az ${LIBDRM_OUT_DIR}/dist${LIBDRM_PREFIX}/	${R}${LIBDRM_PREFIX}

	echo "Done."
}

# ----------------------------------------------------------------------------

echo "Building LIBDRM..."

libdrm_get_src

libdrm_make

libdrm_deploy

echo "LIBDRM build finished."
