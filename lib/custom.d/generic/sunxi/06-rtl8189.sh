#
# Build kernel module for RTL8189-series Ethernet adapter (sunxi)
#

RTL8189_URL="https://github.com/jwrdegoede/rtl8189ES_linux.git"

REALTEK_DIR=$EXTRADIR/drivers/realtek

# Will be selected later on
RTL8189_BRANCH=
RTL8189_DIR=
RTL8189_MOD=

#----------------------------------------------------------------------------

rtl8189_get()
{
	mkdir -p $REALTEK_DIR

        display_alert "Prepare rtl8189 sources..." "${RTL8189_URL} | ${RTL8189_BRANCH}" "info"

        rm -rf $RTL8189_DIR

        # clone sources
        git clone $RTL8189_URL -b $RTL8189_BRANCH --depth=1 $RTL8189_DIR
	[ $? -eq 0 ] || exit $?;

        echo "Done."
}

rtl8189_make()
{
	echo "Building rtl8189 kernel driver..."

        cd $RTL8189_DIR

        export ARCH="${KERNEL_ARCH}"
	# always use kernel toolchain to compile drivers
	export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"
	export KSRC="${KERNEL_SOURCE_DIR}"

	make
	[ $? -eq 0 ] || exit $?;

	MODDESTDIR=${R}/lib/modules/${KERNEL_VERSION}/extra
	mkdir -p $MODDESTDIR

	# install is broken in supplied Makefile, let's install manually
	install_readonly "${RTL8189_DIR}/${RTL8189_MOD}.ko" "${MODDESTDIR}/${RTL8189_MOD}.ko"
	chroot_exec /sbin/depmod -a $KERNEL_VERSION

        echo "Build finished."
}

#----------------------------------------------------------------------------

if [ "${ENABLE_WLAN}" = yes ] ; then

  RTL8189_BRANCH=

  if [[ $KERNEL_MODULES =~ (^|,)"8189fs"(,|$) ]] ; then
    RTL8189_BRANCH="rtl8189fs"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189FS"
    RTL8189_MOD="8189fs"

  elif [[ $KERNEL_MODULES =~ (^|,)"8189es"(,|$) ]] ; then
    RTL8189_BRANCH="master"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189ES"
    RTL8189_MOD="8189es"
  fi

  if [ ! -z "${RTL8189_BRANCH}" ] ; then
    rtl8189_get
    rtl8189_make
  else
    echo "Skip."
  fi
fi
