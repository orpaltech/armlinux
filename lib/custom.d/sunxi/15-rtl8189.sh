#
# Build RTL8189 ethernet card module (sunxi)
#

RTL8189_URL=https://github.com/jwrdegoede/rtl8189ES_linux.git
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

        echo "Prepare rtl8189 sources..."

        rm -rf $RTL8189_DIR
        # clone sources
        git clone $RTL8189_URL -b $RTL8189_BRANCH --depth=1 $RTL8189_DIR

        echo "Done."
}

rtl8189_make()
{
	echo "Building rtl8189 kernel module..."

        cd $RTL8189_DIR

        ARCH="${KERNEL_ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" KSRC="${KERNELSRC_DIR}" make

	MODDESTDIR=${R}/lib/modules/${KERNEL_VERSION}/extra
	mkdir -p $MODDESTDIR

	# install target is broken in the supplied Makefile, let's do it ourselves
	install_readonly "${RTL8189_DIR}/${RTL8189_MOD}.ko" "${MODDESTDIR}/${RTL8189_MOD}.ko"
	chroot_exec /sbin/depmod -a $KERNEL_VERSION

        echo "Build finished."
}

#----------------------------------------------------------------------------

if [ "${ENABLE_WIRELESS}" = yes ] ; then

  if [[ $KERNEL_MODULES =~ .*8189fs.* ]] ; then
    RTL8189_BRANCH="rtl8189fs"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189FS"
    RTL8189_MOD="8189fs"

  elif [[ $KERNEL_MODULES =~ .*8189es.* ]] ; then
    RTL8189_BRANCH="master"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189ES"
    RTL8189_MOD="8189es"
  fi

  if [ ! -z "${RTL8189_BRANCH}" ] ; then
    rtl8189_get_src
    rtl8189_make
  fi
fi

#----------------------------------------------------------------------------
