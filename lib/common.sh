#!/bin/bash

# ------------------------------------------------------------------------------
# Let's have unique way of displaying alerts
#
# void display_alert(message, outline, type)
# ------------------------------------------------------------------------------
display_alert() {
	# log function parameters to install.log
	[[ -n ${LOG_DEST} ]] && echo "Displaying message: $@" >> ${LOG_DEST}/debug/output.log

	local tmp=""
	[[ -n ${2} ]] && tmp="[\e[0;33m ${2} \x1B[0m]"

	case ${3} in
		err)
		echo -e "[\e[0;31m error \x1B[0m] ${1} $tmp"
		;;

		wrn)
		echo -e "[\e[0;35m warn \x1B[0m] ${1} $tmp"
		;;

		ext)
		echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m${1}\x1B[0m ${tmp}"
		;;

		info)
		echo -e "[\e[0;32m o.k. \x1B[0m] ${1} ${tmp}"
		;;

		*)
		echo -e "[\e[0;32m .... \x1B[0m] ${1} ${tmp}"
		;;
	esac
}

# ------------------------------------------------------------------------------
sudo_init() {
    # Ask for the administrator password upfront
    sudo -v
    [[ $? != 0 ]] && exit 1

    # Keep-alive: update existing `sudo` timestamp until the calling script has finished
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

# ------------------------------------------------------------------------------
pause() {
        PAUSE_MSG=$1
        PAUSE_MSG=${PAUSE_MSG:="Press any key to continue or Ctrl+C to exit..."}
        echo "${PAUSE_MSG}"
        read -n1 -rs
}
