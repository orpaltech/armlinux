#!/bin/bash

########################################################################
# packages-update.sh
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
# Copyright (C) 2013-2024 ORPAL Technology, Inc.
#
########################################################################

GCC_VERSION=13

REQUIRED_PACKAGES="autoconf autogen automake "\
"build-essential bc binfmt-support bison bmap-tools "\
"ccache cmake cpio crossbuild-essential-armhf crossbuild-essential-arm64 "\
"debootstrap debian-archive-keyring device-tree-compiler dialog dosfstools dropbear "\
"debhelper "\
"fakeroot flex "\
"gawk git gpg gpgv "\
"kmod "\
"libmpc-dev libelf-dev libglib2.0-dev libgnutls28-dev libssl-dev libncurses-dev libtool lynx lzip "\
"ninja-build "\
"qemu-system-arm qemu-user-static quilt "\
"patch python3 python3-pip python3-mako "\
"rsync "\
"sunxi-tools swig "\
"texi2html texinfo "\
"u-boot-tools "\
"whois "\
"xdotool xz-utils "\
"zstd "\
"gcc-${GCC_VERSION} g++-${GCC_VERSION}"

# will find out missing required packages
MISSING_PACKAGES=""

#-----------------------------------------------------------------------

get_host_pkgs()
{
	display_alert "Updating host packages..." "" "info"

	# Check if all required packages are installed on the build system
	for package in $REQUIRED_PACKAGES ; do
		if [ "`dpkg-query -W -f='${Status}' $package 2> /dev/null`" != "install ok installed" ] ; then
			MISSING_PACKAGES="${MISSING_PACKAGES} $package"
		fi
	done

	if [ -n "${MISSING_PACKAGES}" ] ; then
		echo "The following packages needed by build scripts are not installed:"
		echo "${MISSING_PACKAGES}"

		sudo apt-get update

		# Make sure all required packages are installed
		sudo apt-get install -qq -y ${MISSING_PACKAGES}
		[ $? -eq 0 ] || exit $?;
	fi

	local current_version=$(gcc -v 2>&1 | tail -1 | awk '{print $3}')
	local major_version=$(cut -d '.' -f 1 <<< "${current_version}")

	if [[ $GCC_VERSION -gt $major_version ]] ; then
		sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} ${GCC_VERSION}0
		sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} ${GCC_VERSION}0
	fi

	echo "Done."
}
