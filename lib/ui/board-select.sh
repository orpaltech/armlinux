#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Select board"
LABEL_MENU="Choose one of the supported boards:"

declare -a board_options

board_index=0
for board_conf in ${LIBDIR}/boards/*.conf; do
	board_key=$(basename $board_conf .conf)
	if [[ -z "${BOARDS_SUPPORTED}" ]] || [[ ${BOARDS_SUPPORTED} =~ (^|,)${board_key}(,|$) ]] ; then
		board_name=$(sed -n 's/^BOARD_NAME=\([^ ]\+\)/\1/p' $board_conf)
		soc_name=$(sed -n 's/^SOC_NAME=\([^ ]\+\)/\1/p' $board_conf)
		board_options[$board_index]="${board_key}"
		((board_index++))
		board_options[$board_index]="${board_name} (SoC: ${soc_name})"
		((board_index++))
	fi
done

BOARD=$(dialog  --clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--menu "${LABEL_MENU}" 24 110 16 \
		"${board_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
