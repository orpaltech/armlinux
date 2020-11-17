#!/bin/bash

########################################################################
# create-image.sh
#
# Description:	The entry point of the image creation scenario
#		for ORPALTECH ARMLINUX build framework.
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


IMAGE_SCRIPT="${LIBDIR}/sdcard-${SOC_FAMILY}.sh"

if [ -f "${IMAGE_SCRIPT}" ] ; then
. $IMAGE_SCRIPT
else
  echo "error: image creation script not found for ${SOC_FAMILY}!"
  exit 1
fi

#-----------------------------------------------------------------------

create_image()
{
    if [ ! -z "${DEBIAN_RELEASE}" ] ; then
        display_alert "Prepare SD-card image..." "${SOC_FAMILY} | ${SOC_ARCH} | ${BOARD} | ${DEBIAN_RELEASE}" "info"

        cd ${LIBDIR}/

	sudo mkdir -p ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/
	sudo rm -rf ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build

        sudo	CONFIG=${CONFIG} \
		CLEAN=${CLEAN} \
		BOARD=${BOARD} \
		TOOLCHAINDIR=${TOOLCHAINDIR} \
		OUTPUTDIR=${OUTPUTDIR} \
		UBOOT_SOURCE_DIR=${UBOOT_SOURCE_DIR} \
		KERNEL_SOURCE_DIR=${KERNEL_SOURCE_DIR} \
		FIRMWARE_DIR=${FIRMWARE_SOURCE_DIR} \
	${LIBDIR}/image-gen.sh

	[ $? -eq 0 ] || exit $?;


	ROOTFS_DIR="${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build/chroot"


	if [ "${DEST_DEV_TYPE}" = img ] ; then

		local img_name="${DEST_IMG_PREFIX}-${DEST_VERSION}-${BOARD}-${KERNEL_REPO_NAME}-${KERNEL_VERSION}-${DEBIAN_RELEASE}"
		local img_file="${OUTPUTDIR}/images/${img_name}.img"

		# calculate directory size
		local block_size=1024
		local rootfs_size=$(sudo du --block-size=1 --max-depth=0 $ROOTFS_DIR 2>/dev/null | tail -n 1 | tr -dc '0-9')

		# Find number of blocks needed, add around 200MB extra space
		local mbyte=1048576
		local blocks_count=$(((rootfs_size + (mbyte * 200)) / block_size))
		local img_size=$((blocks_count * block_size))

		echo "Create img file [rootfs size=${rootfs_size}; image size=${img_size}, block size=${block_size}, blocks=${blocks_count}]"

		[[ -f $img_file ]] && sudo rm -f $img_file

		sudo fallocate -l $img_size $img_file

		BLOCK_DEV=$(sudo losetup --show -f $img_file)
		DISK_NAME="Loop device"
        	P="p"

                echo "Loop device ${BLOCK_DEV} allocated for image file ${img_file}"

	elif [ "${DEST_DEV_TYPE}" = sd ] ; then
		#
		# Write directly to SD-card
		#
		BLOCK_DEV="${DEST_BLOCK_DEV}"
		DISK_NAME="SD-card"
		[[ $BLOCK_DEV =~ ^/dev/mmcblk[0-9]+$ ]] && P="p"

                if [ ! -e $BLOCK_DEV ] ; then
                        echo "!!!!!!!!! Make sure your SD-card is attached to the reader !!!!!!!!!"
                        pause
                else
                        local ticks=5
                        echo "*** SD-card operation starts in ${ticks} sec"
                        while [ $ticks -gt 0 ]; do
                            ticks=$((ticks-1))
                            sleep 1
                            echo "*** SD-card operation starts in ${ticks} sec"
                        done
                fi

	else
		echo "error: unknown image destination!"
		exit 1
	fi

	format_disk

	write_image

	# Release loop device
	if [[ $BLOCK_DEV =~ ^/dev/loop[0-9]+$ ]] ; then
		sudo losetup -d $BLOCK_DEV
	fi
    fi
}
