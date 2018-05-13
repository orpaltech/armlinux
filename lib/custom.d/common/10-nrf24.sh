#
# Build kernel module for NRF24-family tranceiver
#

NRF24_URL=https://github.com/sergey-suloev/nrf24.git
NRF24_BRANCH="master"
NORDIC_DIR=$EXTRADIR/drivers/nordic
NRF24_DIR=$NORDIC_DIR/nrf24

# ----------------------------------------------------------------------------

nrf24_get_source()
{
        mkdir -p $NORDIC_DIR

        echo "Prepare Nrf24 sources..."

        rm -rf $NRF24_DIR
        # clone sources
        git clone $NRF24_URL -b $NRF24_BRANCH --depth=1 $NRF24_DIR

        echo "Done."
}

# ----------------------------------------------------------------------------

nrf24_make_kmod()
{
	echo "Building Nrf24 kernel module..."

	cd ${NRF24_DIR}

	export ARCH=${KERNEL_ARCH}
        export CROSS_COMPILE=${CROSS_COMPILE}
        export KERNEL_DIR=${KERNELSRC_DIR}
        export PWD=$(pwd)
        export INSTALL_MOD_PATH=${R}

        make
        make install

        echo "Build finished."
}

# ----------------------------------------------------------------------------

nrf24_get_source

nrf24_make_kmod
