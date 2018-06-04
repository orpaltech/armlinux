#
# Build Mali Utgard GPU Kernel module (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_DRV_SRC="${SUNXI_DIR}/sunxi-mali"
MALI_DRV_URL="https://github.com/mripard/sunxi-mali.git"
MALI_DRV_BRANCH=master
MALI_DRV_VER=r6p2

MALI_BLOB_SRC="${SUNXI_DIR}/mali-blobs"
MALI_BLOB_REPO="https://github.com/orpaltech/mali-blobs.git"
MALI_BLOB_BRANCH=master

get_mali_source()
{
	mkdir -p $SUNXI_DIR

        echo "Updating Mali driver sources..."

        rm -rf $MALI_DRV_SRC

        # clone sources
        git clone $MALI_DRV_URL --depth=1 -b $MALI_DRV_BRANCH  $MALI_DRV_SRC

        echo "Done."
}

build_mali_kmod()
{
        cd $MALI_DRV_SRC

        echo "Building Mali kernel module..."

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

	# make sure that gbm library won't be overwritten by update
	chroot_exec dpkg-divert --add --rename --divert /usr/lib/$LINUX_PLATFORM/libgbm.so.orig /usr/lib/$LINUX_PLATFORM/libgbm.so
	chroot_exec dpkg-divert --add --rename --divert /usr/lib/$LINUX_PLATFORM/libgbm.so.1.orig /usr/lib/$LINUX_PLATFORM/libgbm.so.1

	cp -a $MALI_BLOB_SRC/$SOC_GPU/$MALI_DRV_VER/wayland/lib/$LINUX_PLATFORM/lib* ${R}/usr/lib/$LINUX_PLATFORM/

#	if [ $SOC_ARCH = arm ] ; then
#		git clone "https://github.com/free-electrons/mali-blobs.git" \
#			--depth=1 -b master $MALI_BLOB_SRC
#
#		local MALI_INC="${R}/opt/mali/include"
#		local MALI_LIB="${R}/opt/mali/lib"
#
#		mkdir -p $MALI_INC
#		mkdir -p $MALI_LIB
#
#		cp -a $MALI_BLOB_SRC/r6p2/fbdev/include/* $MALI_INC/
#		cp -a $MALI_BLOB_SRC/r6p2/fbdev/lib/lib_fb_dev/lib* $MALI_LIB/
#	fi

	echo "Done."
}

# Check if GPU is supported by the driver
if [[ $SOC_GPU == mali4* ]] ; then

	# TODO: only support 32bit platforms currently
	get_mali_source

	build_mali_kmod

	deploy_mali_blob
else
    echo "Skip building Mali driver."
fi
