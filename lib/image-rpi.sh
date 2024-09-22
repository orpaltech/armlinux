#!/bin/bash

########################################################################
# image-rpi.sh
#
# Description:	RaspberryPi-specific part of the disk image scenario
#		for ORPALTECH ARMLINUX build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2024 ORPAL Technology, Inc.
#
########################################################################


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

write_image()
{
	echo "Copy files to ${DISK_NAME}..."

	sudo mkdir -p			/mnt/sdcard
	sudo mount ${BLOCK_DEV}${P}2	/mnt/sdcard

	sudo mkdir -p			/mnt/sdcard/${BOOT_DIR}
	sudo mount ${BLOCK_DEV}${P}1	/mnt/sdcard/${BOOT_DIR}

	sudo rsync -a -l --stats ${ROOTFS_DIR}/	/mnt/sdcard

        local ROOT_UUID=$(sudo blkid -o value -s UUID ${BLOCK_DEV}${P}2)
	local BOOT_UUID=$(sudo blkid -o value -s UUID ${BLOCK_DEV}${P}1)
        # update /etc/fstab with the actual partition UUID
        sudo sed -i "s/ROOTUUID/UUID=${ROOT_UUID}/g"	/mnt/sdcard/etc/fstab
	sudo sed -i "s/BOOTUUID/UUID=${BOOT_UUID}/g"	/mnt/sdcard/etc/fstab

        local ROOT_PARTUUID=$(sudo blkid -o value -s PARTUUID ${BLOCK_DEV}${P}2)
	if [ "${BOOTLOADER}" = uboot ] ; then
	  sudo sed -i "s/ROOTPARTUUID/PARTUUID=${ROOT_PARTUUID}/g" /mnt/sdcard/${BOOT_DIR}/bootEnv.txt
	else
	  sudo sed -i "s/ROOTPARTUUID/PARTUUID=${ROOT_PARTUUID}/g" /mnt/sdcard/${BOOT_DIR}/cmdline.txt
	fi

	sudo umount ${BLOCK_DEV}${P}*

        echo "${DISK_NAME} is ready."
}
