#!/bin/bash

########################################################################
# create-image.sh
#
# Description:	The entry point of the disk image creation scenario
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

if [ -f "${LIBDIR}/image-${SOC_FAMILY}.sh" ] ; then
. ${LIBDIR}/image-${SOC_FAMILY}.sh
else
  echo "error: image creation script not found for ${SOC_FAMILY}!"
  exit 1
fi

#-----------------------------------------------------------------------

create_debian_image()
{
  if [ -n "${DEBIAN_RELEASE}" ] ; then
    display_alert "Prepare disk image..." "${SOC_FAMILY} | ${SOC_ARCH} | ${BOARD} | ${DEBIAN_RELEASE}" "info"

    cd ${LIBDIR}/

    sudo mkdir -p ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/
    sudo rm -rf ${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build

    sudo  CONFIG=${CONFIG} \
	  CLEAN=${CLEAN} \
	  BOARD=${BOARD} \
	  ROOTFS=${ROOTFS} \
	  TOOLCHAINDIR=${TOOLCHAINDIR} \
	  OUTPUTDIR=${OUTPUTDIR} \
	  BOOTLOADER=${BOOTLOADER} \
	  UBOOT_SOURCE_DIR=${UBOOT_SOURCE_DIR} \
	  KERNEL_VERSION=${KERNEL_VERSION} \
	  KERNEL_SOURCE_DIR=${KERNEL_SOURCE_DIR} \
	  KERNEL_DEB_PKG_VER=${KERNEL_DEB_PKG_VER} \
	  FIRMWARE_DIR=${FIRMWARE_BASE_DIR} \
	  ENABLE_WLAN=${ENABLE_WLAN} \
	  PROD_FULL_VERSION=${PROD_FULL_VERSION} \
	  DEBIAN_RELEASE=${DEBIAN_RELEASE} \
    ${LIBDIR}/customize-image.sh

    [ $? -eq 0 ] || exit $?;


    ROOTFS_DIR="${OUTPUTDIR}/images/${DEBIAN_RELEASE}/build/chroot"

    DEST_IMG_PREFIX=${DEST_IMG_PREFIX:="${CONFIG}"}
    DEST_IMG_VERSION=${DEST_IMG_VERSION:="${PROD_FULL_VERSION}"}

    if [ "${DEST_DEV_TYPE}" = img ] ; then

      # Override image name if U-Boot is used as bootloader
      if [ "${BOOTLOADER}" = uboot ] ; then
        local uboot_spec="-uboot_${UBOOT_RELEASE}"
      fi
      local kernel_spec="${KERNEL_REPO_NAME}_${KERNEL_VERSION}"

      local img_name="${DEST_IMG_PREFIX}-${DEST_IMG_VERSION}-${BOARD}-${kernel_spec}${uboot_spec}-${DEBIAN_RELEASE}"
      local img_file="${OUTPUTDIR}/images/${img_name}.img"

      # calculate directory size
      local block_size=1024
      local rootfs_size=$(sudo du --block-size=1 --max-depth=0 ${ROOTFS_DIR} 2>/dev/null | tail -n 1 | tr -dc '0-9')

      # Find number of blocks needed, add around 200MB extra space
      local mbyte=1048576
      local blocks_count=$(((rootfs_size + (mbyte * 200)) / block_size))
      local img_size=$((blocks_count * block_size))

      echo "Create img file [rootfs size=${rootfs_size}; image size=${img_size}, block size=${block_size}, blocks=${blocks_count}]"

      [[ -f ${img_file} ]] && sudo rm -f ${img_file}

      sudo fallocate -l ${img_size} ${img_file}

      BLOCK_DEV=$(sudo losetup --show -f ${img_file})
      DISK_NAME="Loop device"
      P="p"

      echo "Loop device ${BLOCK_DEV} allocated for image file ${img_file}"

    elif [ "${DEST_DEV_TYPE}" = sd ] ; then

      # Write directly to Flash card
      BLOCK_DEV="${DEST_BLOCK_DEV}"
      DISK_NAME="SD-card"
      [[ $BLOCK_DEV =~ ^/dev/mmcblk[0-9]+$ ]] && P="p"

      while [ ! -e ${BLOCK_DEV} ];
      do
        pause "Make sure your card is attached to the reader. Press press any key to continue..."
      done

      local ticks=5
      echo "*** Disk operation starts in ${ticks} sec"
      while [ ${ticks} -gt 0 ]; do
        ticks=$((ticks-1))
        sleep 1
        echo "*** Disk operation starts in ${ticks} sec"
      done

    else
      echo "error: unknown image destination!"
      exit 1
    fi

    format_disk

    write_image

    # Release loop device
    if [[ $BLOCK_DEV =~ ^/dev/loop[0-9]+$ ]] ; then
      sudo losetup -d ${BLOCK_DEV}
    fi
  fi
}

create_image()
{
	if [ "${ROOTFS}" = debian ] ; then
		create_debian_image
	fi
}
