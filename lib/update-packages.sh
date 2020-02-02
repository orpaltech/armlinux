#!/bin/bash

########################################################################
# update-packages.sh
#
# Description:	Host machine preparation script for ORPALTECH ARMLINUX
#		build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2018 ORPAL Technology, Inc.
#
########################################################################

REQUIRED_PACKAGES="autoconf \
bc binfmt-support bison bmap-tools \
cmake \
debootstrap debian-archive-keyring device-tree-compiler dialog dosfstools \
git \
libssl-dev \
qemu-user-static quilt \
patch \
python-dev python-mako python-minimal \
python3 python3-pip python3-mako \
ninja-build \
rsync \
sunxi-tools swig \
texi2html texinfo \
u-boot-tools \
whois"

MISSING_PACKAGES=""

TOOLCHAIN_FORCE_UPDATE=${TOOLCHAIN_FORCE_UPDATE:="no"}

#-----------------------------------------------------------------------

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
		echo "The following packages needed by build scripts are not installed:"
		echo "${MISSING_PACKAGES}"

		sudo apt-get update
		# Make sure all required packages are installed
		sudo apt-get install -qq -y $MISSING_PACKAGES
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
}

#-----------------------------------------------------------------------

get_toolchains()
{
        display_alert "Prepare toolchains..." "" "info"

	local LINARO_BASE_URL="https://releases.linaro.org/components/toolchain/binaries"

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

			mkdir -p "${TOOLCHAINDIR}/${VERDIR}/${TOOLCHAIN_ARCH}"
			cd "${TOOLCHAINDIR}/${VERDIR}/${TOOLCHAIN_ARCH}"

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
				cp -rf ./$TOOLCHAIN/* ./
				rm -rf ./$TOOLCHAIN
				echo $TOOLCHAIN_VER > ./$TOOLCHAIN_VER
			fi
			TOOLCHAIN_INDEX=$(expr ${TOOLCHAIN_INDEX} + 1)
		done
	done


        echo "Done."
}
