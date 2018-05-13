#
# Build Mali Utgard GPU Kernel module (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_MOD_SRC="${SUNXI_DIR}/sunxi-mali"
MALI_MOD_URL="https://github.com/mripard/sunxi-mali.git"
MALI_MOD_BRANCH="master"
MALI_MOD_VERSION="r6p2"

MALI_BLOB_SRC="${SUNXI_DIR}/mali-blobs"
MALI_BLOB_URL="https://github.com/free-electrons/mali-blobs.git"
MALI_BLOB_BRANCH="master"


get_mali_source()
{
	mkdir -p $SUNXI_DIR

        echo "Prepare Mali Utgard GPU sources..."

        rm -rf $MALI_MOD_SRC
	rm -rf $MALI_BLOB_SRC

        # clone sources
        git clone $MALI_MOD_URL  --depth=1 -b $MALI_MOD_BRANCH  $MALI_MOD_SRC
        git clone $MALI_BLOB_URL --depth=1 -b $MALI_BLOB_BRANCH $MALI_BLOB_SRC

        echo "Done."
}

build_mali_kmod()
{
        cd $MALI_MOD_SRC

        echo "Building Mali Utgard kernel module..."

        export CROSS_COMPILE="${CROSS_COMPILE}"
        export KDIR="${KERNELSRC_DIR}"
        export INSTALL_MOD_PATH="${R}"

        $MALI_MOD_SRC/build.sh -r $MALI_MOD_VERSION -j $NUM_CPU_CORES -b
        $MALI_MOD_SRC/build.sh -r $MALI_MOD_VERSION -i

        echo "Build finished."
}

deploy_mali_blob()
{
	echo "Deploy Mali Utgard userspace libs & headers..."

	local MALI_INC="${R}/opt/mali/include"
	local MALI_LIB="${R}/opt/mali/lib"
	mkdir -p $MALI_INC
	mkdir -p $MALI_LIB

	cp -a $MALI_BLOB_SRC/r6p2/fbdev/lib/lib_fb_dev/lib*	$MALI_LIB/
	cp -a $MALI_BLOB_SRC/r6p2/fbdev/include/*		$MALI_INC/

	echo "Done."
}

# Check if GPU is supported by the driver
if [[ $SOC_GPU == Mali4* ]] && [ $SOC_ARCH = arm ] ; then

	# TODO: only support 32bit platforms currently
	get_mali_source

	build_mali_kmod

	deploy_mali_blob
else
    echo "Skip building Mali driver."
fi
