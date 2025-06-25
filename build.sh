#!/bin/bash

########################################################################
# build.sh
#
# Description:	Main script for Armlinux build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2024 ORPAL Technology, Inc.
#
########################################################################


BASEDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
SRCDIR=${BASEDIR}/sources
LIBDIR=${BASEDIR}/lib
CONFIGDIR=${BASEDIR}/config
TOOLCHAINDIR=${BASEDIR}/toolchains
OUTPUTDIR=${BASEDIR}/output
LOGDIR=${BASEDIR}/logs
DEFAULT_CONFIG="armlinux"

. ${LIBDIR}/common.sh
. ${LIBDIR}/packages-update.sh

# ensure folder exists for debug logger
mkdir -p ${LOGDIR}/debug

# start background sudo monitor
display_alert "This script requires root privileges, entering sudo" "" "warn"

sudo_init

# ensure all required packages are installed
get_host_pkgs

#------------------------------------------------------------------------------

if [ -z "${CONFIG}" ] ; then
. ${LIBDIR}/ui/config-select.sh
fi
ARMLINUX_CONF=${CONFIGDIR}/product/${CONFIG}.conf
if [ ! -f ${ARMLINUX_CONF} ] ; then
  display_alert "No config file found. Cannot continue." "${ARMLINUX_CONF}" "err"
  exit 1
fi

set -x

. ${ARMLINUX_CONF}

if [ -f ${BASEDIR}/wlan ] ; then
. ${BASEDIR}/wlan
fi

if [ -z "${PROD_BUILD}" ] ; then
  PROD_BUILD=$(( $(date +%s) / 3600 - 474709 ))
fi
PRODUCT_FULL_VER=${PRODUCT_VERSION}-${PRODUCT_BUILD}
# aliases
VERSION=${PRODUCT_VERSION}


# directory for building extra-packages
EXTRADIR=${BUILD_EXTRA_DIR:="${BASEDIR}/extra"}

set +x
#------------------------------------------------------------------------------
# board configuration
if [ -z "${BOARD}" ] ; then
. ${LIBDIR}/ui/board-select.sh
elif [ -n "${BOARDS_SUPPORTED}" ] && [[ ! ${BOARDS_SUPPORTED} =~ (^|,)${BOARD}(,|$) ]] ; then
  echo "error: board not supported by configuration!"
  exit 1
fi
if [ -z "${BOARD}" ] ; then
  echo "error: board must be specified!"
  exit 1
fi
BOARD_CONF="${LIBDIR}/boards/${CONFIG}/${BOARD}.conf"
if [ ! -f ${BOARD_CONF} ] ; then
  BOARD_CONF="${LIBDIR}/boards/${BOARD}.conf"
fi
if [ -f ${BOARD_CONF} ] ; then
. ${BOARD_CONF}
else
  echo "error: Board ${BOARD} is not supported!"
  exit 1
fi

# select bootloader
if [ -z "${BOOTLOADER}" ] ; then
. $LIBDIR/ui/bootload-select.sh
fi
if [[ ! ${BOOTLOAD_OPTIONS[@]} =~ $BOOTLOADER ]] ; then
  echo "error: unknown bootloader '${BOOTLOADER}'"
  exit 1
fi

ROOTFS_OPTIONS="debian busybox"
# select rootfs
if [ -z "${ROOTFS}" ] ; then
. $LIBDIR/ui/rootfs-select.sh
fi
if [[ ! ${ROOTFS_OPTIONS[@]} =~ $ROOTFS ]] ; then
  echo "error: unknown rootfs '${ROOTFS}'"
  exit 1
fi

if [ "${ROOTFS}" = debian ] ; then
  FILESDIR=$LIBDIR/files/debian
  if [ -f ${FILESDIR}/${CONFIG}/common/debootstrap/debian_releases ] ; then
	debian_releases_file="${FILESDIR}/${CONFIG}/common/debootstrap/debian_releases"
  else
	debian_releases_file="${FILESDIR}/generic/common/debootstrap/debian_releases"
  fi

  DEBIAN_OPTIONS=$(sed '1!d' ${debian_releases_file})
  DEBIAN_STATES=$(sed '2!d' ${debian_releases_file})
  DEBIAN_SUPPORTS=$(sed '3!d' ${debian_releases_file})

  # select debian release
  if [ -z "${DEBIAN_RELEASE}" ] ; then
. $LIBDIR/ui/debian-select.sh
  fi

  if [[ ! ${DEBIAN_OPTIONS[@]} =~ $DEBIAN_RELEASE ]] ; then
    echo "error: unknown debian release '${DEBIAN_RELEASE}'"
    exit 1
  fi
else
  FILESDIR=$LIBDIR/files/busybox
fi

# git mirror server root
GIT_MIRROR_ROOT=${GIT_MIRROR_ROOT:=""}

# clean options
[[ "${BOOTLOADER}" = uboot ]] && CLEAN_OPTIONS="uboot ${CLEAN_OPTIONS}"
[[ "${ENABLE_MESA}" = yes ]] && CLEAN_OPTIONS="${CLEAN_OPTIONS} mesa"
[[ "${ENABLE_QT}" = yes ]] && CLEAN_OPTIONS="${CLEAN_OPTIONS} qt"
[[ "${ENABLE_BTH}" = yes ]] && CLEAN_OPTIONS="${CLEAN_OPTIONS} bluetooth"
[[ "${ENABLE_SOUND}" = yes ]] && CLEAN_OPTIONS="${CLEAN_OPTIONS} sound"
[[ "${ENABLE_SDR}" = yes ]] && CLEAN_OPTIONS="${CLEAN_OPTIONS} sdr"
if [ -z "${CLEAN}" ] ; then
. $LIBDIR/ui/clean-options.sh
fi

