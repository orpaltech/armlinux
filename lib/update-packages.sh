#!/bin/bash


get_host_pkgs()
{
	display_alert "Updating host packages..." "" "info"

        sudo apt-get install -qq -y \
		autoconf \
                debootstrap \
                debian-archive-keyring \
                qemu-user-static \
                binfmt-support \
                dosfstools \
		git \
                rsync \
		patch \
                bmap-tools \
                whois git bc \
                device-tree-compiler \
		cmake \
		texi2html texinfo \
		dialog \
		sunxi-tools
	[ $? -eq 0 ] || exit $?;
}

get_toolchains()
{
        display_alert "Prepare toolchains..." "" "info"

	LINARO_BASE_URL="https://releases.linaro.org/components/toolchain/binaries"

	declare -A TOOLCHAIN_VERSIONS
	TOOLCHAIN_VERSIONS["7.2-2017.11"]="7_2"
	TOOLCHAIN_VERSIONS["6.4-2017.11"]="6_4"

	TOOLCHAIN_7_2_FILES=("gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf" 
				"gcc-linaro-7.2.1-2017.11-x86_64_armv8l-linux-gnueabihf" 
				"gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu")
	TOOLCHAIN_7_2_ARCHS=("arm-linux-gnueabihf" 
				"armv8l-linux-gnueabihf" 
				"aarch64-linux-gnu")

	TOOLCHAIN_6_4_FILES=("gcc-linaro-6.4.1-2017.11-x86_64_arm-linux-gnueabihf")
	TOOLCHAIN_6_4_ARCHS=("arm-linux-gnueabihf")

	#--------------------------------------------------------------------

	for TOOLCHAIN_VER in "${!TOOLCHAIN_VERSIONS[@]}" ; do

		local VERTMP="${TOOLCHAIN_VERSIONS[$TOOLCHAIN_VER]}"

		eval TOOLCHAIN_FILES=( \"\${TOOLCHAIN_${VERTMP}_FILES[@]}\" )
		eval TOOLCHAIN_ARCHS=( \"\${TOOLCHAIN_${VERTMP}_ARCHS[@]}\" )

		TOOLCHAIN_INDEX=0
		for TOOLCHAIN in "${TOOLCHAIN_FILES[@]}" ; do
			TOOLCHAIN_ARCH="${TOOLCHAIN_ARCHS[$TOOLCHAIN_INDEX]}"

			mkdir -p "${TOOLCHAINDIR}/${TOOLCHAIN_VER}/${TOOLCHAIN_ARCH}"
			cd "${TOOLCHAINDIR}/${TOOLCHAIN_VER}/${TOOLCHAIN_ARCH}"

			if [ -f "./${TOOLCHAIN}.tar.xz" ] ; then
                		# file was not removed, i.e. extraction failed
	                	rm -rf "./${TOOLCHAIN}"
        		fi
			if [ ! -d "./${TOOLCHAIN}" ] ; then
				if [ ! -f "./${TOOLCHAIN}.tar.xz" ] ; then
                        		wget "${LINARO_BASE_URL}/${TOOLCHAIN_VER}/${TOOLCHAIN_ARCH}/${TOOLCHAIN}.tar.xz"
                		fi
				cat "./${TOOLCHAIN}.tar.xz" | tar -ixJv
	                	rm -f "./${TOOLCHAIN}.tar.xz"
			fi
			TOOLCHAIN_INDEX=$(expr $TOOLCHAIN_INDEX + 1)
		done

	done

	#--------------------------------------------------------------------

        if [ ! -f "${CROSS_COMPILE}gcc" ] ; then
                echo "ERROR: specified toolchain not found [${CROSS_COMPILE}] !"
                exit 1
        fi

        echo "Done."
}
