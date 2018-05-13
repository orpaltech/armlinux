#!/bin/bash

#------------------------------------------------------------------------

prepare_disk()
{
        # makes sure it's not mounted
        sudo umount ${BLOCK_DEV}* 2> /dev/null

	sudo parted -s $BLOCK_DEV \
			mklabel msdos \
			mkpart primary fat32 1M 80M \
			mkpart primary ext4 80M 100%
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

	sudo mkdir -p /mnt/sdcard
	sudo mount ${BLOCK_DEV}${P}2 /mnt/sdcard
	sudo mkdir -p /mnt/sdcard/boot/firmware
	sudo mount ${BLOCK_DEV}${P}1 /mnt/sdcard/boot/firmware
	sudo rsync -a --stats ${ROOTFS_DIR}/ /mnt/sdcard
	sudo umount ${BLOCK_DEV}${P}*

        echo "${DISK_NAME} is ready."
}

#------------------------------------------------------------------------
