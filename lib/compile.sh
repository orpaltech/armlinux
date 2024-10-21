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
# Copyright (C) 2013-2022 ORPAL Technology, Inc.
#
########################################################################


# Use only half of availables CPUs
HOST_CPU_CORES=$((CPUINFO_NUM_CORES / 2))

[[ "${KERNEL_VERBOSE}" = yes ]] && KERNEL_V_OPTION="V=1"
[[ -z "${KERNEL_DEB_COMPRESS}" ]] && KERNEL_DEB_COMPRESS="none"

. ${LIBDIR}/sources-update.sh
. ${LIBDIR}/sources-patch.sh

COMPILE_SCRIPT="${LIBDIR}/compile-${SOC_FAMILY}.sh"
if [ -f "${COMPILE_SCRIPT}" ] ; then
. ${COMPILE_SCRIPT}
else
  echo "error: compile script not found for ${SOC_FAMILY}!"
  exit 1
fi


compile_bootloader()
{
if [ "${BOOTLOADER}" = uboot ] ; then
        display_alert "Make u-boot" "${UBOOT_REPO_TAG:=\"${UBOOT_REPO_BRANCH}\"}" "info"

	display_alert "Selected toolchain:" "${UBOOT_CROSS_COMPILE}gcc" "ext"

	export ARCH="${UBOOT_ARCH}"
	export CROSS_COMPILE="${UBOOT_CROSS_COMPILE}"
	export USE_PRIVATE_LIBGCC="yes"

        cd ${UBOOT_SOURCE_DIR}

	if [[ ${CLEAN} =~ (^|,)bootloader(,|$) ]] ; then
		echo "Clean u-boot directory"
		make mrproper
	fi

	local CONFIG_BASE_DIR="${BASEDIR}/config/u-boot/${CONFIG}"
	local CONFIG_DIR="${CONFIG_BASE_DIR}/${UBOOT_REPO_NAME}"
	local USER_CONFIG="${CONFIG_DIR}/${UBOOT_RELEASE}/${UBOOT_USER_CONFIG}"
	if [ -f ${USER_CONFIG} ] ; then
		echo "Selected user-provided config file: ${USER_CONFIG}"
		cp ${USER_CONFIG} "${UBOOT_SOURCE_DIR}/.config"
		make olddefconfig
	else
		echo "Selected config file: ${UBOOT_CONFIG}"
		make ${UBOOT_CONFIG}
	fi
	[ $? -eq 0 ] || exit $?;


        chrt -i 0 make -j${HOST_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	# Concatenate u-boot outputs for sunxi boards with ATF
	if [[ ${SOC_FAMILY} =~ ^sun([0-9]+|x)i$ ]] && [[ "${SUNXI_ATF_USED}" = yes ]] && [[ ! -f ${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin ]] ; then
		cat ${UBOOT_SOURCE_DIR}/spl/sunxi-spl.bin ${UBOOT_SOURCE_DIR}/u-boot.itb > "${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
		echo "Created binary ${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
	fi

	echo "Done."
fi
}

compile_kernel()
{
	display_alert "Make kernel" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_TAG:=${KERNEL_REPO_BRANCH}}" "info"

	display_alert "Selected toolchain:" "${KERNEL_CROSS_COMPILE}gcc" "ext"

	cd ${KERNEL_SOURCE_DIR}

	if [[ ${CLEAN} =~ (^|,)kernel(,|$) ]] ; then
		echo "Clean kernel directory"
		make mrproper
	fi

	local CONFIG_BASE_DIR="${BASEDIR}/config/kernel/${CONFIG}"
	local CONFIG_DIR="${CONFIG_BASE_DIR}/${KERNEL_REPO_NAME}"

	local USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_FAMILY_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_FAMILY_CONFIG}"

	export ARCH="${SOC_ARCH}"
	export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"
	export LOCALVERSION="-${SOC_FAMILY}"

	if [ -f ${USER_CONFIG} ] ; then
		echo "Selected user-provided config file: ${USER_CONFIG}"
		cp ${USER_CONFIG} "${KERNEL_SOURCE_DIR}/.config"
		make olddefconfig
        else
		make ${KERNEL_BUILD_CONFIG}
	fi
	[ $? -eq 0 ] || exit $?;

	chrt -i 0 make -j${HOST_CPU_CORES} \
		${KERNEL_V_OPTION}
	[ $? -eq 0 ] || exit $?;


	# read kernel release version
	KERNEL_VERSION=$(cat "${KERNEL_SOURCE_DIR}/include/config/kernel.release")
	KERNEL_DEB_PKG_VER="${FULL_VERSION}-${CONFIG}-${KERNEL_VERSION}-${KERNEL_REPO_NAME}"

	echo "Create Kernel DEB-packages..."

	export KDEB_SOURCENAME="linux-${KERNEL_REPO_NAME}"
	export KDEB_PKGVERSION=${KERNEL_DEB_PKG_VER}
	export KDEB_COMPRESS=${KERNEL_DEB_COMPRESS}
	export KBUILD_DEBARCH=${DEBIAN_RELEASE_ARCH}
	export DEBFULLNAME=${MAINTAINER_NAME}
	export DEBEMAIL=${MAINTAINER_EMAIL}

	chrt -i 0 make -j${HOST_CPU_CORES} bindeb-pkg
	[ $? -eq 0 ] || exit $?;

	rsync --remove-source-files -rq ../*.deb "${OUTPUTDIR}/debs/"
	[ $? -eq 0 ] || exit $?;

	# save kernel build config
	cp ${KERNEL_SOURCE_DIR}/.config	${KERNEL_DEB_PKG_VER}.config

	echo "Done."
}
