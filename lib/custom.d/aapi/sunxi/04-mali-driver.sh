#
# Mali GPU Kernel module (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_DRV_SRC="${SUNXI_DIR}/sunxi-mali"
MALI_DRV_URL="https://github.com/mripard/sunxi-mali.git"
# MALI_DRV_URL="https://github.com/sergey-suloev/sunxi-mali.git"
MALI_DRV_BRANCH="master"
MALI_DRV_VER="r6p2"
# MALI_DRV_BUILD="debug"


mali_driver_update()
{
	mkdir -p $SUNXI_DIR

        display_alert "Updating Mali driver sources..." "${MALI_DRV_URL} | ${MALI_DRV_BRANCH}" "info"

        rm -rf $MALI_DRV_SRC

        # clone sources
        git clone $MALI_DRV_URL --depth=1 -b $MALI_DRV_BRANCH  $MALI_DRV_SRC

        echo "Done."
}

mali_driver_build()
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

# check if GPU is supported by the board
if [[ $SOC_GPU == mali4* ]] ; then

	if [ "${MALI_BLOB_TYPE}" = "lima" ] ; then
		echo "Skip building out-of-tree ARM Mali GPU driver in favour of LIMA"
	else
		mali_driver_update

		mali_driver_build
	fi
else
    echo "Skip building Mali GPU driver."
fi
