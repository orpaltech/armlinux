#!/bin/bash

########################################################################
# image-sunxi.sh
#
# Description:	Allwinner-specific part of the image creation.
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

RESIZE_PART_NUM=1

format_disk()
{
        # Make sure it's not mounted
	sudo umount ${BLOCK_DEV}* 2> /dev/null

	# To be on safe side erase the first part of your SD Card (also clears the partition table)
	sudo dd if=/dev/zero of=${BLOCK_DEV} bs=1M count=1

	sudo parted -s ${BLOCK_DEV} \
			mklabel msdos \
			mkpart primary ext4 1M 100%
	[ $? -eq 0 ] || exit $?;

	sudo mkfs.ext4 -F ${BLOCK_DEV}${P}1
	[ $? -eq 0 ] || exit $?;

        echo "${DISK_NAME} has been partitioned & formatted."
}

#-----------------------------------------------------------------------

write_disk()
{
	echo "Copy files to ${DISK_NAME}..."

	# write u-boot binary
	sudo dd if=${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin of=${BLOCK_DEV} bs=1024 seek=8

	local root_part="${BLOCK_DEV}${P}1"

	# copy rootfs files
        sudo mkdir -p		/mnt/sdcard
        sudo mount ${root_part}	/mnt/sdcard

        sudo rsync -a --stats ${ROOTFS_DIR}/	/mnt/sdcard

	local root_uuid=$(sudo blkid -o value -s UUID ${root_part})
	# update /etc/fstab with the actual partition UUID
	sudo sed -i "s/ROOTUUID/UUID=${root_uuid}/g"	/mnt/sdcard/etc/fstab

	local root_partuuid=$(sudo blkid -o value -s PARTUUID ${root_part})
	sudo sed -i "s/ROOTPART/PARTUUID=${root_partuuid}/g" /mnt/sdcard/boot/bootEnv.txt

        sudo umount ${BLOCK_DEV}${P}*

        echo "${DISK_NAME} is ready."
}
