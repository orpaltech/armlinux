#!/bin/bash

REQUIRED_PACKAGES="autoconf \
bc binfmt-support bison bmap-tools \
cmake \
debootstrap debian-archive-keyring device-tree-compiler dialog dosfstools \
git \
libssl-dev \
qemu-user-static quilt \
patch python-dev python-mako python-minimal \
rsync \
sunxi-tools swig \
texi2html texinfo \
u-boot-tools \
whois"

MISSING_PACKAGES=""

#------------------------------------------------------------------------------------------------------

get_host_pkgs()
{
	display_alert "Updating host packages..." "" "info"

	# Check if all required packages are installed on the build system
	for package in $REQUIRED_PACKAGES ; do
		if [ "`dpkg-query -W -f='${Status}' $package`" != "install ok installed" ] ; then
			MISSING_PACKAGES="${MISSING_PACKAGES} $package"
		fi
	done

	if [ -n "${MISSING_PACKAGES}" ] ; then
		echo "The following packages needed by this script are not installed:"
		echo "${MISSING_PACKAGES}"

		# Make sure all required packages are installed
		sudo apt-get install -qq -y $MISSING_PACKAGES
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
}

#------------------------------------------------------------------------------------------------------

get_toolchains()
{
        display_alert "Prepare toolchains..." "" "info"

	local LINARO_BASE_URL="https://releases.linaro.org/components/toolchain/binaries"

	declare -A TOOLCHAIN_VERSIONS
	TOOLCHAIN_VERSIONS["7.3-2018.05"]="7_3"
	TOOLCHAIN_VERSIONS["6.4-2018.05"]="6_4"
	TOOLCHAIN_ARCHS=("arm-linux-gnueabihf" "aarch64-linux-gnu")

	local TOOLCHAIN_7_3_VER="7.3.1-2018.05-x86_64"
	local TOOLCHAIN_7_3_FILES=("gcc-linaro-${TOOLCHAIN_7_3_VER}_arm-linux-gnueabihf" 
				"gcc-linaro-${TOOLCHAIN_7_3_VER}_aarch64-linux-gnu")

	local TOOLCHAIN_6_4_VER="6.4.1-2018.05-x86_64"
	local TOOLCHAIN_6_4_FILES=("gcc-linaro-${TOOLCHAIN_6_4_VER}_arm-linux-gnueabihf" 
				"gcc-linaro-${TOOLCHAIN_6_4_VER}_aarch64-linux-gnu")


	for TOOLCHAIN_VER in "${!TOOLCHAIN_VERSIONS[@]}" ; do

		local VERTMP="${TOOLCHAIN_VERSIONS[$TOOLCHAIN_VER]}"
		local VERDIR=$(sed 's/_/\./g' <<<"${VERTMP}")

		eval TOOLCHAIN_FILES=( \"\${TOOLCHAIN_${VERTMP}_FILES[@]}\" )

		TOOLCHAIN_INDEX=0
		for TOOLCHAIN in "${TOOLCHAIN_FILES[@]}" ; do
			TOOLCHAIN_ARCH="${TOOLCHAIN_ARCHS[$TOOLCHAIN_INDEX]}"

			mkdir -p "${TOOLCHAINDIR}/${VERDIR}/${TOOLCHAIN_ARCH}"
			cd "${TOOLCHAINDIR}/${VERDIR}/${TOOLCHAIN_ARCH}"

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

        if [ ! -f "${CROSS_COMPILE}gcc" ] ; then
                echo "ERROR: toolchain not found [${CROSS_COMPILE}] !"
                exit 1
        fi

        echo "Done."
}
