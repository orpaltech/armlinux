#!/bin/bash

########################################################################
# functions.sh
#
# Description:	This file contains functions used by image-gen.sh
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


cleanup()
{
  set +x
  set +e

  # Identify and kill all processes still using files
  echo "killing processes using mount point ..."
  fuser -k "${R}"
  sleep 3
  fuser -9 -k -v "${R}"

  # Clean up temporary .password file
  if [ -r ".password" ] ; then
    shred -zu .password
  fi

  # Clean up all temporary mount points
  echo "removing temporary mount points ..."
  umount -l "${R}/proc" 2> /dev/null
  umount -l "${R}/sys" 2> /dev/null
  umount -l "${R}/dev/pts" 2> /dev/null
  umount "$BUILDDIR/mount/boot/firmware" 2> /dev/null
  umount "$BUILDDIR/mount" 2> /dev/null
  losetup -d "$ROOT_LOOP" 2> /dev/null
  losetup -d "$FRMW_LOOP" 2> /dev/null
  trap - 0 1 2 3 6
}

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
