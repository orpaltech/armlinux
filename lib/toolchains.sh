#!/bin/bash

ARMDEV_NAME="armdev"
BOOTLIN_NAME="bootlin"

LINARO_DIR=${TOOLCHAINDIR}/linaro
OPENRISC_DIR=${TOOLCHAINDIR}/openrisc
BOOTLIN_DIR=${TOOLCHAINDIR}/${BOOTLIN_NAME}
ARMDEV_DIR=${TOOLCHAINDIR}/${ARMDEV_NAME}
MUSL_DIR=${TOOLCHAINDIR}/musl

OPENRISC_CROSS_URL="https://github.com/openrisc/musl-cross"
OPENRISC_CROSS="or1k-linux-musl-cross"

# toolchains versions for kernel, uboot and remaining tools
DEFAULT_TOOLCHAIN_VER=7
KERNEL_TOOLCHAIN_VER=7
UBOOT_TOOLCHAIN_VER=7
ARMDEV_TOOLCHAIN_VER=10
MUSL_TOOLCHAIN_VER=10

# ----------------------------------------------------------------------

get_linaro()
{
	display_alert "Prepare Linaro toolchains..." "" "info"

	LINARO_BASE_URL="https://releases.linaro.org/components/toolchain/binaries"

	declare -A TOOLCHAIN_VERSIONS
	TOOLCHAIN_VERSIONS["7.5-2019.12"]="7"
	TOOLCHAIN_ARCHS=("arm-linux-gnueabihf" "aarch64-linux-gnu")

	local TOOLCHAIN_7_VER="7.5.0-2019.12-x86_64"
	local TOOLCHAIN_7_FILES=("gcc-linaro-${TOOLCHAIN_7_VER}_arm-linux-gnueabihf" "gcc-linaro-${TOOLCHAIN_7_VER}_aarch64-linux-gnu")

	for TOOLCHAIN_VER in "${!TOOLCHAIN_VERSIONS[@]}" ; do

		local VERTMP="${TOOLCHAIN_VERSIONS[$TOOLCHAIN_VER]}"
		local VERDIR=$(sed 's/_/\./g' <<<"${VERTMP}")

		eval TOOLCHAIN_FILES=( \"\${TOOLCHAIN_${VERTMP}_FILES[@]}\" )
		TOOLCHAIN_INDEX=0
		for TOOLCHAIN in "${TOOLCHAIN_FILES[@]}" ; do
			TOOLCHAIN_ARCH="${TOOLCHAIN_ARCHS[$TOOLCHAIN_INDEX]}"

			mkdir -p "${LINARO_DIR}/${VERDIR}/${TOOLCHAIN_ARCH}"
			cd "${LINARO_DIR}/${VERDIR}/${TOOLCHAIN_ARCH}"

			if [ -f "./${TOOLCHAIN}.tar.xz" ] ; then
                		# file was not removed, i.e. extraction failed
	                	rm -f "./${TOOLCHAIN_VER}"
        		fi
			if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
				rm -f "./${TOOLCHAIN_VER}"
			fi

			if [ ! -f "./${TOOLCHAIN_VER}" ] ; then
				rm -rf *
                       		wget "${LINARO_BASE_URL}/${TOOLCHAIN_VER}/${TOOLCHAIN_ARCH}/${TOOLCHAIN}.tar.xz"

				cat "./${TOOLCHAIN}.tar.xz" | tar -ixJv
	                	rm -f "./${TOOLCHAIN}.tar.xz"
				cp -rf ./${TOOLCHAIN}/* ./
				rm -rf ./${TOOLCHAIN}
				echo ${TOOLCHAIN_VER} > ./${TOOLCHAIN_VER}
			fi
			TOOLCHAIN_INDEX=$(expr ${TOOLCHAIN_INDEX} + 1)
		done
	done

	echo "Done."
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

	if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
		rm -rf ${OPENRISC_DIR}/${OPENRISC_CROSS}
	fi

	if [ ! -d "${OPENRISC_DIR}/${OPENRISC_CROSS}" ] ; then
		cd ${OPENRISC_DIR}
		curl -fsSL "http://musl.cc/or1k-linux-musl-cross.tgz" -o ${OPENRISC_CROSS}.tgz

		tar zxvf ${OPENRISC_CROSS}.tgz
	fi

	echo "Done."
}

# ----------------------------------------------------------------------

get_musl()
{
	display_alert "Prepare MUSL toolchains..." "" "info"

	mkdir -p ${MUSL_DIR}

	echo "Done."
}

# ----------------------------------------------------------------------

get_bootlin()
{
	display_alert "Prepare Bootlin toolchains..." "" "info"

	echo "Done."
}

# ----------------------------------------------------------------------

get_toolchains()
{
	get_linaro

	get_armdev

	get_openrisc

#	get_bootlin
}

# ----------------------------------------------------------------------

set_cross_compile()
{
	if [ "${DEBIAN_RELEASE_ARCH}" = arm64 ] ; then
#		BOOTLIN_TOOLCHAIN_PLATFORM="aarch64-buildroot-linux-gnu"

		ARMDEV_TOOLCHAIN_PLATFORM="aarch64-none-linux-gnu"

		MUSL_TOOLCHAIN_PLATFORM="aarch64-linux-musl"

	elif [ "${DEBIAN_RELEASE_ARCH}" = armhf ] ; then
		ARMDEV_TOOLCHAIN_PLATFORM="arm-none-linux-gnueabihf"

		MUSL_TOOLCHAIN_PLATFORM="arm-linux-musleabihf"
	fi

	LINARO_TOOLCHAIN_PLATFORM="${LINUX_PLATFORM}"


#	if [ -z "${BOOTLIN_TOOLCHAIN_PLATFORM}" ] ; then
#		echo "error: variable BOOTLIN_TOOLCHAIN_PLATFORM must be set!"
#		exit 1
#	fi
	if [ -z "${ARMDEV_TOOLCHAIN_PLATFORM}" ] ; then
		echo "error: variable ARMDEV_TOOLCHAIN_PLATFORM must be set!"
		exit 1
	fi
	if [ -z "${MUSL_TOOLCHAIN_PLATFORM}" ] ; then
		echo "error: variable MUSL_TOOLCHAIN_PLATFORM must be set!"
		exit 1
	fi

	LINARO_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/7/${LINARO_TOOLCHAIN_PLATFORM}"
	LINARO_CROSS_COMPILE="${LINARO_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"

#	BOOTLIN_TOOLCHAIN_BASE_DIR="${BOOTLIN_DIR}/10/${BOOTLIN_TOOLCHAIN_PLATFORM}"
#	BOOTLIN_CROSS_COMPILE="${BOOTLIN_TOOLCHAIN_BASE_DIR}/bin/${BOOTLIN_TOOLCHAIN_PLATFORM}-"
#	BOOTLIN_TOOLCHAIN_INCDIR="${BOOTLIN_TOOLCHAIN_BASE_DIR}/${BOOTLIN_TOOLCHAIN_PLATFORM}/include"
#	BOOTLIN_TOOLCHAIN_LIBDIR="${BOOTLIN_TOOLCHAIN_BASE_DIR}/${BOOTLIN_TOOLCHAIN_PLATFORM}/lib64"

	MUSL_TOOLCHAIN_BASE_DIR="${MUSL_DIR}/${MUSL_TOOLCHAIN_VER}/${MUSL_TOOLCHAIN_PLATFORM}"
	MUSL_CROSS_COMPILE="${MUSL_TOOLCHAIN_BASE_DIR}/bin/${MUSL_TOOLCHAIN_PLATFORM}-"

	ARMDEV_TOOLCHAIN_BASE_DIR="${ARMDEV_DIR}/${ARMDEV_TOOLCHAIN_VER}/${ARMDEV_TOOLCHAIN_PLATFORM}"
	ARMDEV_CROSS_COMPILE="${ARMDEV_TOOLCHAIN_BASE_DIR}/bin/${ARMDEV_TOOLCHAIN_PLATFORM}-"
	ARMDEV_TOOLCHAIN_INCDIR="${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/usr/include"

	if [ "${DEBIAN_RELEASE_ARCH}" = arm64 ] ; then
		ARMDEV_TOOLCHAIN_LIBDIR="${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/lib ${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/lib64 ${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/usr/lib64"
	elif [ "${DEBIAN_RELEASE_ARCH}" = armhf ] ; then
		ARMDEV_TOOLCHAIN_LIBDIR="${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/lib ${ARMDEV_TOOLCHAIN_BASE_DIR}/${ARMDEV_TOOLCHAIN_PLATFORM}/libc/usr/lib"
	fi

	OPENRISC_CROSS_COMPILE="${OPENRISC_DIR}/${OPENRISC_CROSS}/bin/or1k-linux-musl-"


	if [ -z "${UBOOT_CROSS_COMPILE}" ] ; then
		UBOOT_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/7/${LINARO_TOOLCHAIN_PLATFORM}"
		UBOOT_CROSS_COMPILE="${UBOOT_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"
	fi

	if [ -z "${KERNEL_CROSS_COMPILE}" ] ; then
		KERNEL_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/7/${LINARO_TOOLCHAIN_PLATFORM}"
		KERNEL_CROSS_COMPILE="${KERNEL_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"
	fi

	if [ -z "${CROSS_COMPILE}" ] ; then
		TOOLCHAIN_BASE_DIR="${LINARO_DIR}/7/${LINARO_TOOLCHAIN_PLATFORM}"
		CROSS_COMPILE="${TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"
	fi

#	if [ -z "${MESA_CROSS_COMPILE}" ] ; then
#		MESA_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/11/${LINARO_TOOLCHAIN_PLATFORM}"
#		MESA_CROSS_COMPILE="${MESA_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"
#	fi

#	if [ -z "${QT_CROSS_COMPILE}" ] ; then
#		QT_TOOLCHAIN_BASE_DIR="${LINARO_DIR}/7/${LINARO_TOOLCHAIN_PLATFORM}"
#		QT_CROSS_COMPILE="${QT_TOOLCHAIN_BASE_DIR}/bin/${LINARO_TOOLCHAIN_PLATFORM}-"
#	fi


#	if [ -z "${UBOOT_CROSS_COMPILE}" ] ; then
	UBOOT_TOOLCHAIN_BASE_DIR="${ARMDEV_TOOLCHAIN_BASE_DIR}"
	UBOOT_CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"
#	fi

#	if [ -z "${KERNEL_CROSS_COMPILE}" ] ; then
	KERNEL_TOOLCHAIN_BASE_DIR="${ARMDEV_TOOLCHAIN_BASE_DIR}"
	KERNEL_CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"
#	fi

#	TOOLCHAIN_BASE_DIR="${BOOTLIN_TOOLCHAIN_BASE_DIR}"
#	CROSS_COMPILE="${BOOTLIN_CROSS_COMPILE}"
	TOOLCHAIN_BASE_DIR="${ARMDEV_TOOLCHAIN_BASE_DIR}"
	CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"

	MESA_TOOLCHAIN=${ARMDEV_NAME}
	MESA_TOOLCHAIN_BASE_DIR=${ARMDEV_TOOLCHAIN_BASE_DIR}
	MESA_CROSS_COMPILE=${ARMDEV_CROSS_COMPILE}
	MESA_TOOLCHAIN_INCDIR=${ARMDEV_TOOLCHAIN_INCDIR}

#	QT_CROSS_COMPILE="${MESA_CROSS_COMPILE}"

#	QT_CROSS_COMPILE="${BOOTLIN_CROSS_COMPILE}"
#	QT_TOOLCHAIN_BASE_DIR="${BOOTLIN_TOOLCHAIN_BASE_DIR}"
#	QT_TOOLCHAIN_INCDIR="${BOOTLIN_TOOLCHAIN_INCDIR}"
#	QT_TOOLCHAIN_LIBDIR="${BOOTLIN_TOOLCHAIN_LIBDIR}"

	QT_CROSS_COMPILE=${ARMDEV_CROSS_COMPILE}
	QT_TOOLCHAIN_BASE_DIR=${ARMDEV_TOOLCHAIN_BASE_DIR}
	QT_TOOLCHAIN_INCDIR=${ARMDEV_TOOLCHAIN_INCDIR}
	QT_TOOLCHAIN_LIBDIR=${ARMDEV_TOOLCHAIN_LIBDIR}

}
