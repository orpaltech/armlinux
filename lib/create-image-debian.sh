#!/bin/bash

########################################################################
# create-image-debian.sh
#
# Description:	The entry point of the image creation scenario
#		for ORPALTECH ARMLINUX build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


ROOTFS_DIR="${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build/chroot"

DEST_IMAGE_NAME="${DEST_IMG_PREFIX}-${DEST_IMG_VERSION}-${BOARD}-${DEST_KERNEL_SPEC}${DEST_UBOOT_SPEC}-${DEBIAN_RELEASE}"

create_image()
{
        display_alert "Prepare SD-card image..." "${SOC_FAMILY} | ${SOC_ARCH} | ${BOARD} | ${DEBIAN_RELEASE}" "info"

        cd ${LIBDIR}/

	sudo mkdir -p ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/
	sudo rm -rf ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build


        sudo    CONFIG=${CONFIG} \
                PRODUCT_FULL_VER=${PRODUCT_FULL_VER} \
                CLEAN=${CLEAN} \
                BOARD=${BOARD} \
                TOOLCHAINDIR=${TOOLCHAINDIR} \
                OUTPUTDIR=${OUTPUTDIR} \
                LOGDIR=${LOGDIR} \
                CONFIGDIR=${CONFIGDIR} \
                GIT_MIRROR_ROOT=${GIT_MIRROR_ROOT} \
                BOOTLOADER=${BOOTLOADER} \
                UBOOT_SOURCE_DIR=${UBOOT_SOURCE_DIR} \
                KERNEL_VERSION=${KERNEL_VERSION} \
                KERNEL_SOURCE_DIR=${KERNEL_SOURCE_DIR} \
		KERNEL_IMAGE_FILE=${KERNEL_IMAGE_FILE} \
                KERNEL_DEB_PKG_VER=${KERNEL_DEB_PKG_VER} \
                FIRMWARE_DIR=${FIRMWARE_BASE_DIR} \
		DEBIAN_RELEASE=${DEBIAN_RELEASE} \
                RESIZE_PART_NUM=${RESIZE_PART_NUM} \
                DEST_MEDIA=${DEST_MEDIA} \
                DEST_DEV_TYPE=${DEST_DEV_TYPE} \
                DEST_BLOCK_DEV=${DEST_BLOCK_DEV} \
                ENABLE_WLAN=${ENABLE_WLAN} \
                ENABLE_SOUND=${ENABLE_SOUND} \
                ENABLE_BTH=${ENABLE_BTH} \
                ENABLE_SDR=${ENABLE_SDR} \
	${LIBDIR}/generate-debian.sh

	[ $? -eq 0 ] || exit $?;

}
