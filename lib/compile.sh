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
NUM_CPU_CORES=$((CPUINFO_NUM_CORES / 2))

[[ "${KERNEL_VERBOSE}" = yes ]] && KERNEL_V_OPTION="V=1"
[[ -z "${KERNEL_MAKE_DEB_PKG}" ]] && KERNEL_MAKE_DEB_PKG="yes"
[[ -z "${KERNEL_DEB_COMPRESS}" ]] && KERNEL_DEB_COMPRESS="none"

. ${LIBDIR}/sources-update.sh
. ${LIBDIR}/sources-patch.sh

COMPILE_SCRIPT="${LIBDIR}/compile-${SOC_FAMILY}.sh"
if [ -f "${COMPILE_SCRIPT}" ] ; then
. $COMPILE_SCRIPT
else
  echo "error: compile script not found for ${SOC_FAMILY}!"
  exit 1
fi

#-----------------------------------------------------------------------

compile_uboot()
{
if [ "${ENABLE_UBOOT}" = yes ] ; then
        display_alert "Make u-boot" "${UBOOT_REPO_TAG:=\"${UBOOT_REPO_BRANCH}\"}" "info"

	display_alert "Selected toolchain:" "${UBOOT_CROSS_COMPILE}gcc" "ext"

	export ARCH="${UBOOT_ARCH}"
	export CROSS_COMPILE="${UBOOT_CROSS_COMPILE}"
	export USE_PRIVATE_LIBGCC="yes"

        cd ${UBOOT_SOURCE_DIR}

	if [[ $CLEAN =~ (^|,)"uboot"(,|$) ]] ; then
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


        chrt -i 0 make -j${NUM_CPU_CORES}
	[ $? -eq 0 ] || exit $?;

	# Concatenate u-boot outputs for sunxi boards with ATF
	if [[ ${SOC_FAMILY} =~ ^sun([0-9]+|x)i$ ]] && [[ "${SUNXI_ATF_USED}" = yes ]] && [[ ! -f ${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin ]] ; then
		cat ${UBOOT_SOURCE_DIR}/spl/sunxi-spl.bin ${UBOOT_SOURCE_DIR}/u-boot.itb > "${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
		echo "Created binary ${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin"
	fi

	echo "Create U-Boot deb package..."

	# create directory structure for the .deb package
#	UBOOT_DEB_PKG_VER="${UBOOT_RELEASE}-${UBOOT_ARCH}"
#	UBOOT_NAME="${UBOOT_REPO_NAME}-${UBOOT_DEB_PKG_VER}-${VERSION}"
#	UBOOT_DEB_PKG="uboot-${UBOOT_NAME}"
#	UBOOT_DEB_DIR="${DEBS_DIR}/${UBOOT_DEB_PKG}-deb"

#	mkdir -p ${UBOOT_DEB_DIR}
#	rm -rf ${UBOOT_DEB_DIR}/*
#	mkdir -p ${UBOOT_DEB_DIR}/usr/lib/${UBOOT_NAME}
#	mkdir ${UBOOT_DEB_DIR}/DEBIAN

	#
	# TODO: create u-boot deb package
	#

	echo "[To be]Done."
fi
}

#-----------------------------------------------------------------------

compile_kernel()
{
	display_alert "Make kernel" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_TAG:=${KERNEL_REPO_BRANCH}}" "info"

	display_alert "Selected toolchain:" "${KERNEL_CROSS_COMPILE}gcc" "ext"

	export ARCH="${SOC_ARCH}"
	export CROSS_COMPILE="${KERNEL_CROSS_COMPILE}"
	export LOCALVERSION="-${SOC_FAMILY}"

	cd ${KERNEL_SOURCE_DIR}

	if [[ $CLEAN =~ (^|,)"kernel"(,|$) ]] ; then
		echo "Clean kernel directory"
		make mrproper
	fi

	local CONFIG_BASE_DIR="${BASEDIR}/config/kernel/${CONFIG}"
	local CONFIG_DIR="${CONFIG_BASE_DIR}/${KERNEL_REPO_NAME}"

	local USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_RELEASE}/${KERNEL_BUILD_FAMILY_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_BOARD_CONFIG}"
	[[ -f ${USER_CONFIG}  ]] || USER_CONFIG="${CONFIG_DIR}/${KERNEL_BUILD_FAMILY_CONFIG}"

	if [ -f ${USER_CONFIG} ] ; then
		echo "Selected user-provided config file: ${USER_CONFIG}"
		cp ${USER_CONFIG} "${KERNEL_SOURCE_DIR}/.config"
		make olddefconfig
        else
		make ${KERNEL_BUILD_CONFIG}
	fi
	[ $? -eq 0 ] || exit $?;

	chrt -i 0 make -j${NUM_CPU_CORES} \
		${KERNEL_V_OPTION}
	[ $? -eq 0 ] || exit $?;


	# read kernel release version
#	KERNEL_VERSION=$(make kernelversion)
	KERNEL_VERSION=$(cat "${KERNEL_SOURCE_DIR}/include/config/kernel.release")
	KERNEL_DEB_PKG_VER="${PROD_VERSION}-${CONFIG}-${KERNEL_VERSION}-${KERNEL_REPO_NAME}"

	if [ "${KERNEL_MAKE_DEB_PKG}" = yes ] ; then
		echo "Create Kernel DEB-packages..."

		# TODO: cleanup here
		#
		# create directory structure for the .deb package
	#	if [ -z "${KERNEL_REPO_TAG}" ] ; then
	#		KERNEL_DEB_PKG_VER="${KERNEL_REPO_TAG}-${KERNEL_ARCH}"
	#	else
	#		KERNEL_DEB_PKG_VER="${KERNEL_RELEASE}-${KERNEL_BRANCH}-${KERNEL_ARCH}"
	#	fi

	#	KERNEL_NAME="${KERNEL_REPO_NAME}-${KERNEL_DEB_PKG_VER}-${VERSION}"
	#	KERNEL_DEB_PKG="kernel-${KERNEL_NAME}"
	#	KERNEL_DEB_DIR="${DEBS_DIR}/${KERNEL_DEB_PKG}-deb"

	#	mkdir -p ${KERNEL_DEB_DIR}
	#	rm -rf ${KERNEL_DEB_DIR}/*
	#	mkdir -p ${KERNEL_DEB_DIR}/usr/lib/${UBOOT_NAME}
	#	mkdir ${KERNEL_DEB_DIR}/DEBIAN

#			KDEB_SOURCENAME="linux-${KERNEL_REPO_NAME}" \
#                        KDEB_PKGVERSION=${KERNEL_DEB_PKG_VER} \
#                        KDEB_COMPRESS=${KERNEL_DEB_COMPRESS} \
#                        KBUILD_DEBARCH=${DEBIAN_RELEASE_ARCH} \
#                        DEBFULLNAME=${MAINTAINER_NAME} \
#                        DEBEMAIL=${MAINTAINER_EMAIL}

		export KDEB_SOURCENAME="linux-${KERNEL_REPO_NAME}"
		export KDEB_PKGVERSION=${KERNEL_DEB_PKG_VER}
		export KDEB_COMPRESS=${KERNEL_DEB_COMPRESS}
		export KBUILD_DEBARCH=${DEBIAN_RELEASE_ARCH}
		export DEBFULLNAME=${MAINTAINER_NAME}
		export DEBEMAIL=${MAINTAINER_EMAIL}

		chrt -i 0 make -j${NUM_CPU_CORES} bindeb-pkg
		[ $? -eq 0 ] || exit $?;

		rsync --remove-source-files -rq ../*.deb "${OUTPUTDIR}/debs/"
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
}
