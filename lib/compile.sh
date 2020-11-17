#!/bin/bash

########################################################################
# compile.sh
#
# Description:	U-Boot, Firmware and Kernel compilation script
#		for ORPALTECH ARMLINUX build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2020 ORPAL Technology, Inc.
#
########################################################################


NUM_CPU_CORES=$CPUINFO_NUM_CORES

[[ "${KBUILD_VERBOSE}" = "yes" ]] && KERNEL_V="V=1"

#-----------------------------------------------------------------------

compile_uboot()
{
        display_alert "Make u-boot" "${UBOOT_REPO_TAG:=\"${UBOOT_REPO_BRANCH}\"}" "info"

	export ARCH="${UBOOT_ARCH}"
	export CROSS_COMPILE="${UBOOT_CROSS_COMPILE}"
	export USE_PRIVATE_LIBGCC="yes"

        cd $UBOOT_SOURCE_DIR

	if [[ $CLEAN =~ (^|,)"uboot"(,|$) ]] ; then
		echo "Clean u-boot directory"
		make mrproper
	fi

	local CONFIG_BASE_DIR="${BASEDIR}/config/u-boot/${CONFIG}"
	local CONFIG_DIR="${CONFIG_BASE_DIR}/${UBOOT_REPO_NAME}"
	local USER_CONFIG="${CONFIG_DIR}/${UBOOT_RELEASE}/${UBOOT_USER_CONFIG}"
	if [ -f $USER_CONFIG ] ; then
		cp $USER_CONFIG "${UBOOT_SOURCE_DIR}/.config"
		make olddefconfig
	else
		make $UBOOT_CONFIG
	fi
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

#-----------------------------------------------------------------------

compile_kernel()
{
	display_alert "Make kernel" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_TAG:=${KERNEL_REPO_BRANCH}}" "info"

	export ARCH="${SOC_ARCH}"
	export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"
	export LOCALVERSION="-${SOC_FAMILY}"

	cd $KERNEL_SOURCE_DIR

	if [[ $CLEAN =~ (^|,)"kernel"(,|$) ]] ; then
		echo "Clean kernel directory"
		make mrproper
	fi

	local CONFIG_BASE_DIR="${BASEDIR}/config/kernel/${CONFIG}"
	local CONFIG_DIR="${CONFIG_BASE_DIR}/${KERNEL_REPO_NAME}"

	local USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f $USER_CONFIG  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_FAMILY_CONFIG}"
	[[ -f $USER_CONFIG  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f $USER_CONFIG  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_FAMILY_CONFIG}"

	if [ -f $USER_CONFIG ] ; then
		echo "Selected user-provided config file: ${USER_CONFIG}"
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

#-----------------------------------------------------------------------

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLATFORM}" "info"

	export CROSS_COMPILE="${UBOOT_CROSS_COMPILE}"

	case $SOC_PLATFORM in
    	    sun50i*)
		echo "*** ARM trusted firmware ***"
		cd $FIRMWARE_SOURCE_DIR

		if [[ $CLEAN =~ (^|,)"firmware"(,|$) ]] ; then
			echo "Clean firmware directory"
			make clean
			rm -rf ./build/${FIRMWARE_PLATFORM}/*
		fi

        	make PLAT="${FIRMWARE_PLATFORM}" DEBUG=1 bl31
		cp ./build/${FIRMWARE_PLATFORM}/debug/bl31.bin $UBOOT_SOURCE_DIR/
		SUNXI_ATF_USED="yes"
    	  	;;
	    bcm283*)
		echo "*** RaspberryPi is using prebuilt firmware ***"
		;;
	esac

	echo "Done."
}
