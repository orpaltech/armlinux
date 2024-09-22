#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX [ ${CONFIG} v${VERSION} ]"
LABEL_TITLE="Target Board"
LABEL_MENU="Choose one of supported boards:"

declare -a board_options

board_index=0
for board_conf in ${LIBDIR}/boards/*.conf; do
	board_key=$(basename $board_conf .conf)
	if [[ -z "${BOARDS_SUPPORTED}" ]] || [[ ${BOARDS_SUPPORTED} =~ (^|,)${board_key}(,|$) ]] ; then
		board_conf_text=$(bash -v ${board_conf} 2>&1  >/dev/null)
		board_name=$(echo "$board_conf_text" | sed -n 's/^BOARD_NAME=\([^ ]\+\)/\1/p')
		soc_name=$(echo "$board_conf_text" | sed -n 's/^SOC_NAME=\([^ ]\+\)/\1/p')
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
		--menu "${LABEL_MENU}" 24 112 16 \
		"${board_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
