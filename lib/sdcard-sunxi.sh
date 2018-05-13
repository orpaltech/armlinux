#!/bin/bash


#------------------------------------------------------------------------

prepare_disk()
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

#------------------------------------------------------------------------

write_image()
{
	echo "Copy files to ${DISK_NAME}..."

	# write u-boot binary
	sudo dd if=${UBOOT_SOURCE_DIR}/u-boot-sunxi-with-spl.bin of=$BLOCK_DEV bs=1024 seek=8

	# copy rootfs files
        sudo mkdir -p /mnt/sdcard
        sudo mount ${BLOCK_DEV}${P}1 /mnt/sdcard
        sudo rsync -a --stats $ROOTFS_DIR/ /mnt/sdcard

	local BOOT_PART_ID=$(sudo blkid -o value -s UUID ${BLOCK_DEV}${P}1)

	# update /etc/fstab with the actual partition UUID
	sudo sed -i "s/BOOTPARTID/UUID=${BOOT_PART_ID}/g" /mnt/sdcard/etc/fstab

        sudo umount ${BLOCK_DEV}${P}1

        echo "${DISK_NAME} write finished."
}

#------------------------------------------------------------------------
