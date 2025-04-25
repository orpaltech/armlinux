#!/bin/bash

########################################################################
# common.sh
#
# Description:	This file contains functions used in build scripts.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


CPUINFO_NUM_CORES=$(grep -c ^processor /proc/cpuinfo)

# (!!!) Do not overload CPU, use only half of CPU cores
HOST_CPU_CORES=$((CPUINFO_NUM_CORES / 2))


[ ${SUDO_USER} ] && CURRENT_USER=${SUDO_USER} || CURRENT_USER=$(whoami)


GIT=${GIT:="git_retry"}

. ${LIBDIR}/git-utils.sh


# ----------------------------------------------------------------------
# void display_alert(message, outline, type)
# ----------------------------------------------------------------------

display_alert()
{
  # log function parameters
  [[ -n ${LOGDIR} ]] && echo "Message: $@" >> ${LOGDIR}/debug/output.log

  local tmp=""
  [[ -n ${2} ]] && tmp="[\e[0;33m ${2} \x1B[0m]"

  case ${3} in
    err)
      echo -e "[\e[0;31m error \x1B[0m] ${1} $tmp"
      ;;

    warn)
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

# ----------------------------------------------------------------------

fn_exists()
{
  declare -f -F $1 > /dev/null
  return $?
}

str_replace()
{
  local INPUT=$1
  local SRC=$2
  local DST=$3
  echo -e "${INPUT}" | tr "${SRC}" "${DST}"
}

make_array()
{
  local INPUT="$@"
  readarray -t temp_array < <(awk -F'[[:blank:],]' '{ for( i=1; i<=NF; i++ ) print $i }' <<<"${INPUT}")
}

ver_compare()
{
  if [[ $1 == $2 ]] ; then
    return 0
  fi

  local IFS=.
  local i ver1=($1) ver2=($2)

  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)) ; do
    ver1[i]=0
  done

  for ((i=0; i<${#ver1[@]}; i++)) ; do
    if ((10#${ver1[i]:=0} > 10#${ver2[i]:=0})) ; then
	return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]})) ; then
	return 2
    fi
  done

  return 0
}

. ${LIBDIR}/update-src-pkg.sh
