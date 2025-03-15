#!/bin/bash
########################################################################
# generate-busybox.sh
#
# Description:	BUSYBOX-specific image generation script for
#		ORPALTECH ARMLINUX build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2024 ORPAL Technology, Inc.
#
########################################################################


# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: script must be executed with root privileges!"
  exit 1
fi

if [ -z "${CONFIG}" ] ; then
  echo "error: no config specified!"
  exit 1
fi

LIBDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
PATCHDIR=$(realpath -s "${LIBDIR}/../patch")
ARMLINUX_CONF=${LIBDIR}/../${CONFIG}.conf
WLAN_CONF=${LIBDIR}/../wlan

# IMPORTANT: Preserve variables that may be cleared by config
_BOARD_="${BOARD}"
_CLEAN_="${CLEAN}"

if [ ! -f ${ARMLINUX_CONF} ] ; then
  echo "error: config file not found!"
  exit 1
fi
. ${ARMLINUX_CONF}

if [ -f ${WLAN_CONF} ] ; then
. ${WLAN_CONF}
fi

BOARD=${BOARD:="${_BOARD_}"}
BOARD_CONF=${LIBDIR}/boards/${BOARD}.conf
CLEAN=${CLEAN:="${_CLEAN_}"}
BASEDIR=${OUTPUTDIR:="${LIBDIR}/../output"}
EXTRADIR=${BUILD_EXTRA_DIR:="${BASEDIR}/extra"}

# aliases
VERSION=${PRODUCT_VERSION}

if [ -z "${BOARD}" ] ; then
  echo "error: board must be specified!"
  exit 1
fi
if [ ! -f "${BOARD_CONF}" ] ; then
  echo "error: board ${BOARD} is not supported!"
  exit 1
fi

if [ ! -d "${EXTRADIR}" ] ; then
  echo "error: directory '${EXTRADIR}' not found!"
  exit 1
fi

# common includes
. ${LIBDIR}/common.sh
. ${LIBDIR}/functions.sh

# board configuration
. ${BOARD_CONF}

# configure cross compile
. ${LIBDIR}/toolchains.sh
set_cross_compile

# configure meson build
. ${LIBDIR}/meson-build.sh

[ "${SUPPORT_ETHERNET}" = yes ] || ENABLE_ETHERNET="no"
# Do not install WLAN if there's no hardware support
[ "${SUPPORT_WLAN}" = yes ] || ENABLE_WLAN="no"

# Introduce settings
echo -n -e "\n#\n# Custom Settings\n#\n"
set -x

ROOTFS=${ROOTFS}

BOOTLOADER="${BOOTLOADER}"

# Build directories
RELEASEDIR="${BASEDIR}/images/busybox"
BUILDDIR="${RELEASEDIR}/build"

# Chroot directories
R="${BUILDDIR}/chroot"
ETC_DIR="${R}/etc"
USR_DIR="${R}/usr"
HOME_DIR="${R}/home"

# General settings
HOST_NAME=${HOST_NAME:="${BOARD}-busybox"}
DEFLOCAL=${DEFLOCAL:="en_US.UTF-8"}
TIMEZONE=${TIMEZONE:="Europe/Moscow"}

# Keyboard settings
XKB_MODEL=${XKB_MODEL:=""}
XKB_LAYOUT=${XKB_LAYOUT:=""}
XKB_VARIANT=${XKB_VARIANT:=""}
XKB_OPTIONS=${XKB_OPTIONS:=""}

# Network settings (static)
NET_ADDRESS=${NET_ADDRESS:=""}
NET_GATEWAY=${NET_GATEWAY:=""}
NET_DNS_1=${NET_DNS_1:=""}
NET_DNS_2=${NET_DNS_2:=""}
NET_DNS_DOMAINS=${NET_DNS_DOMAINS:=""}
NET_NTP_1=${NET_NTP_1:=""}
NET_NTP_2=${NET_NTP_2:=""}

# Features
ENABLE_CONSOLE=${ENABLE_CONSOLE:="yes"}
ENABLE_IPV6=${ENABLE_IPV6:="yes"}
ENABLE_SSHD=${ENABLE_SSHD:="no"}
ENABLE_SOUND=${ENABLE_SOUND:="no"}
ENABLE_X11=${ENABLE_X11:="no"}

ENABLE_USER=${ENABLE_USER:="no"}
	USER_NAME=${USER_NAME:="pi"}
	USER_ADMIN=${USER_ADMIN:="no"}
	USER_GROUPS="default users tty ${USER_GROUPS}"
	PASSWORD=${PASSWORD:="armlinux"}

ENABLE_ROOT=${ENABLE_ROOT:="yes"}
ENABLE_ROOT_SSH=${ENABLE_ROOT_SSH:="yes"}
ENABLE_ETHERNET=${ENABLE_ETHERNET:="no"}
ENABLE_WLAN=${ENABLE_WLAN:="no"}
ENABLE_BTH=${ENABLE_BTH:="no"}
ENABLE_SDR=${ENABLE_SDR:="no"}
ENABLE_GDB=${ENABLE_GDB:="no"}
ENABLE_QT=${ENABLE_QT:="no"}
ENABLE_NTP=${ENABLE_NTP:="no"}
ENABLE_DEVEL=${ENABLE_DEVEL:="yes"}

