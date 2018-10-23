#!/bin/bash

LABEL_BACKTITLE="ORPALTECH ARM LINUX"
LABEL_TITLE="Build configuration"
LABEL_MENU="Choose one of the supported configurations:"

declare -a config_options

config_index=0
for config_file in $BASEDIR/*.conf; do
	config_key=$(basename $config_file .conf)
	config_name=$(sed -n 's/^DESCRIPTION=\([^ ]\+\)/\1/p' $config_file)
	config_options[$config_index]=$config_key
	((config_index++))
	config_options[$config_index]=$config_name
	((config_index++))
done

CONFIG=$(dialog	--clear \
		--shadow \
		--backtitle "${LABEL_BACKTITLE}" \
		--title "${LABEL_TITLE}" \
		--menu "${LABEL_MENU}" 24 72 16 \
		"${config_options[@]}" \
		2>&1 >/dev/tty)

if [ $? -ne 0 ] ; then
	echo "User cancelled"
	exit 1
fi
