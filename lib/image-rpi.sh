#!/bin/bash

########################################################################
# sdcard-rpi.sh
#
# Description:	RaspberryPi-specific part of the image creation.
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

RESIZE_PART_NUM=2


format_disk()
{
        # makes sure it's not mounted
        sudo umount ${BLOCK_DEV}* 2> /dev/null

	sudo parted -s ${BLOCK_DEV} \
			mklabel msdos \
			mkpart primary fat32 4MiB 120MiB \
			mkpart primary ext4 120MiB 100%
	[ $? -eq 0 ] || exit $?;

	sudo mkfs.vfat ${BLOCK_DEV}${P}1
	[ $? -eq 0 ] || exit $?;

	sudo mkfs.ext4 -F ${BLOCK_DEV}${P}2
	[ $? -eq 0 ] || exit $?;

        echo "${DISK_NAME} has been partitioned & formatted."
}

write_disk()
{
	echo "Copy files to ${DISK_NAME}..."

	local root_part="${BLOCK_DEV}${P}2"
	local boot_part="${BLOCK_DEV}${P}1"

	sudo mkdir -p		/mnt/sdcard
	sudo mount ${root_part}	/mnt/sdcard

	sudo mkdir -p		/mnt/sdcard/boot/firmware
	sudo mount ${boot_part}	/mnt/sdcard/boot/firmware

	sudo rsync -a --stats ${ROOTFS_DIR}/	/mnt/sdcard

	local root_uuid=$(sudo blkid -o value -s UUID	${root_part})
	local boot_uuid=$(sudo blkid -o value -s UUID	${boot_part})
	# update /etc/fstab with the actual partition UUID
	sudo sed -i "s/ROOTUUID/UUID=${root_uuid}/g"	/mnt/sdcard/etc/fstab
	sudo sed -i "s/BOOTUUID/UUID=${boot_uuid}/g"	/mnt/sdcard/etc/fstab

	local root_partuuid=$(sudo blkid -o value -s PARTUUID	${root_part})
	sudo sed -i "s/ROOTPART/PARTUUID=${root_partuuid}/g"	/mnt/sdcard/boot/firmware/bootEnv.txt
	sudo sed -i "s/ROOTPART/PARTUUID=${root_partuuid}/g"	/mnt/sdcard/boot/firmware/cmdline.txt

	sudo umount ${BLOCK_DEV}${P}*

        echo "${DISK_NAME} is ready."
}
