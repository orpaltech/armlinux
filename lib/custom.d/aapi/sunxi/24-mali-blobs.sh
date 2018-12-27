#
# Deploy Mali userspace binaries (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_BLOB_TYPE=${MALI_BLOB_TYPE:="fbdev"}

MALI_BLOB_DIR="${SUNXI_DIR}/bootlin-mali-blobs"
MALI_BLOB_REPO="https://github.com/bootlin/mali-blobs.git"
MALI_BLOB_BRANCH="master"

MALI_BLOB_INC_DIR="${MALI_BLOB_DIR}/include/${MALI_BLOB_TYPE}"
MALI_BLOB_LIB_DIR="${MALI_BLOB_DIR}/${MALI_DRV_VER}/${SOC_ARCH}/${MALI_BLOB_TYPE}"


mali_blobs_deploy()
{
	echo "Deploy Mali userspace binaries..."

	if [ -z "${MALI_DRV_VER}" ] ; then
		echo "ERROR: Mali driver version is required!"
		exit 1
        fi

	rm -rf $MALI_BLOB_DIR

	git clone $MALI_BLOB_REPO --depth=1 -b $MALI_BLOB_BRANCH $MALI_BLOB_DIR

	if [ ! -d $MALI_BLOB_LIB_DIR ] ; then
		echo "ERROR: Mali library directory not found!"
		exit 1
	fi

	# For fbdev we store binaries under /opt/mali directory
	if [ $MALI_BLOB_TYPE = fbdev ] ; then
		MALI_BLOB_PREFIX="/opt/mali"
		MALI_BLOB_PREFIX_LIB=${MALI_BLOB_PREFIX}/lib
	else
		MALI_BLOB_PREFIX="/usr"
		MALI_BLOB_PREFIX_LIB=${MALI_BLOB_PREFIX}/lib/${LINUX_PLATFORM}
	fi
	MALI_BLOB_PREFIX_INC=${MALI_BLOB_PREFIX}/include

	mkdir -p ${R}${MALI_BLOB_PREFIX_INC}
	mkdir -p ${R}${MALI_BLOB_PREFIX_LIB}
	mkdir -p ${SYSROOT_DIR}${MALI_BLOB_PREFIX_INC}
	mkdir -p ${SYSROOT_DIR}${MALI_BLOB_PREFIX_LIB}


	if [ $MALI_BLOB_TYPE = wayland ] ; then
		# make sure that gbm library won't be overwritten by update

#		chroot_exec dpkg-divert --divert $MALI_BLOB_PREFIX/lib/libEGL.so.orig --rename --add $MALI_BLOB_PREFIX/lib/libEGL.so
#		chroot_exec dpkg-divert --divert $MALI_BLOB_PREFIX/lib/libEGL.so.1.orig --rename --add $MALI_BLOB_PREFIX/lib/libEGL.so.1
#		chroot_exec dpkg-divert --divert $MALI_BLOB_PREFIX/lib/libGLESv2.so.orig --rename --add $MALI_BLOB_PREFIX/lib/libGLESv2.so
#		chroot_exec dpkg-divert --divert $MALI_BLOB_PREFIX/lib/libGLESv2.so.2.orig --rename --add $MALI_BLOB_PREFIX/lib/libGLESv2.so.2

		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libgbm.so.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/libgbm.so
		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libgbm.so.1.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/libgbm.so.1

		if [ -f ${MALI_BLOB_PREFIX_LIB}/libwayland-egl.so ] ; then
			chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libwayland-egl.so.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/libwayland-egl.so
		fi
	fi

	rsync -az ${MALI_BLOB_INC_DIR}/* ${R}${MALI_BLOB_PREFIX_INC}
	rsync -az ${MALI_BLOB_INC_DIR}/* ${SYSROOT_DIR}${MALI_BLOB_PREFIX_INC}

	rsync -az ${MALI_BLOB_LIB_DIR}/lib* ${R}${MALI_BLOB_PREFIX_LIB}
	rsync -az ${MALI_BLOB_LIB_DIR}/lib* ${SYSROOT_DIR}${MALI_BLOB_PREFIX_LIB}

	${LIBDIR}/make-relativelinks.sh	$SYSROOT_DIR

	echo "Done."
}

# Check if GPU is supported by the board
if [[ $SOC_GPU == mali4* ]] ; then

    mali_blobs_deploy
else
    echo "Skip deploying Mali binaries."
fi
