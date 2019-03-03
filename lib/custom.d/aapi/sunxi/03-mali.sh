#
# Build Mali Utgard GPU Kernel module (sunxi)
#

SUNXI_DIR="${EXTRADIR}/drivers/sunxi"

MALI_DRV_SRC="${SUNXI_DIR}/sunxi-mali"
MALI_DRV_URL="https://github.com/mripard/sunxi-mali.git"
# MALI_DRV_URL="https://github.com/sergey-suloev/sunxi-mali.git"
MALI_DRV_BRANCH="master"
MALI_DRV_VER="r6p2"
# MALI_DRV_BUILD="debug"


mali_update()
{
	mkdir -p $SUNXI_DIR

        display_alert "Updating Mali driver sources..." "${MALI_DRV_URL} | ${MALI_DRV_BRANCH}" "info"

        rm -rf $MALI_DRV_SRC

        # clone sources
        git clone $MALI_DRV_URL --depth=1 -b $MALI_DRV_BRANCH  $MALI_DRV_SRC

        echo "Done."
}

mali_build()
{
        cd $MALI_DRV_SRC

        echo "Building Mali kernel driver..."

        export CROSS_COMPILE="${CROSS_COMPILE}"
        export KDIR="${KERNEL_SOURCE_DIR}"
        export INSTALL_MOD_PATH="${R}"

#        $MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -m $MALI_DRV_BUILD -j $NUM_CPU_CORES -b
#        $MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -m $MALI_DRV_BUILD -i
	$MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -j $NUM_CPU_CORES -b
	$MALI_DRV_SRC/build.sh -r $MALI_DRV_VER -i

        echo "Build finished."
}

# Check if GPU is supported by the board
if [[ $SOC_GPU == mali4* ]] ; then
	mali_update

	mali_build
else
    echo "Skip building Mali driver."
fi