# Advanced settings
ENABLE_REDUCE=${ENABLE_REDUCE:="no"}
ENABLE_HARDNET=${ENABLE_HARDNET:="no"}
ENABLE_IPTABLES=${ENABLE_IPTABLES:="no"}


# DRM debug level
DRM_DEBUG=${DRM_DEBUG:=""}

# Kernel installation settings
KERNEL_INSTALL_HEADERS=${KERNEL_INSTALL_HEADERS:="yes"}
KERNEL_INSTALL_SOURCE=${KERNEL_INSTALL_SOURCE:="no"}

# Reduce disk usage settings
REDUCE_APT=${REDUCE_APT:="yes"}
REDUCE_DOC=${REDUCE_DOC:="yes"}
REDUCE_MAN=${REDUCE_MAN:="yes"}
REDUCE_BASH=${REDUCE_BASH:="no"}
REDUCE_HWDB=${REDUCE_HWDB:="yes"}
REDUCE_LOCALE=${REDUCE_LOCALE:="yes"}

SWAP_SIZE_MB=${SWAP_SIZE_MB:="200"}

# Chroot scripts directory
CHROOT_SCRIPTS=${CHROOT_SCRIPTS:=""}

set +x

# configs are stored in ${CONFIGDIR}/busybox/${CONFIG}/${BUSYBOX_VERSION}/ directiory
BB_BUILD_CONFIG=${BB_BUILD_CONFIG:="busybox.config"}

BB_LIBC=${BB_LIBC:="gnu"}

if [ $BB_LIBC = gnu ] ; then
  BB_PLATFORM=${LINUX_PLATFORM}
  BB_CROSS_COMPILE=${CROSS_COMPILE}

elif [ $BB_LIBC = musl ] ; then
  BB_PLATFORM=${MUSL_TOOLCHAIN_PLATFORM}
  BB_CROSS_COMPILE=${MUSL_CROSS_COMPILE}

  # bluez requires GLib which, in turn, requires GNU libc to compile
  ENABLE_BTH=no

else
  echo "error: libc '{EXTRADIR}' not supported!"
  exit 1
fi
BB_GCC=${BB_CROSS_COMPILE}gcc
BB_CXX=${BB_CROSS_COMPILE}g++
BB_NM=${BB_CROSS_COMPILE}nm
BB_OBJDUMP=${BB_CROSS_COMPILE}objdump
BB_OBJCOPY=${BB_CROSS_COMPILE}objcopy
BB_STRIP=${BB_CROSS_COMPILE}strip
BB_RANLIB=${BB_CROSS_COMPILE}ranlib
BB_AR=${BB_CROSS_COMPILE}ar
BB_SIZE=${BB_CROSS_COMPILE}size
BB_LD=${BB_CROSS_COMPILE}ld
BB_BUILD_OUT=build-${BB_PLATFORM}


display_alert "Selected platform:" "${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])" "info"

display_alert "Product version:" "${PRODUCT_FULL_VER}" "info"

# Make absolute path to output rootfs
BOOT_DIR="${R}${TARGET_BOOT_DIR}"

# find out kernel image name
if [ "${KERNEL_IMAGE_COMPRESSED}" = yes ] ; then
  if [ "${KERNEL_ARCH}" = arm64 ] ; then
    KERNEL_IMAGE_FILE="Image.gz"
  else
    KERNEL_IMAGE_FILE="zImage"
  fi
else
  KERNEL_IMAGE_FILE="Image"
fi

# Fail early: Is kernel ready?
if [ ! -e "${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_FILE}" ] ; then
  echo "error: cannot proceed: Linux kernel must be precompiled"
  exit 1
fi

# Fail early: Is u-boot ready?
if [ "${BOOTLOADER}" = uboot ] && [ ! -e "${UBOOT_SOURCE_DIR}/u-boot.bin" ] ; then
  echo "error: cannot proceed: U-Boot must be precompiled"
  exit 1
fi

BOOTSTRAP_D="${LIBDIR}/bootstrap.d/busybox"
FILES_D="${LIBDIR}/files/busybox"
CUSTOM_D="${LIBDIR}/custom.d/busybox"

# Check if ./bootstrap.d directory exists
if [ ! -d "${BOOTSTRAP_D}" ] ; then
  echo "error: 'bootstrap.d' required directory not found!"
  exit 1
fi

# Check if ./files directory exists
if [ ! -d "${FILES_D}" ] ; then
  echo "error: 'files' required directory not found!"
  exit 1
fi

