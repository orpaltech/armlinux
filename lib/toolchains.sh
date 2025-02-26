#!/bin/bash

########################################################################
# toolchains.sh
#
# Description:  The functions used for preparing toolchains.
#
# Author:       Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


LINARO_DIR=${TOOLCHAINDIR}/linaro
OPENRISC_DIR=${TOOLCHAINDIR}/openrisc
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
ARMDEV_DIR=${TOOLCHAINDIR}/armdev
MUSL_DIR=${TOOLCHAINDIR}/musl

#OPENRISC_GCC_VER=9.1.1-20190507
OPENRISC_GCC_VER=10.0.0-20190723
OPENRISC_CROSS_URL="https://github.com/stffrdhrn/gcc/releases/download/or1k-${OPENRISC_GCC_VER}/or1k-linux-musl-${OPENRISC_GCC_VER}.tar.xz"
OPENRISC_CROSS="or1k-linux-musl"

MUSL_ARMHF_CROSS_URL="https://musl.cc/arm-linux-musleabihf-cross.tgz"
MUSL_AARCH64_CROSS_URL="https://musl.cc/armv7l-linux-musleabihf-cross.tgz"

# current toolchains versions that we want to use
ARMDEV_TOOLCHAIN_VER=14
OPENRISC_TOOLCHAIN_VER=10
MUSL_TOOLCHAIN_VER=11
LINARO_TOOLCHAIN_VER=14


#
# ############ helper functions ##############
#

extract_tar()
{
	local linux_plat=$2
	local tar_url=$1

	wget $tar_url
	local tar_file=$(basename $tar_url)
	local tar_name=${tar_file%.tar.xz}
	cat $tar_file | tar -ixJv
	mv $tar_name $linux_plat
	rm -f $tar_file
}

