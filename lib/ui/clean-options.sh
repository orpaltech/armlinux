#!/bin/bash

# common clean options, can be overriden in board-specific config files
CLEAN_OPTIONS="bootloader firmware kernel rootfs ${CLEAN_OPTIONS}"

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Clean Options"
LABEL_CHECKLIST="Select components to clean:"

if [ -z "${CLEAN_OPTIONS}" ] ; then
	echo "Clean options not specified!"
	exit 1
fi

# convert the string into array
CLEAN_OPTIONS=(`echo ${CLEAN_OPTIONS}`)

declare -a clean_options

opt_index=0
for opt in "${CLEAN_OPTIONS[@]}" ; do
        clean_options[$opt_index]=$opt
	((opt_index++))
	clean_options[$opt_index]=$opt
	((opt_index++))
	clean_options[$opt_index]="off"
	((opt_index++))
done

CLEAN=$(dialog	--clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--notags \
		--checklist "${LABEL_CHECKLIST}" 24 38 16 \
		"${clean_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -eq 0 ] ; then
	if [ ! -z "${CLEAN}" ] ; then
		CLEAN=$(echo "${CLEAN// /,}")
	fi
else
	echo "User cancelled"
	exit 1
fi
