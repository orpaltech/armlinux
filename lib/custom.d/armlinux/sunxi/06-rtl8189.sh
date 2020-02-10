#
# Build kernel module for RTL8189-series Ethernet adapter (sunxi)
#

RTL8189_URL="https://github.com/jwrdegoede/rtl8189ES_linux.git"
# Will be selected later on
RTL8189_BRANCH=""

REALTEK_DIR=$EXTRADIR/drivers/realtek
# Will be selected later on
RTL8189_DIR=""
RTL8189_MOD=""

#----------------------------------------------------------------------------

rtl8189_get_src()
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
	export CROSS_COMPILE="${CROSS_COMPILE}"
	export KSRC="${KERNEL_SOURCE_DIR}"

	make
	[ $? -eq 0 ] || exit $?;

	MODDESTDIR=${R}/lib/modules/${KERNEL_VERSION}/extra
	mkdir -p $MODDESTDIR

	# install target is broken in the supplied Makefile, let's do it ourselves
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
    rtl8189_get_src
    rtl8189_make
  else
    echo "Skip."
  fi
fi
