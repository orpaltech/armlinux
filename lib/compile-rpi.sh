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
# Copyright (C) 2013-2022 ORPAL Technology, Inc.
#
########################################################################


update_firmware()
{
	if [ ! -z "${FIRMWARE_URL}" ] ; then
		fw_update ${FIRMWARE_NAME} ${FIRMWARE_URL} no ${FIRMWARE_BRANCH}
	fi
}

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLATFORM}" "info"

	echo "*** RaspberryPi is using prebuilt firmware ***"

	echo "Done."
}
