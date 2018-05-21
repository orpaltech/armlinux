#!/bin/bash

#-----------------------------------------------------------------------------------

NUM_CPU_CORES=$(grep -c ^processor /proc/cpuinfo)

[[ "${KBUILD_VERBOSE}" = "yes" ]] && KERNEL_V="V=1"

#-----------------------------------------------------------------------------------

compile_uboot()
{
        display_alert "Make u-boot" "${UBOOT_REPO_TAG:=\"${UBOOT_REPO_BRANCH}\"} | ${SOC_ARCH}" "info"

        export USE_PRIVATE_LIBGCC="yes"
	export ARCH="${SOC_ARCH}"
	export CROSS_COMPILE="${CROSS_COMPILE}"

        cd $UBOOT_SOURCE_DIR

	if [[ $CLEAN_OPTIONS =~ (^|,)"uboot"(,|$) ]] ; then
		echo "Clean u-boot directory"
		make clean
	fi

        make $UBOOT_CONFIG
	[ $? -eq 0 ] || exit $?;

        chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	# Concatenate u-boot outputs for sunxi boards with ATF
	if [[ $SOC_FAMILY =~ ^sun([0-9]+|x)i$ ]] && [[ "${SUNXI_ATF_USED}" = "yes" ]] ; then
		cat $UBOOT_SOURCE_DIR/spl/sunxi-spl.bin $UBOOT_SOURCE_DIR/u-boot.itb > "${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
		echo "Created binary ${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
	fi

	echo "Done."
}

#-----------------------------------------------------------------------------------

compile_kernel()
{
	display_alert "Make kernel" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_TAG:=${KERNEL_REPO_BRANCH}} | ${SOC_ARCH}" "info"

	export ARCH="${SOC_ARCH}"
	export CROSS_COMPILE="${CROSS_COMPILE}"
	export LOCALVERSION="-${SOC_FAMILY}"

	cd $KERNEL_SOURCE_DIR

	if [[ $CLEAN_OPTIONS =~ (^|,)"kernel"(,|$) ]] ; then
		echo "Clean kernel directory"
		make mrproper
	fi

	local USER_CONFIG="${BASEDIR}/config/kernel/${KERNEL_BUILD_USER_CONFIG}"

	if [ -f $USER_CONFIG ] ; then
		cp $USER_CONFIG "${KERNEL_SOURCE_DIR}/.config"
		make olddefconfig $KERNEL_V
        else
		make $KERNEL_BUILD_CONFIG $KERNEL_V
	fi
	[ $? -eq 0 ] || exit $?;

	chrt -i 0 make -j${NUM_CPU_CORES} $KERNEL_V
	[ $? -eq 0 ] || exit $?;

	# read kernel release version
	KERNEL_VERSION=$(cat "${KERNEL_SOURCE_DIR}/include/config/kernel.release")

	echo "Done."
}

#-----------------------------------------------------------------------------------

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLAT}" "info"

	case $SOC_PLAT in
    	    sun50i*)
		echo "*** ARM trusted firmware ***"
		cd $FIRMWARE_SOURCE_DIR
        	CROSS_COMPILE="${CROSS_COMPILE}" make PLAT="${SOC_PLAT}" DEBUG=1 bl31
		cp "${FIRMWARE_SOURCE_DIR}/build/${SOC_PLAT}/debug/bl31.bin" $UBOOT_SOURCE_DIR/
		SUNXI_ATF_USED="yes"
    	  	;;
	esac

	echo "Done."
}

#-----------------------------------------------------------------------------------

