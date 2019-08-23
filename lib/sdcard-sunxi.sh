#!/bin/bash

########################################################################
# sdcard-sunxi.sh
#
# Description:	Allwinner-specific part of the image creation scenario
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


format_disk()
{
        # Make sure it's not mounted
	sudo umount ${BLOCK_DEV}* 2> /dev/null

	# To be on safe side erase the first part of your SD Card (also clears the partition table)
	sudo dd if=/dev/zero of=$BLOCK_DEV bs=1M count=1

	sudo parted -s $BLOCK_DEV \
			mklabel msdos \
			mkpart primary ext4 1M 100%
	[ $? -eq 0 ] || exit $?;

	sudo mkfs.ext4 -F ${BLOCK_DEV}${P}1
	[ $? -eq 0 ] || exit $?;

        echo "${DISK_NAME} has been partitioned & formatted."
}

#-----------------------------------------------------------------------

write_image()
{
	echo "Copy files to ${DISK_NAME}..."

	# write u-boot binary
	sudo dd if=${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin of=$BLOCK_DEV bs=1024 seek=8

	# copy rootfs files
        sudo mkdir -p /mnt/sdcard
        sudo mount ${BLOCK_DEV}${P}1 /mnt/sdcard
        sudo rsync -a --stats $ROOTFS_DIR/ /mnt/sdcard

	local BOOTPARTID=$(sudo blkid -o value -s UUID ${BLOCK_DEV}${P}1)

	# update /etc/fstab with the actual partition UUID
	sudo sed -i "s/BOOTPARTID/UUID=${BOOTPARTID}/g" /mnt/sdcard/etc/fstab

        sudo umount ${BLOCK_DEV}${P}1

        echo "${DISK_NAME} write finished."
}
