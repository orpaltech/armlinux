#!/bin/bash

########################################################################
# compile-sunxi.sh
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
	if [ -n "${FIRMWARE_ATF_URL}" ] ; then
		fw_update ${FIRMWARE_ATF_NAME} ${FIRMWARE_ATF_URL} no ${FIRMWARE_ATF_BRANCH} ${FIRMWARE_ATF_TAG}
	fi

	if [ -n "${FIRMWARE_SCP_URL}" ] ; then
		fw_update ${FIRMWARE_SCP_NAME} ${FIRMWARE_SCP_URL} no ${FIRMWARE_SCP_BRANCH} ${FIRMWARE_SCP_TAG}
        fi
}

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLATFORM}" "info"

	case ${SOC_PLATFORM} in
    	    sun50i*)
		echo "*** ARM trusted firmware ***"
		cd ${FIRMWARE_BASE_DIR}/${FIRMWARE_ATF_NAME}
		export CROSS_COMPILE="${ARMDEV_CROSS_COMPILE}"

		if [[ ${CLEAN} =~ (^|,)firmware(,|$) ]] ; then
			echo "Clean ATF directory"
			make clean
			rm -rf ./build/${FIRMWARE_ATF_PLAT}/*
		fi

        	make PLAT=${FIRMWARE_ATF_PLAT} DEBUG=1 bl31
		cp ./build/${FIRMWARE_ATF_PLAT}/debug/bl31.bin ${UBOOT_SOURCE_DIR}/
		SUNXI_ATF_USED="yes"

		echo "*** SCP firmware ***"
		cd ${FIRMWARE_BASE_DIR}/${FIRMWARE_SCP_NAME}
		export CROSS_COMPILE="${OPENRISC_CROSS_COMPILE}"

		if [[ ${CLEAN} =~ (^|,)firmware(,|$) ]] ; then
                        echo "Clean SCP directory"
                        make clean
                        rm -rf ./build/*
                fi

		make ${FIRMWARE_SCP_CONFIG}
		make scp
		cp ./build/scp/scp.bin ${UBOOT_SOURCE_DIR}/
    	  	;;
	esac

	echo "Done."
}
