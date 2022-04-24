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
# Copyright (C) 2013-2020 ORPAL Technology, Inc.
#
########################################################################

GCC_VERSION=10

REQUIRED_PACKAGES="autoconf automake bc binfmt-support bison bmap-tools "\
"cmake "\
"debootstrap debian-archive-keyring device-tree-compiler dialog dosfstools "\
"flex "\
"git "\
"libmpc-dev "\
"libssl-dev "\
"ninja-build "\
"qemu-user-static quilt "\
"patch "\
"python2.7 python-mako python3 python3-pip python3-mako "\
"rsync "\
"sunxi-tools swig "\
"texi2html texinfo "\
"u-boot-tools "\
"whois "\
"xz-utils "\
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

	sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} ${GCC_VERSION}0 --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} --slave /usr/bin/gcov gcov /usr/bin/gcov-${GCC_VERSION}

	echo "Done."
}
