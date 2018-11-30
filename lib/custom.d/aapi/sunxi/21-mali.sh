#
# Build Mali Utgard GPU Kernel module (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_DRV_SRC="${SUNXI_DIR}/sunxi-mali"
MALI_DRV_URL="https://github.com/mripard/sunxi-mali.git"
MALI_DRV_BRANCH="master"
MALI_DRV_VER="r6p2"

MALI_BLOB_SRC="${SUNXI_DIR}/mali-blobs"
MALI_BLOB_REPO="https://github.com/orpaltech/mali-blobs.git"
MALI_BLOB_BRANCH="master"


get_mali_source()
{
	mkdir -p $SUNXI_DIR

        display_alert "Updating Mali driver sources..." "${MALI_DRV_URL} | ${MALI_DRV_BRANCH}" "info"

        rm -rf $MALI_DRV_SRC

        # clone sources
        git clone $MALI_DRV_URL --depth=1 -b $MALI_DRV_BRANCH  $MALI_DRV_SRC

        echo "Done."
}

build_mali_kmod()
{
        cd $MALI_DRV_SRC

        echo "Building Mali kernel driver..."

        export CROSS_COMPILE="${CROSS_COMPILE}"
        export KDIR="${KERNEL_SOURCE_DIR}"
        export INSTALL_MOD_PATH="${R}"

        $MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -j $NUM_CPU_CORES -b
        $MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -i

        echo "Build finished."
}

deploy_mali_blob()
{
	echo "Deploying Mali userspace library..."

	rm -rf $MALI_BLOB_SRC

	git clone $MALI_BLOB_REPO --depth=1 -b $MALI_BLOB_BRANCH $MALI_BLOB_SRC

	local BLOB_PREFIX="/usr/lib/${LINUX_PLATFORM}"

	# make sure that gbm library won't be overwritten by update
	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libEGL.so.orig --rename --add $BLOB_PREFIX/libEGL.so
	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libEGL.so.1.orig --rename --add $BLOB_PREFIX/libEGL.so.1
	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libGLESv2.so.orig --rename --add $BLOB_PREFIX/libGLESv2.so
	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libGLESv2.so.2.orig --rename --add $BLOB_PREFIX/libGLESv2.so.2

	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libgbm.so.orig --rename --add $BLOB_PREFIX/libgbm.so
	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libgbm.so.1.orig --rename --add $BLOB_PREFIX/libgbm.so.1

	chroot_exec dpkg-divert --divert $BLOB_PREFIX/libwayland-egl.so.orig --rename --add $BLOB_PREFIX/libwayland-egl.so


	rsync -az $MALI_BLOB_SRC/$SOC_GPU/$MALI_DRV_VER/wayland/lib/$LINUX_PLATFORM/lib* ${R}${BLOB_PREFIX}
	rsync -az $MALI_BLOB_SRC/$SOC_GPU/$MALI_DRV_VER/wayland/lib/$LINUX_PLATFORM/lib* ${SYSROOT_DIR}${BLOB_PREFIX}

	${LIBDIR}/make-relativelinks.sh	${SYSROOT_DIR}${BLOB_PREFIX}

	echo "Done."
}

# Check if GPU is supported by the driver
if [[ $SOC_GPU == mali4* ]] ; then
	get_mali_source

	build_mali_kmod

	deploy_mali_blob
else
    echo "Skip building Mali driver."
fi
