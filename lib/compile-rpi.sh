#!/bin/bash

########################################################################
# compile-rpi.sh
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
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


FIRMWARE_SRC_DIR="${FIRMWARE_BASE_DIR}/${FIRMWARE_NAME}"


update_firmware()
{
	if [ -n "${FIRMWARE_URL}" ] ; then
            PKG_FORCE_CLEAN=yes \
		update_src_pkg $FIRMWARE_NAME \
				$FIRMWARE_VER \
				$FIRMWARE_SRC_DIR \
				$FIRMWARE_URL \
				$FIRMWARE_BRANCH \
				$FIRMWARE_TAG
	fi
}

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLATFORM}" "info"

	echo "*** RaspberryPi is using prebuilt firmware ***"

	echo "Firmware files location: ${FIRMWARE_SRC_DIR}/boot"
	echo "Done."
}
