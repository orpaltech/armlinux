#!/bin/bash

# HEIGHT=15
# WIDTH=40
# CHOICE_HEIGHT=4
# BACKTITLE="ORPALTECH ARM LINUX v1.0"
# TITLE="Select board"
# MENU="Choose one of the supported boards:"

declare -a board_options

board_index=0
for board_conf in ${LIBDIR}/boards/*.conf; do
	board_key=$(basename $board_conf .conf)
	board_name=$(sed -n 's/^BOARD_NAME=\([^ ]\+\)/\1/p' $board_conf)
	soc_name=$(sed -n 's/^SOC_NAME=\([^ ]\+\)/\1/p' $board_conf)
	board_options[$board_index]="${board_key}"
	((board_index++))
	board_options[$board_index]="${board_name} (SoC: ${soc_name})"
	((board_index++))
done

BOARD=$(dialog  --clear \
		--backtitle "ORPALTECH ARM Linux v1.0" \
		--title "Select board" \
		--menu "Choose one of the supported boards:" \
		24 102 16 \
		"${board_options[@]}" \
		2>&1 >/dev/tty)

clear
