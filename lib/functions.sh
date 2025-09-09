#!/bin/bash

########################################################################
# functions.sh
#
# Description:	The functions used by the image generation.
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


chroot_exec()
{
  # Exec command in chroot
  LANG=C LC_ALL=C DEBIAN_FRONTEND=noninteractive chroot ${R} "$@"
}

install_readonly()
{
  # Install file with user read-only permissions
  install -o root -g root -m 644 $*
}

install_exec()
{
  # Install file with root exec permissions
  install -o root -g root -m 744 $*
}

copy_custom_files()
{
  local sub_path=$1
  local target_path=$2
  local ext=$3

  if [ -d "${sub_path}" ] ; then
    local num_files=$(count_files "${sub_path}/common/*${ext}")
    if [ ${num_files} -gt 0 ] ; then
      cp -R ${sub_path}/common/*  ${target_path}/
    fi

    num_files=$(count_files "${sub_path}/${SOC_FAMILY}/*${ext}")
    if [ ${num_files} -gt 0 ] ; then
      cp -R ${sub_path}/${SOC_FAMILY}/*  ${target_path}/
    fi

    num_files=$(count_files "${sub_path}/${SOC_FAMILY}/${BOARD}/*${ext}")
    if [ ${num_files} -gt 0 ] ; then
      cp -R ${sub_path}/${SOC_FAMILY}/${BOARD}/*  ${target_path}/
      rm -rf ${target_path}/${BOARD}
    fi
  fi
}