#------------------------------------------------------------------------------

BUILD_IMAGE=${BUILD_IMAGE:="yes"}

# destination to write a image to, possible values are "dev" or "img"
DEST_MEDIA=${DEST_MEDIA:="img"}
DEST_DEV_TYPE=${DEST_DEV_TYPE:="mmc"}
# destination block device in form /dec/sdX, required
DEST_BLOCK_DEV=${DEST_BLOCK_DEV:="/dev/mmcblk0"}

# check image destination
if ! [[ ${DEST_MEDIA} =~ ^(img|dev)$ ]] ; then
  echo "error: DEST_MEDIA has unsupported value '${DEST_MEDIA}'!"
  exit 1
fi
if [ "${DEST_MEDIA}" = dev ] && [ -z "${DEST_BLOCK_DEV}" ] ; then
  echo "error: DEST_BLOCK_DEV must be specified!"
  exit 1
fi
if ! [[ ${DEST_DEV_TYPE} =~ ^(mmc|nvme)$ ]] ; then
  echo "error: DEST_DEV_TYPE has unsupported value '${DEST_DEV_TYPE}'!"
  exit 1
fi

#------------------------------------------------------------------------------

if [ ! -f ${LIBDIR}/toolchains.sh ] ; then
  echo "error: configuration script not found for toolchains"
  exit 1
fi
. ${LIBDIR}/toolchains.sh
TOOLCHAIN_FORCE_UPDATE=${TOOLCHAIN_FORCE_UPDATE:="no"}

get_toolchains

set_cross_compile

if [ ! -f "${CROSS_COMPILE}gcc" ] ; then
  echo "error: toolchain not found [${CROSS_COMPILE}] !"
  exit 1
fi

if [ ! -f ${LIBDIR}/meson-build.sh ] ; then
  echo "error: configuration script not found for meson build"
  exit 1
fi
. ${LIBDIR}/meson-build.sh

#------------------------------------------------------------------------------

if [ -z "${UBOOT_REPO_TAG}" ] ; then
  UBOOT_REPO_TAG="v${UBOOT_RELEASE}"
elif [ "${UBOOT_REPO_BRANCH}" = no ] ; then
  UBOOT_REPO_TAG=
fi
[ -z "${UBOOT_REPO_BRANCH}" ] && UBOOT_REPO_BRANCH="master"

KERNEL_RELEASE="v${KERNEL_VER_MAJOR}.${KERNEL_VER_MINOR}"
if [ -z "${KERNEL_REPO_TAG}" ] ; then
  KERNEL_REPO_TAG="${KERNEL_RELEASE}${KERNEL_VER_BUILD}"
elif [ "${KERNEL_REPO_TAG}" = no ] ; then
  KERNEL_REPO_TAG=
fi
[ -z "${KERNEL_REPO_BRANCH}" ] && KERNEL_REPO_BRANCH="master"

# declare firmware directories
[ -z "${FIRMWARE_NAME}" ] && FIRMWARE_NAME="${SOC_FAMILY}"
FIRMWARE_BASE_DIR=${SRCDIR}/firmware

# declare directories for u-boot & kernel
UBOOT_BASE_DIR=${SRCDIR}/u-boot/${UBOOT_REPO_NAME}
KERNEL_ROOT_DIR=${SRCDIR}/linux

if [ -z "${KERNEL_BUILD_BOARD_CONFIG}" ] ; then
  KERNEL_BUILD_BOARD_CONFIG="linux-${SOC_FAMILY}-${SOC_ARCH}-${BOARD}.config"
fi

#------------------------------------------------------------------------------

# source library scripts
. ${LIBDIR}/compile.sh

display_alert "Build configuration:" "${CONFIG}" "info"
display_alert "Selected platform:" "${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])" "info"

# prepare build environment
TICKS_BEGIN=$(date '+%s')
DATETIME_BEGIN=$(date '+%d/%m/%Y %H:%M:%S')

# start build sequence
update_firmware

update_bootloader
patch_bootloader

update_kernel
patch_kernel


# build u-boot, kernel, firmware
compile_firmware
compile_bootloader
compile_kernel


# prepare meson build tool
meson_install


DEST_IMG_PREFIX=${DEST_IMG_PREFIX:="${CONFIG}"}
DEST_IMG_VERSION=${DEST_IMG_VERSION:="${PRODUCT_FULL_VER}"}

# Override image name if U-Boot is used as bootloader
if [ "${BOOTLOADER}" = uboot ] ; then
  DEST_UBOOT_SPEC="-uboot_${UBOOT_RELEASE}"
fi
DEST_KERNEL_SPEC="${KERNEL_REPO_NAME}_${KERNEL_VERSION}"

if [ -f ${LIBDIR}/create-image-${ROOTFS}.sh ] ; then
. ${LIBDIR}/create-image-${ROOTFS}.sh
else
  echo "error: image creation script not found for ${ROOTFS} rootfs!"
  exit 1
fi
. ${LIBDIR}/write-image.sh

if [ "${BUILD_IMAGE}" = yes ] ; then

  # create disk image
  create_image

  # write image to media
  write_image
fi

# build finished
DATETIME_END=$(date '+%d/%m/%Y %H:%M:%S')
TICKS_END=$(date '+%s')
DURATION=$((TICKS_END - TICKS_BEGIN))

display_alert "Build finished" "${DATETIME_BEGIN} - ${DATETIME_END} | $(($DURATION / 60))m $(($DURATION % 60))s elapsed" "info"
