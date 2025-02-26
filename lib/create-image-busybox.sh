#!/bin/bash

########################################################################
# create-image-busybox.sh
#
# Description:	The functions for the busybox image creation.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2024-2025 ORPAL Technology, Inc.
#
########################################################################


create_image()
{
	display_alert "Prepare SD-card image..." "${SOC_FAMILY} | ${SOC_ARCH} | ${BOARD} | busybox" "info"

	cd ${LIBDIR}/

	sudo mkdir -p ${OUTPUTDIR}/images/busybox/
	sudo rm -rf ${OUTPUTDIR}/images/busybox/build

	sudo	CONFIG=${CONFIG} \
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
		KERNEL_DEB_PKG_VER=${KERNEL_DEB_PKG_VER} \
		FIRMWARE_DIR=${FIRMWARE_BASE_DIR} \
		ENABLE_WLAN=${ENABLE_WLAN} \
		ENABLE_SOUND=${ENABLE_SOUND} \
		ENABLE_BTH=${ENABLE_BTH} \
		ENABLE_SDR=${ENABLE_SDR} \
		RESIZE_PART_NUM=${RESIZE_PART_NUM} \
		DEST_MEDIA=${DEST_MEDIA} \
		DEST_DEV_TYPE=${DEST_DEV_TYPE} \
		DEST_BLOCK_DEV=${DEST_BLOCK_DEV} \
	${LIBDIR}/generate-busybox.sh

	[ $? -eq 0 ] || exit $?;


	ROOTFS_DIR="${OUTPUTDIR}/images/busybox/build/chroot"

	DEST_IMG_PREFIX=${DEST_IMG_PREFIX:="${CONFIG}"}
	DEST_IMG_VERSION=${DEST_IMG_VERSION:="${PRODUCT_FULL_VER}"}

        # Override image name if U-Boot is used as bootloader
	if [ "${BOOTLOADER}" = uboot ] ; then
		local UBOOT_SPEC="-uboot_${UBOOT_RELEASE}"
        fi
	local KERNEL_SPEC="${KERNEL_REPO_NAME}_${KERNEL_VERSION}"

	DEST_IMAGE_NAME="${DEST_IMG_PREFIX}-${DEST_IMG_VERSION}-${BOARD}-${KERNEL_SPEC}${UBOOT_SPEC}-busybox"

}
