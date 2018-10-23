#!/bin/bash

########################################################################
# build.sh
#
# Description:	Main script for ORPALTECH ARMLINUX build framework.
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


BASEDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
SRCDIR=$BASEDIR/sources
LIBDIR=$BASEDIR/lib
TOOLCHAINDIR=$BASEDIR/toolchains
OUTPUTDIR=$BASEDIR/output
DEFAULT_CONFIG="armlinux"

. $LIBDIR/common.sh
. $LIBDIR/update-packages.sh

# start background sudo monitor
display_alert "This script requires root privileges, entering sudo" "" "wrn"

sudo_init

# ensure all required packages are installed
get_host_pkgs

#-----------------------------------------------------------------------

if [ -z "${CONFIG}" ] ; then
. $LIBDIR/ui/config-select.sh
fi
ARMLINUX_CONF=$BASEDIR/${CONFIG}.conf
if [ ! -f $ARMLINUX_CONF ] ; then
    echo "No config file found. Cannot continue."
    exit 1
fi
set -x
. $ARMLINUX_CONF

set +x

if [ ! -d "${BUILD_EXTRA_DIR}" ] ; then
  echo "error: '${BUILD_EXTRA_DIR}' directory not found!"
  exit 1
fi

# board configuration
if [ -z "${BOARD}" ] ; then
. $LIBDIR/ui/board-select.sh
fi
if [ -z "${BOARD}" ] ; then
  echo "error: board must be specified!"
  exit 1
fi
BOARD_CONF="${LIBDIR}/boards/${BOARD}.conf"
if [ -f $BOARD_CONF ] ; then
. $BOARD_CONF
else
  echo "error: Board ${BOARD} is not supported!"
  exit 1
fi

# clean options
if [ -z "${CLEAN}" ] ; then
. $LIBDIR/ui/clean-options.sh
fi

# declare firmware directories
[[ -z "${FIRMWARE_NAME}" ]] && FIRMWARE_NAME="${SOC_FAMILY}"
FIRMWARE_BASE_DIR=${SRCDIR}/firmware
FIRMWARE_SOURCE_DIR=${FIRMWARE_BASE_DIR}/${FIRMWARE_NAME}

# declare directories for u-boot & kernel
UBOOT_BASE_DIR=${SRCDIR}/u-boot
KERNEL_BASE_DIR=${SRCDIR}/linux-${KERNEL_REPO_NAME}

# source library scripts
. ${LIBDIR}/update-sources.sh
. ${LIBDIR}/compile.sh
. ${LIBDIR}/create-image.sh


display_alert "Build configuration:" "${CONFIG}" "info"
display_alert "Selected platform:" "${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])" "info"

# prepare build environment
TICKS_BEGIN=${SECONDS}
DATETIME_BEGIN=$(date '+%d/%m/%Y %H:%M:%S')

update_toolchains

update_firmware

update_uboot

patch_uboot

update_kernel

patch_kernel

# build u-boot & kernel & optional firmware
display_alert "Selected toolchain:" "${CROSS_COMPILE}gcc" "ext"

compile_firmware

compile_uboot

compile_kernel


# create a SD-card image
create_image

# build finished
DATETIME_END=$(date '+%d/%m/%Y %H:%M:%S')
DURATION=$(( SECONDS - TICKS_BEGIN ))

display_alert "Build finished" "${DATETIME_BEGIN} - ${DATETIME_END} | $(($DURATION / 60))m $(($DURATION % 60))s elapsed" "info"
