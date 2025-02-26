#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Bootloader"
LABEL_MENU="Select the desired bootloader:"

if [ -z "${BOOTLOAD_OPTIONS}" ] ; then
	echo "Bootloader options not specified!"
	exit 1
fi

# convert the string into array
BOOTLOAD_OPTIONS=(`echo ${BOOTLOAD_OPTIONS}`)

declare -a bootload_options

bl_index=0
for opt in "${BOOTLOAD_OPTIONS[@]}" ; do
	bootload_options[$bl_index]=$opt
	((bl_index++))
	bootload_options[$bl_index]=""
	((bl_index++))
done

BOOTLOADER=$(dialog --clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--menu "${LABEL_MENU}" 16 38 16 \
		"${bootload_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
