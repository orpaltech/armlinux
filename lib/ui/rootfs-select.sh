#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Root File System"
LABEL_MENU="Select rootfs to install:"

if [ -z "${ROOTFS_OPTIONS}" ] ; then
	echo "Rootfs options not specified!"
	exit 1
fi

# convert the string into array
ROOTFS_OPTIONS=(`echo ${ROOTFS_OPTIONS}`)

declare -a rootfs_options

rootfs_index=0
for opt in "${ROOTFS_OPTIONS[@]}" ; do
        rootfs_options[$rootfs_index]=$opt
	((rootfs_index++))
	rootfs_options[$rootfs_index]=""
	((rootfs_index++))
done

ROOTFS=$(dialog	--clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--menu "${LABEL_MENU}" 16 32 16 \
		"${rootfs_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
