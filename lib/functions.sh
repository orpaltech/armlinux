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
