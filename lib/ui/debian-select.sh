#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="DEBIAN Release"
LABEL_MENU="Select the desired release to install:"

if [ -z "${DEBIAN_OPTIONS}" ] ; then
	echo "Debian release options not specified!"
	exit 1
fi

# convert the string into array
DEBIAN_OPTIONS=(`echo ${DEBIAN_OPTIONS}`)
DEBIAN_STATES=(`echo ${DEBIAN_STATES}`)
DEBIAN_SUPPORTS=(`echo ${DEBIAN_SUPPORTS}`)

declare -a debian_options

deb_index=0
arr_index=0
for opt in "${DEBIAN_OPTIONS[@]}" ; do
	debian_options[$deb_index]=$opt
	((deb_index++))
	debian_options[$deb_index]=$(printf '%-14s [ %-10s ]' "${DEBIAN_STATES[$arr_index]}" "${DEBIAN_SUPPORTS[$arr_index]}")
	((deb_index++))
	((arr_index++))
done

DEBIAN_RELEASE=$(dialog	--clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--menu "${LABEL_MENU}" 16 52 16 \
		"${debian_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
