#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Clean options"
LABEL_CHECKLIST="Select components you want to clean:"

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
		--checklist "${LABEL_CHECKLIST}" 24 42 16 \
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
