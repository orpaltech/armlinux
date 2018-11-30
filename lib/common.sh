#!/bin/bash

########################################################################
# common.sh
#
# Description:	This file contains functions used in build scripts.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2018 ORPAL Technology, Inc.
#
########################################################################

# common clean options, can be overriden in board-specific config files
CLEAN_OPTIONS="uboot firmware kernel rootfs qt5"

# ----------------------------------------------------------------------
# void display_alert(message, outline, type)
# ----------------------------------------------------------------------
display_alert()
{
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

# ----------------------------------------------------------------------
sudo_init()
{
  # Ask for the administrator password upfront
  sudo -v
  [[ $? != 0 ]] && exit 1

  # Keep-alive: update existing `sudo` timestamp until the calling script has finished
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

# ----------------------------------------------------------------------
pause()
{
  local PAUSE_MSG=$1
  local PAUSE_MSG=${PAUSE_MSG:="Press any key to continue or Ctrl+C to exit..."}
  echo "$PAUSE_MSG"
  read -n1 -rs
}

# ----------------------------------------------------------------------
count_files()
{
  local FILE_PATH=$1
  local FILE_COUNT=$(ls $FILE_PATH 2> /dev/null | wc -l)
  echo "$FILE_COUNT"
}