get_armdev()
{
	display_alert "Prepare ARM Cortex-A Family toolchains..." "" "info"

	mkdir -p ${ARMDEV_DIR}

	if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
		rm -rf ${ARMDEV_DIR}/*
	fi


	mkdir -p ${ARMDEV_DIR}/10
	cd ${ARMDEV_DIR}/10


	if [ ! -d "arm-none-linux-gnueabihf" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz"
		extract_tar $tar_url arm-none-linux-gnueabihf
	fi
	if [ ! -d "aarch64-none-linux-gnu" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz"
		extract_tar $tar_url aarch64-none-linux-gnu
        fi


	mkdir -p ${ARMDEV_DIR}/11
	cd ${ARMDEV_DIR}/11


	if [ ! -d "arm-none-linux-gnueabihf" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
		extract_tar $tar_url arm-none-linux-gnueabihf
	fi
	if [ ! -d "aarch64-none-linux-gnu" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz"
		extract_tar $tar_url aarch64-none-linux-gnu
	fi


	mkdir -p ${ARMDEV_DIR}/14
	cd ${ARMDEV_DIR}/14/


        if [ ! -d "arm-none-linux-gnueabihf" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz"
		extract_tar $tar_url arm-none-linux-gnueabihf
        fi
        if [ ! -d "aarch64-none-linux-gnu" ] ; then
		tar_url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
		extract_tar $tar_url aarch64-none-linux-gnu
        fi

	echo "Done."
}

# ----------------------------------------------------------------------

get_openrisc()
{
	display_alert "Prepare OpenRISC toolchains..." "" "info"

	mkdir -p ${OPENRISC_DIR}

	OPENRISC_CROSS_DIR="${OPENRISC_DIR}/${OPENRISC_TOOLCHAIN_VER}"

	if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
		rm -rf ${OPENRISC_CROSS_DIR}
	fi

	if [ ! -d "${OPENRISC_CROSS_DIR}" ] ; then
		mkdir -p ${OPENRISC_CROSS_DIR}
		cd ${OPENRISC_CROSS_DIR}
		curl -fsSL "${OPENRISC_CROSS_URL}" -o ${OPENRISC_CROSS}.tar.xz
		tar -xvf ${OPENRISC_CROSS}.tar.xz
		rm -f ${OPENRISC_CROSS}.tar.xz
	fi

	echo "Done."
}

# ----------------------------------------------------------------------

get_musl()
{
	display_alert "Prepare MUSL ARM toolchains..." "" "info"

	mkdir -p ${MUSL_DIR}

	echo "Done."
}

# ----------------------------------------------------------------------

get_linaro()
{
	display_alert "Prepare Linaro ARM toolchains..." "" "info"

	mkdir -p ${LINARO_DIR}

	echo "Done."
}


#
# ############ public functions ##############
#

get_toolchains()
{
	get_musl
	get_openrisc
	get_armdev
	get_linaro
}


set_cross_compile()
{
	if [ "${SOC_ARCH}" = arm64 ] ; then

		ARMDEV_TOOLCHAIN_PLATFORM="aarch64-none-linux-gnu"

		LINARO_TOOLCHAIN_PLATFORM="aarch64-linux-gnu"

		MUSL_TOOLCHAIN_PLATFORM="aarch64-linux-musl"

	elif [ "${SOC_ARCH}" = arm ] ; then

		ARMDEV_TOOLCHAIN_PLATFORM="arm-none-linux-gnueabihf"

		LINARO_TOOLCHAIN_PLATFORM="arm-linux-gnueabihf"

		MUSL_TOOLCHAIN_PLATFORM="arm-linux-musleabihf"
	fi


	if [ -z "${ARMDEV_TOOLCHAIN_PLATFORM}" ] ; then
		echo "error: variable ARMDEV_TOOLCHAIN_PLATFORM must be set!"
		exit 1
	fi
	if [ -z "${LINARO_TOOLCHAIN_PLATFORM}" ] ; then
		echo "error: variable LINARO_TOOLCHAIN_PLATFORM must be set!"
		exit 1
	fi
	if [ -z "${MUSL_TOOLCHAIN_PLATFORM}" ] ; then
		echo "error: variable MUSL_TOOLCHAIN_PLATFORM must be set!"
		exit 1
	fi

	ARMDEV_TOOLCHAIN_BASE_DIR="${ARMDEV_DIR}/${ARMDEV_TOOLCHAIN_VER}/${ARMDEV_TOOLCHAIN_PLATFORM}"
	ARMDEV_CROSS_COMPILE="${ARMDEV_TOOLCHAIN_BASE_DIR}/bin/${ARMDEV_TOOLCHAIN_PLATFORM}-"

	LINARO_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/${LINARO_TOOLCHAIN_VER}/${LINARO_TOOLCHAIN_PLATFORM}"
	LINARO_TOOLCHAIN_SYSROOT="${LINARO_TOOLCHAIN_BASE_DIR}/${LINARO_TOOLCHAIN_PLATFORM}/libc"
	LINARO_TOOLCHAIN_LIB_DIR="${LINARO_TOOLCHAIN_SYSROOT}/lib"
        LINARO_CROSS_COMPILE="${LINARO_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"

	MUSL_TOOLCHAIN_BASE_DIR="${MUSL_DIR}/${MUSL_TOOLCHAIN_VER}/${MUSL_TOOLCHAIN_PLATFORM}"
	MUSL_TOOLCHAIN_ROOT_DIR="${MUSL_TOOLCHAIN_BASE_DIR}/${MUSL_TOOLCHAIN_PLATFORM}"
	MUSL_CROSS_COMPILE="${MUSL_TOOLCHAIN_BASE_DIR}/bin/${MUSL_TOOLCHAIN_PLATFORM}-"


	OPENRISC_CROSS_COMPILE="${OPENRISC_DIR}/${OPENRISC_TOOLCHAIN_VER}/${OPENRISC_CROSS}/bin/${OPENRISC_CROSS}-"


	if [ -z "${UBOOT_CROSS_COMPILE}" ] ; then
		UBOOT_TOOLCHAIN_BASE_DIR="${ARMDEV_TOOLCHAIN_BASE_DIR}"
		UBOOT_CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"
	fi

	if [ -z "${KERNEL_CROSS_COMPILE}" ] ; then
		KERNEL_TOOLCHAIN_BASE_DIR="${ARMDEV_TOOLCHAIN_BASE_DIR}"
		KERNEL_CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"
	fi

	if [ -z "${CROSS_COMPILE}" ] ; then
		CROSS_COMPILE=${LINARO_CROSS_COMPILE}
		TOOLCHAIN_BASE_DIR=${LINARO_TOOLCHAIN_BASE_DIR}
		TOOLCHAIN_SYSROOT=${LINARO_TOOLCHAIN_SYSROOT}
		TOOLCHAIN_NAME=linaro
		TOOLCHAIN_LIB_DIR=${LINARO_TOOLCHAIN_LIB_DIR}
	fi

	# declare individual toolchain components
	DEV_GCC="${CROSS_COMPILE}gcc"
	DEV_CXX="${CROSS_COMPILE}g++"
	DEV_LD="${CROSS_COMPILE}ld"
	DEV_AS="${CROSS_COMPILE}as"
	DEV_AR="${CROSS_COMPILE}ar"
	DEV_NM="${CROSS_COMPILE}nm"
	DEV_STRIP="${CROSS_COMPILE}strip"
	DEV_RANLIB="${CROSS_COMPILE}ranlib"
	DEV_READELF="${CROSS_COMPILE}readelf"
	DEV_OBJCOPY="${CROSS_COMPILE}objcopy"
	DEV_OBJDUMP="${CROSS_COMPILE}objdump"


	# musl individual toolchain components
	MUSL_GCC="${MUSL_CROSS_COMPILE}gcc"
	MUSL_CXX="${MUSL_CROSS_COMPILE}g++"
	MUSL_LD="${MUSL_CROSS_COMPILE}ld"
	MUSL_NM="${MUSL_CROSS_COMPILE}nm"
	MUSL_STRIP="${MUSL_CROSS_COMPILE}strip"


	#-------------------------------------------------------------------

#	if [ "${ROOTFS}" = debian ] ; then
	QT_CROSS_COMPILE=${CROSS_COMPILE}
	QT_TOOLCHAIN_BASE_DIR=${TOOLCHAIN_BASE_DIR}
#		QT_TOOLCHAIN_INCDIR=${BOOTLIN_TOOLCHAIN_INCDIR}
#		QT_TOOLCHAIN_LIBDIR=${BOOTLIN_TOOLCHAIN_LIBDIR}
#	else
#		QT_CROSS_COMPILE=${MUSL_CROSS_COMPILE}
#		QT_TOOLCHAIN_BASE_DIR=${MUSL_TOOLCHAIN_BASE_DIR}
#		QT_TOOLCHAIN_INCDIR=${ARMDEV_TOOLCHAIN_INCDIR}
#		QT_TOOLCHAIN_LIBDIR=${ARMDEV_TOOLCHAIN_LIBDIR}
#	fi
}
