#
# Deploy Mali userspace binaries (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_BLOB_DIR="${SUNXI_DIR}/bootlin-mali-blobs"
MALI_BLOB_REPO="https://github.com/bootlin/mali-blobs.git"
MALI_BLOB_BRANCH="master"

MALI_BLOB_INC_DIR="${MALI_BLOB_DIR}/include/${MALI_BLOB_TYPE}"
MALI_BLOB_LIB_DIR="${MALI_BLOB_DIR}/${MALI_DRV_VER}/${SOC_ARCH}/${MALI_BLOB_TYPE}"


mali_blobs_deploy()
{
	rm -rf $MALI_BLOB_DIR

	git clone $MALI_BLOB_REPO --depth=1 -b $MALI_BLOB_BRANCH $MALI_BLOB_DIR

	if [ ! -d $MALI_BLOB_LIB_DIR ] ; then
		echo "ERROR: Mali library directory not found!"
		exit 1
	fi

	# For fbdev we store binaries under /opt/mali directory
	if [ "${MALI_BLOB_TYPE}" = fbdev ] ; then
		MALI_BLOB_PREFIX_INC=/opt/mali/include
		MALI_BLOB_PREFIX_LIB=/opt/mali/lib


		mkdir -p ${R}${MALI_BLOB_PREFIX_INC}
		mkdir -p ${R}${MALI_BLOB_PREFIX_LIB}
		mkdir -p ${SYSROOT_DIR}${MALI_BLOB_PREFIX_INC}
		mkdir -p ${SYSROOT_DIR}${MALI_BLOB_PREFIX_LIB}

	elif [ "${MALI_BLOB_TYPE}" = wayland ] ; then
		MALI_BLOB_PREFIX_INC=/usr/include
		MALI_BLOB_PREFIX_LIB=/usr/lib/${LINUX_PLATFORM}

		# make sure that gbm library won't be overwritten by update

#		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libEGL.so.orig --rename --add $MALI_BLOB_PREFIX_LIB/libEGL.so
#		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libEGL.so.1.orig --rename --add $MALI_BLOB_PREFIX_LIB/libEGL.so.1
#		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libGLESv2.so.orig --rename --add $MALI_BLOB_PREFIX_LIB/libGLESv2.so
#		chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libGLESv2.so.2.orig --rename --add $MALI_BLOB_PREFIX_LIB/libGLESv2.so.2

		if [ -f ${R}${MALI_BLOB_PREFIX_LIB}/pkgconfig/gbm.pc ] ; then
			chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libgbm.so.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/libgbm.so
			chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/libgbm.so.1.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/libgbm.so.1
		fi

		#chroot_exec dpkg-divert --divert ${MALI_BLOB_PREFIX_LIB}/${LINUX_PLATFORM}/libwayland-egl.so.orig --rename --add ${MALI_BLOB_PREFIX_LIB}/${LINUX_PLATFORM}/libwayland-egl.so

	fi

	echo "Deploy Mali userspace binaries..."

	rsync -az ${MALI_BLOB_INC_DIR}/* ${R}${MALI_BLOB_PREFIX_INC}
	rsync -az ${MALI_BLOB_INC_DIR}/* ${SYSROOT_DIR}${MALI_BLOB_PREFIX_INC}

	rsync -az ${MALI_BLOB_LIB_DIR}/lib* ${R}${MALI_BLOB_PREFIX_LIB}
	rsync -az ${MALI_BLOB_LIB_DIR}/lib* ${SYSROOT_DIR}${MALI_BLOB_PREFIX_LIB}

	${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}

	echo "Done."
}

# Check if GPU is supported by the board
if [[ $SOC_GPU == mali4* ]] ; then

	if [ "${MALI_BLOB_TYPE}" = "lima" ] ; then
		echo "Skip deploying Mali userspace blob/headers in favor of MESA LIMA"
        else
		if [ -z "${MALI_DRV_VER}" ] ; then
			echo "WARNING: Skip deploying Mali userspace blob/headers: missing Mali driver version"
		elif [ -z "${MALI_BLOB_TYPE}" ] ; then
			echo "WARNING: Skip deploying Mali userspace blob/headers: missing Mali blob type"
		else
			mali_blobs_deploy
		fi
	fi
else
	echo "Skip deploying Mali userspace blob/headers"
fi
