#!/bin/bash

########################################################################
# write-image.sh
#
# Description:	The functions for the image creation.
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


if [ -f "${LIBDIR}/image-${SOC_FAMILY}.sh" ] ; then
. ${LIBDIR}/image-${SOC_FAMILY}.sh
else
	echo "error: image creation script not found for ${SOC_FAMILY}!"
	exit 1
fi


write_image()
{
    if [ "${DEST_MEDIA}" = img ] ; then

	local img_name="${DEST_IMAGE_NAME}"
	local img_file="${OUTPUTDIR}/images/${img_name}.img"

	# calculate directory size
	local block_size=1024
	local rootfs_size=$(sudo du --block-size=1 --max-depth=0 ${ROOTFS_DIR} 2>/dev/null | tail -n 1 | tr -dc '0-9')

	# Find number of blocks needed, add around 100MB extra space
	local mbyte=1048576
	local blocks_count=$(((rootfs_size + (mbyte * 100)) / block_size))
	local img_size=$((blocks_count * block_size))

	echo "Create img file [rootfs size=${rootfs_size}; image size=${img_size}, block size=${block_size}, blocks=${blocks_count}]"

	[[ -f ${img_file} ]] && sudo rm -f ${img_file}

	sudo fallocate -l ${img_size} ${img_file}

	BLOCK_DEV=$(sudo losetup --show -f ${img_file})
	DISK_NAME="Loop device"
        P="p"

        echo "Loop device ${BLOCK_DEV} allocated for image file ${img_file}"

    elif [ "${DEST_MEDIA}" = dev ] ; then
	#
	# Write directly to a physical disk
	#
	if [ "${DEST_DEV_TYPE}" = mmc ]; then
		DISK_NAME="SD-card"
	elif [ "${DEST_DEV_TYPE}" = nvme ]; then
		DISK_NAME="NVME disk"
	fi

	BLOCK_DEV="${DEST_BLOCK_DEV}"
	if [[ $BLOCK_DEV =~ ^/dev/nvme[0-9]+n[1-9]+$ ]]; then
		P="p"
	elif [[ $BLOCK_DEV =~ ^/dev/mmcblk[0-9]+$ ]]; then
		P="p"
	else
		P=
	fi

	if [ ! -e ${BLOCK_DEV} ] ; then
		echo "!!!!!!!!! Make sure your disk is attached to the reader !!!!!!!!!"
		pause
	else
		local ticks=5
		echo "*** Disk operation starts in ${ticks} sec"
		while [ ${ticks} -gt 0 ]; do
			ticks=$((ticks-1))
			sleep 1
			echo "*** Disk operation starts in ${ticks} sec"
		done
	fi

    else
	echo "error: unknown media type!"
	exit 1
    fi

    format_disk

    write_disk

    # Release loop device
    if [[ $BLOCK_DEV =~ ^/dev/loop[0-9]+$ ]] ; then
	sudo losetup -d ${BLOCK_DEV}
    fi
}
