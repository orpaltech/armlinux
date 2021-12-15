#!/bin/bash

LINARO_DIR=${TOOLCHAINDIR}/linaro
OPENRISC_DIR=${TOOLCHAINDIR}/openrisc


# ----------------------------------------------------------------------

get_linaro()
{
	display_alert "Prepare Linaro toolchains..." "" "info"

	LINARO_BASE_URL="https://releases.linaro.org/components/toolchain/binaries"

	declare -A TOOLCHAIN_VERSIONS
	TOOLCHAIN_VERSIONS["7.5-2019.12"]="7"
	TOOLCHAIN_VERSIONS["6.5-2018.12"]="6"
	TOOLCHAIN_VERSIONS["5.5-2017.10"]="5"
	TOOLCHAIN_VERSIONS["4.9-2017.01"]="4"
	TOOLCHAIN_ARCHS=("arm-linux-gnueabihf" "aarch64-linux-gnu")

	local TOOLCHAIN_7_VER="7.5.0-2019.12-x86_64"
	local TOOLCHAIN_7_FILES=("gcc-linaro-${TOOLCHAIN_7_VER}_arm-linux-gnueabihf" "gcc-linaro-${TOOLCHAIN_7_VER}_aarch64-linux-gnu")

	local TOOLCHAIN_6_VER="6.5.0-2018.12-x86_64"
	local TOOLCHAIN_6_FILES=("gcc-linaro-${TOOLCHAIN_6_VER}_arm-linux-gnueabihf" "gcc-linaro-${TOOLCHAIN_6_VER}_aarch64-linux-gnu")

	local TOOLCHAIN_5_VER="5.5.0-2017.10-x86_64"
	local TOOLCHAIN_5_FILES=("gcc-linaro-${TOOLCHAIN_5_VER}_arm-linux-gnueabihf" "gcc-linaro-${TOOLCHAIN_5_VER}_aarch64-linux-gnu")

	local TOOLCHAIN_4_VER="4.9.4-2017.01-x86_64"
        local TOOLCHAIN_4_FILES=("gcc-linaro-${TOOLCHAIN_4_VER}_arm-linux-gnueabihf" "gcc-linaro-${TOOLCHAIN_4_VER}_aarch64-linux-gnu")


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

MUSL_CROSS_URL="https://github.com/openrisc/musl-cross"
MUSL_CROSS="or1k-linux-musl-cross"

get_openrisc()
{
	mkdir -p ${OPENRISC_DIR}

	if [ "${TOOLCHAIN_FORCE_UPDATE}" = yes ] ; then
		rm -rf ${OPENRISC_DIR}/${MUSL_CROSS}
	fi

	if [ ! -d "${OPENRISC_DIR}/${MUSL_CROSS}" ] ; then
		cd ${OPENRISC_DIR}
		curl -fsSL "http://musl.cc/or1k-linux-musl-cross.tgz" -o ${MUSL_CROSS}.tgz

		tar zxvf ${MUSL_CROSS}.tgz
	fi
}

# ----------------------------------------------------------------------

get_toolchains()
{
	get_linaro
	get_openrisc
}

# ----------------------------------------------------------------------

set_cross_compile()
{
	if [ -z "${LINUX_PLATFORM}" ] ; then
		echo "error: variable LINUX_PLATFORM must be set!"
		exit 1
	fi

	if [ -z "${UBOOT_CROSS_COMPILE}" ] ; then
		UBOOT_CROSS_COMPILE="${LINARO_DIR}/${UBOOT_TOOLCHAIN_VER}/${LINUX_PLATFORM}/bin/${LINUX_PLATFORM}-"
	fi

	if [ -z "${KERNEL_CROSS_COMPILE}" ] ; then
		KERNEL_CROSS_COMPILE="${LINARO_DIR}/${KERNEL_TOOLCHAIN_VER}/${LINUX_PLATFORM}/bin/${LINUX_PLATFORM}-"
	fi

	if [ -z "${CROSS_COMPILE}" ] ; then
		CROSS_COMPILE="${LINARO_DIR}/${DEFAULT_TOOLCHAIN_VER}/${LINUX_PLATFORM}/bin/${LINUX_PLATFORM}-"
	fi

	MUSL_CROSS_COMPILE="${OPENRISC_DIR}/${MUSL_CROSS}/bin/or1k-linux-musl-"
}
