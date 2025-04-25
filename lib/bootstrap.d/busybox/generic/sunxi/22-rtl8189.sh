#
# Build kernel module for RTL8189-series Ethernet adapter (sunxi)
#

RTL8189_REPO_URL="https://github.com/jwrdegoede/rtl8189ES_linux.git"

REALTEK_DIR=${EXTRADIR}/drivers/realtek

# Will be selected later on
RTL8189_BRANCH=
RTL8189_DIR=
RTL8189_MOD=

SOURCE_NAME=$(basename ${BASH_SOURCE[0]})

#
# ############ helper functions ##############
#

rtl8189_install()
{
	mkdir -p ${REALTEK_DIR}

        display_alert "Prepare rtl8189 sources..." "${RTL8189_REPO_URL} | ${RTL8189_BRANCH}" "info"

        rm -rf ${RTL8189_DIR}

	# clone sources
	${GIT} clone ${RTL8189_REPO_URL} -b ${RTL8189_BRANCH} --depth=1 ${RTL8189_DIR}
	[ $? -eq 0 ] || exit $?;

	display_alert "Sources ready" "${RTL8189_REPO_URL} | ${RTL8189_BRANCH}" "info"

	echo "${SOURCE_NAME}: Building rtl8189 kernel driver..."

        cd ${RTL8189_DIR}/

set -x
        export ARCH="${KERNEL_ARCH}"
	# always use kernel toolchain to compile drivers
	export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"
	export KSRC="${KERNEL_SOURCE_DIR}"
	export CONFIG_RTW_LOG_LEVEL=2
set +x

	chrt -i 0 make  -s -j${HOST_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	MOD_DESTDIR=${R}/lib/modules/${KERNEL_VERSION}/extra
	mkdir -p ${MOD_DESTDIR}

	# install is broken in supplied Makefile, let's install manually
	install_readonly "${RTL8189_DIR}/${RTL8189_MOD}.ko"	${MOD_DESTDIR}/
	chroot_exec /sbin/depmod -a ${KERNEL_VERSION}

        echo "${SOURCE_NAME}: Build finished."

	unset ARCH KSRC CROSS_COMPILE
}

#
# ############# install modules ##############
#

if [ "${ENABLE_WLAN}" = yes ] ; then

  RTL8189_BRANCH=

  if [[ ${KERNEL_MODULES} =~ (^|,)"8189fs"(,|$) ]] ; then
    RTL8189_BRANCH="rtl8189fs"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189FS"
    RTL8189_MOD="8189fs"

  elif [[ ${KERNEL_MODULES} =~ (^|,)"8189es"(,|$) ]] ; then
    RTL8189_BRANCH="master"
    RTL8189_DIR="${REALTEK_DIR}/rtl8189ES"
    RTL8189_MOD="8189es"
  fi

  if [ -n "${RTL8189_MOD}" ] ; then

    rtl8189_install
  else

    echo "Skip."
  fi
fi
