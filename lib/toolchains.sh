#!/bin/bash


LINARO_DIR=${TOOLCHAINDIR}/linaro
OPENRISC_DIR=${TOOLCHAINDIR}/openrisc
ARMDEV_DIR=${TOOLCHAINDIR}/armdev
MUSL_DIR=${TOOLCHAINDIR}/musl

OPENRISC_CROSS_URL="https://github.com/stffrdhrn/gcc/releases/download/or1k-9.1.1-20190507/or1k-linux-musl-9.1.1-20190507.tar.xz"
OPENRISC_CROSS="or1k-linux-musl"

MUSL_ARMHF_CROSS_URL="https://musl.cc/arm-linux-musleabihf-cross.tgz"
MUSL_AARCH64_CROSS_URL="https://musl.cc/armv7l-linux-musleabihf-cross.tgz"

# toolchains versions for kernel, uboot and remaining tools
ARMDEV_TOOLCHAIN_VER=13
OPENRISC_TOOLCHAIN_VER=9
MUSL_TOOLCHAIN_VER=11
LINARO_TOOLCHAIN_VER=14


# ----------------------------------------------------------------------

get_armdev()
{
	display_alert "Prepare ARM Cortex-A Family toolchains..." "" "info"

	mkdir -p ${ARMDEV_DIR}

	if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
		rm -rf ${ARMDEV_DIR}/*
	fi


	mkdir -p ${ARMDEV_DIR}/10
	cd ${ARMDEV_DIR}/10

	ARMDEV_10_ARMHF_FILE="gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf"
	ARMDEV_10_AARCH64_FILE="gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu"

	if [ ! -d "arm-none-linux-gnueabihf" ] ; then
		wget "https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/${ARMDEV_10_ARMHF_FILE}.tar.xz"
		cat ${ARMDEV_10_ARMHF_FILE}.tar.xz | tar -ixJv
		mv ${ARMDEV_10_ARMHF_FILE} arm-none-linux-gnueabihf
		rm -f ${ARMDEV_10_ARMHF_FILE}.tar.xz
	fi
	if [ ! -d "aarch64-none-linux-gnu" ] ; then
		wget "https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/${ARMDEV_10_AARCH64_FILE}.tar.xz"
		cat ${ARMDEV_10_AARCH64_FILE}.tar.xz | tar -ixJv
		mv ${ARMDEV_10_AARCH64_FILE} aarch64-none-linux-gnu
		rm -f ${ARMDEV_10_AARCH64_FILE}.tar.xz
        fi


	mkdir -p ${ARMDEV_DIR}/11
	cd ${ARMDEV_DIR}/11

	ARMDEV_11_ARMHF_FILE="gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
	ARMDEV_11_AARCH64_FILE="gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu"

	if [ ! -d "arm-none-linux-gnueabihf" ] ; then
		wget "https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/${ARMDEV_11_ARMHF_FILE}.tar.xz"
		cat ${ARMDEV_11_ARMHF_FILE}.tar.xz | tar -ixJv
		mv ${ARMDEV_11_ARMHF_FILE} arm-none-linux-gnueabihf
		rm -f ${ARMDEV_11_ARMHF_FILE}.tar.xz
	fi
	if [ ! -d "aarch64-none-linux-gnu" ] ; then
		wget "https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/${ARMDEV_11_AARCH64_FILE}.tar.xz"
		cat ${ARMDEV_11_AARCH64_FILE}.tar.xz | tar -ixJv
		mv ${ARMDEV_11_AARCH64_FILE} aarch64-none-linux-gnu
		rm -f ${ARMDEV_11_AARCH64_FILE}.tar.xz
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

# ----------------------------------------------------------------------

get_toolchains()
{
	get_musl
	get_openrisc

	if [ "${ROOTFS}" = debian ] ; then
		get_armdev
		get_linaro
	fi
}

# ----------------------------------------------------------------------

set_cross_compile()
{
	if [[ ${LINUX_PLATFORM} =~ ^aarch64-* ]] ; then

		ARMDEV_TOOLCHAIN_PLATFORM="aarch64-none-linux-gnu"

		LINARO_TOOLCHAIN_PLATFORM="aarch64-linux-gnu"

		MUSL_TOOLCHAIN_PLATFORM="aarch64-linux-musl"

	elif [[ ${LINUX_PLATFORM} =~ ^arm-* ]] ; then

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
        LINARO_CROSS_COMPILE="${LINARO_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"

	MUSL_TOOLCHAIN_BASE_DIR="${MUSL_DIR}/${MUSL_TOOLCHAIN_VER}/${MUSL_TOOLCHAIN_PLATFORM}"
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
		if [ "${ROOTFS}" = debian ] ; then
			CROSS_COMPILE=${LINARO_CROSS_COMPILE}
			TOOLCHAIN_BASE_DIR=${LINARO_TOOLCHAIN_BASE_DIR}
			TOOLCHAIN_NAME=linaro
#		else
#			CROSS_COMPILE=${MUSL_CROSS_COMPILE}
#			TOOLCHAIN_BASE_DIR=${MUSL_TOOLCHAIN_BASE_DIR}
#			TOOLCHAIN_NAME=musl
		fi
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


	MESA_TOOLCHAIN_BASE_DIR=${TOOLCHAIN_BASE_DIR}
	MESA_CROSS_COMPILE=${CROSS_COMPILE}
	MESA_TOOLCHAIN=${TOOLCHAIN_NAME}

	MESA_GCC="${MESA_CROSS_COMPILE}gcc"
	MESA_GCC_VER=$(${MESA_GCC} -dumpversion)
	MESA_CXX="${MESA_CROSS_COMPILE}g++"
	MESA_AR="${MESA_CROSS_COMPILE}ar"
	MESA_STRIP="${MESA_CROSS_COMPILE}strip"
	MESA_NM="${MESA_CROSS_COMPILE}nm"

	#-------------------------------------------------------------------

	if [ "${ROOTFS}" = debian ] ; then
		QT_CROSS_COMPILE=${CROSS_COMPILE}
		QT_TOOLCHAIN_BASE_DIR=${TOOLCHAIN_BASE_DIR}
#		QT_TOOLCHAIN_INCDIR=${BOOTLIN_TOOLCHAIN_INCDIR}
#		QT_TOOLCHAIN_LIBDIR=${BOOTLIN_TOOLCHAIN_LIBDIR}
#	else
#		QT_CROSS_COMPILE=${MUSL_CROSS_COMPILE}
#		QT_TOOLCHAIN_BASE_DIR=${MUSL_TOOLCHAIN_BASE_DIR}
#		QT_TOOLCHAIN_INCDIR=${ARMDEV_TOOLCHAIN_INCDIR}
#		QT_TOOLCHAIN_LIBDIR=${ARMDEV_TOOLCHAIN_LIBDIR}
	fi
}
