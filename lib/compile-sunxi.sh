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
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


FIRMWARE_ATF_SRC_DIR="${FIRMWARE_BASE_DIR}/${FIRMWARE_ATF_NAME}"
FIRMWARE_SCP_SRC_DIR="${FIRMWARE_BASE_DIR}/${FIRMWARE_SCP_NAME}"


update_firmware()
{
	if [ ! -z "${FIRMWARE_ATF_URL}" ] ; then
	    PKG_FORCE_CLEAN=yes \
		update_src_pkg $FIRMWARE_ATF_NAME \
				$FIRMWARE_ATF_VER \
				$FIRMWARE_ATF_SRC_DIR \
				$FIRMWARE_ATF_URL \
				$FIRMWARE_ATF_BRANCH \
				$FIRMWARE_ATF_TAG

	fi

	if [ ! -z "${FIRMWARE_SCP_URL}" ] ; then
	    PKG_FORCE_CLEAN=yes \
		update_src_pkg $FIRMWARE_SCP_NAME \
				$FIRMWARE_SCP_VER \
				$FIRMWARE_SCP_SRC_DIR \
				$FIRMWARE_SCP_URL \
				$FIRMWARE_SCP_BRANCH \
				$FIRMWARE_SCP_TAG
        fi
}

compile_firmware()
{
	display_alert "Make firmware" "${SOC_FAMILY} | ${SOC_PLATFORM}" "info"

	case ${SOC_PLATFORM} in
    	    sun50i*)
		echo "*** ARM trusted firmware ***"
		cd ${FIRMWARE_ATF_SRC_DIR}/
		export CROSS_COMPILE="${UBOOT_CROSS_COMPILE}"

		if [[ $CLEAN =~ (^|,)"firmware"(,|$) ]] ; then
			echo "Clean ATF directory"
			make clean
			rm -rf ./build/${FIRMWARE_ATF_PLAT}/*
		fi

        	make PLAT=${FIRMWARE_ATF_PLAT} DEBUG=1 bl31
		cp ./build/${FIRMWARE_ATF_PLAT}/debug/bl31.bin ${UBOOT_SOURCE_DIR}/
		SUNXI_ATF_USED="yes"

		echo "*** SCP firmware ***"
		cd ${FIRMWARE_SCP_SRC_DIR}/
		export CROSS_COMPILE="${OPENRISC_CROSS_COMPILE}"

		if [[ ${CLEAN} =~ (^|,)"firmware"(,|$) ]] ; then
                        echo "Clean SCP directory"
                        make clean
                        rm -rf ./build/*
                fi

		make ${FIRMWARE_SCP_CONFIG}
		make scp
		cp ./build/scp/scp.bin ${UBOOT_SOURCE_DIR}/
		unset CROSS_COMPILE
    	  	;;
	esac

	echo "Done."
}