# Check if specified CHROOT_SCRIPTS directory exists
if [ -n "${CHROOT_SCRIPTS}" ] && [ ! -d "${CHROOT_SCRIPTS}" ] ; then
   echo "error: ${CHROOT_SCRIPTS} specified directory not found (CHROOT_SCRIPTS)!"
   exit 1
fi

# Don't clobber an old build
if [ -e "$BUILDDIR" ] ; then
  echo "error: directory ${BUILDDIR} already exists, not proceeding"
  exit 1
fi

# Setup chroot directory
mkdir -p "${R}"

# Check if build directory has enough of free disk space >512MB
if [ "$(df --output=avail ${BUILDDIR} | sed "1d")" -le "524288" ] ; then
  echo "error: ${BUILDDIR} not enough space left to generate the output image!"
  exit 1
fi

cleanup()
{
  set +x
  set +e

  # Identify and kill all processes still using files
  echo "killing processes using mount point ..."
  fuser -k "${R}"
  sleep 5
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

# Call "cleanup" function on various signals and errors
trap cleanup 0 1 2 3 6

set -e

SCRIPTS_DIR=${BASEDIR}/scripts
BOOTSTRAP_DIR=$(mktemp -u ${SCRIPTS_DIR}/bootstrap.d.XXXXXXXXX)
CUSTOM_DIR=$(mktemp -u ${SCRIPTS_DIR}/custom.d.XXXXXXXXX)
FILES_DIR=$(mktemp -u ${SCRIPTS_DIR}/files.XXXXXXXXX)

# Prepare scripts for execution
mkdir -p ${SCRIPTS_DIR}

# Cleanup possible left-overs
rm -rf ${SCRIPTS_DIR}/*

mkdir ${FILES_DIR}
mkdir ${BOOTSTRAP_DIR}
mkdir ${CUSTOM_DIR}

# Prepare required files
copy_custom_files "${FILES_D}" "${FILES_DIR}"

# Prepare bootstrap scripts
copy_custom_files "${BOOTSTRAP_D}/generic"  "${BOOTSTRAP_DIR}"  ".sh"
copy_custom_files "${BOOTSTRAP_D}/${CONFIG}"  "${BOOTSTRAP_DIR}"  ".sh"


# Execute bootstrapping scripts
num_files=$(count_files "${BOOTSTRAP_DIR}/*.sh")
if [ ${num_files} -gt 0 ] ; then
  # Execute bootstrap scripts
  for SCRIPT in ${BOOTSTRAP_DIR}/*.sh; do
    head -n 3 ${SCRIPT}
    set -e
    . ${SCRIPT}
    set +e
  done
fi

mkdir -p "${R}/chroot_scripts"


if [ -d "${CUSTOM_D}" ] ; then
  # Prepare custom scripts
  copy_custom_files "${CUSTOM_D}/generic"  "${CUSTOM_DIR}"  ".sh"
  copy_custom_files "${CUSTOM_D}/${CONFIG}"  "${CUSTOM_DIR}"  ".sh"

  num_chroot_files=$(count_files "${CUSTOM_DIR}/chroot-*.sh")
  if [ ${num_chroot_files} -gt 0 ] ; then
    for SCRIPT in ${CUSTOM_DIR}/chroot-*.sh; do
	chmod +x ${SCRIPT}
	mv ${SCRIPT} ${R}/chroot_scripts/
    done
  fi

  num_files=$(count_files "${CUSTOM_DIR}/*.sh")
  if [ ${num_files} -gt 0 ] ; then
    # Execute custom bootstrap scripts
    for SCRIPT in $CUSTOM_DIR/*.sh; do
      head -n 3 ${SCRIPT}
      set -e
      . ${SCRIPT}
      set +e
    done
  fi

# TODO: check & remove
#  rm -f ${ETC_DIR}/resolv.conf
#  echo 'nameserver 8.8.4.4' | tee ${ETC_DIR}/resolv.conf

  # Execute custom scripts in chroot
  if [ ${num_chroot_files} -gt 0 ] ; then
    chroot_exec /bin/bash -x <<'EOF'
    for SCRIPT in /chroot_scripts/* ; do
      if [ -f ${SCRIPT} -a -x ${SCRIPT} ] ; then
	set -e
        ${SCRIPT}
	set +e
      fi
    done
EOF
  fi

fi

set -e
rm -rf "${R}/chroot_scripts"


# Unmount mounted filesystems
umount -l ${R}/proc
umount -l ${R}/sys
umount -l ${R}/dev/pts

# Clean up directories
rm -rf "${R}/run/*"
rm -rf "${R}/tmp/*"

# Clean up files
rm -f "${ETC_DIR}/ssh/ssh_host_*"
rm -f "${ETC_DIR}/dropbear/dropbear_*"
rm -f "${ETC_DIR}/*-"
rm -f "${ETC_DIR}/*~"
rm -f "${ETC_DIR}/resolv.conf"
rm -f "${R}/root/.bash_history"
rm -f "${R}/var/lib/urandom/random-seed"

echo ""
echo "DONE!"
echo ""
