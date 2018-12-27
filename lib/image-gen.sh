#!/bin/bash

########################################################################
# image-gen.sh
#
# Description:	Image generation script for ORPALTECH ARMLINUX
#		build framework.
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


# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

if [ -z "${CONFIG}" ] ; then
  echo "No config specified. Cannot continue."
  exit 1
fi

LIBDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
ARMLINUX_CONF=$LIBDIR/../${CONFIG}.conf

# Fix possible clearing up variables by config
_BOARD_="${BOARD}"
_CLEAN_="${CLEAN}"

if [ ! -f "${ARMLINUX_CONF}" ] ; then
  echo "No config file found. Cannot continue."
  exit 1
fi
. $ARMLINUX_CONF

ENABLE_WIRELESS="${ENABLE_WIRELESS_GLOBAL}"
BOARD=${BOARD:="${_BOARD_}"}
BOARD_CONF=$LIBDIR/boards/${BOARD}.conf
CLEAN=${CLEAN:="${_CLEAN_}"}
BASEDIR=${OUTPUTDIR:="${LIBDIR}"}
EXTRADIR=${BUILD_EXTRA_DIR:="${BASEDIR}/extra"}

if [ -z "${BOARD}" ] ; then
  echo "error: board must be specified!"
  exit 1
fi
if [ ! -f "${BOARD_CONF}" ] ; then
  echo "error: board ${BOARD} is not supported!"
  exit 1
fi

if [ ! -d "${EXTRADIR}" ] ; then
  echo "error: '${EXTRADIR}' directory not found!"
  exit 1
fi

# Check if scripts exist
if [ ! -r "${LIBDIR}/functions.sh" ] ; then
  echo "error: required script 'functions.sh' not found!"
  exit 1
fi
if [ ! -r "${LIBDIR}/common.sh" ] ; then
  echo "error: required script 'common.sh' not found!"
  exit 1
fi

# Load utility functions
. $LIBDIR/common.sh
. $LIBDIR/functions.sh

# Apply board configuration
. $BOARD_CONF

CPUINFO_NUM_CORES=$(grep -c ^processor /proc/cpuinfo)
[ $SUDO_USER ] && CURRENT_USER=$SUDO_USER || CURRENT_USER=$(whoami)

# Introduce settings
set -e

echo -n -e "\n#\n# Bootstrap Settings\n#\n"
set -x

NUM_CPU_CORES=$CPUINFO_NUM_CORES

# Debian release
DEBIAN_RELEASE=${DEBIAN_RELEASE:="stretch"}

# Build directories
RELEASEDIR="${BASEDIR}/images/${DEBIAN_RELEASE}"
BUILDDIR="${RELEASEDIR}/build"

# Chroot directories
R="${BUILDDIR}/chroot"
ETC_DIR="${R}/etc"
LIB_DIR="${R}/lib"
USR_DIR="${R}/usr"


# General settings
HOST_NAME=${HOST_NAME:="${BOARD}-${DEBIAN_RELEASE}"}
PASSWORD=${PASSWORD:="armlinux"}
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

# APT settings
APT_PROXY=${APT_PROXY:=""}
APT_SERVER=${APT_SERVER:="ftp.ru.debian.org"}

# Feature settings
ENABLE_CONSOLE=${ENABLE_CONSOLE:="yes"}
ENABLE_IPV6=${ENABLE_IPV6:="yes"}
ENABLE_SSHD=${ENABLE_SSHD:="yes"}
ENABLE_NONFREE=${ENABLE_NONFREE:="no"}
ENABLE_SOUND=${ENABLE_SOUND:="no"}
ENABLE_DBUS=${ENABLE_DBUS:="yes"}
ENABLE_X11=${ENABLE_X11:="no"}
ENABLE_RSYSLOG=${ENABLE_RSYSLOG:="yes"}
ENABLE_USER=${ENABLE_USER:="no"}
USER_NAME=${USER_NAME:="pi"}
ENABLE_ROOT=${ENABLE_ROOT:="yes"}
ENABLE_ROOT_SSH=${ENABLE_ROOT_SSH:="yes"}
ENABLE_WIRELESS=${ENABLE_WIRELESS:="no"}

# Advanced settings
ENABLE_MINBASE=${ENABLE_MINBASE:="no"}
ENABLE_REDUCE=${ENABLE_REDUCE:="no"}
ENABLE_HARDNET=${ENABLE_HARDNET:="no"}
ENABLE_IPTABLES=${ENABLE_IPTABLES:="no"}

# Kernel installation settings
KERNEL_INSTALL_HEADERS=${KERNEL_INSTALL_HEADERS:="yes"}
KERNEL_INSTALL_SOURCE=${KERNEL_INSTALL_SOURCE:="yes"}

# Reduce disk usage settings
REDUCE_APT=${REDUCE_APT:="yes"}
REDUCE_DOC=${REDUCE_DOC:="yes"}
REDUCE_MAN=${REDUCE_MAN:="yes"}
REDUCE_BASH=${REDUCE_BASH:="no"}
REDUCE_HWDB=${REDUCE_HWDB:="yes"}
REDUCE_LOCALE=${REDUCE_LOCALE:="yes"}

# Chroot scripts directory
CHROOT_SCRIPTS=${CHROOT_SCRIPTS:=""}

set +x


display_alert "Selected platform:" "${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])" "info"


APT_INCLUDES="avahi-daemon,rsync,apt-transport-https,apt-utils,ca-certificates,debian-archive-keyring,systemd"
APT_INCLUDES="${APT_INCLUDES},psmisc,u-boot-tools,i2c-tools,usbutils,initramfs-tools,console-setup"

# See if additional packages are required
if [ ! -z "${APT_EXTRA_PACKAGES}" ] ; then
  APT_INCLUDES="${APT_INCLUDES},${APT_EXTRA_PACKAGES}"
fi

# See if board requires any packages
if [ ! -z "${APT_BOARD_PACKAGES}" ] ; then
  APT_INCLUDES="${APT_INCLUDES},${APT_BOARD_PACKAGES}"
fi

APT_FORCE_YES="--allow-downgrades --allow-remove-essential"

# Make absolute path to output rootfs
BOOT_DIR="${R}${BOOT_DIR}"

# individual toolchain components
DEV_GCC="${CROSS_COMPILE}gcc"
DEV_CXX="${CROSS_COMPILE}g++"
DEV_LD="${CROSS_COMPILE}ld"
DEV_AS="${CROSS_COMPILE}as"
DEV_AR="${CROSS_COMPILE}ar"
DEV_NM="${CROSS_COMPILE}nm"
DEV_STRIP="${CROSS_COMPILE}strip"
DEV_RANLIB="${CROSS_COMPILE}ranlib"
DEV_READELF="${CROSS_COMPILE}readelf"
DEV_OBJCOPY="${CROSS_COMPILE}objcopy"
DEV_OBJDUMP="${CROSS_COMPILE}objdump"


# Fail early: Is kernel ready?
if [ ! -e "${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/${KERNEL_IMAGE_SOURCE}" ] ; then
  echo "error: cannot proceed: Linux kernel must be precompiled"
  exit 1
fi
# Get kernel release version
KERNEL_VERSION=$(cat "${KERNEL_SOURCE_DIR}/include/config/kernel.release")

# Fail early: Is u-boot ready?
if [ ! -e "${UBOOT_SOURCE_DIR}/u-boot.bin" ] ; then
  echo "error: cannot proceed: U-Boot must be precompiled"
  exit 1
fi

BOOTSTRAP_D="${LIBDIR}/bootstrap.d"
FILES_D="${LIBDIR}/files"
CUSTOM_D="${LIBDIR}/custom.d"

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


# Call "cleanup" function on various signals and errors
trap cleanup 0 1 2 3 6

# Add required packages for the minbase installation
if [ "${ENABLE_MINBASE}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},vim-tiny,netbase,net-tools,ifupdown"
fi

# Add required locales packages
if [ "${DEFLOCAL}" != "en_US.UTF-8" ] ; then
  APT_INCLUDES="${APT_INCLUDES},locales,keyboard-configuration,console-setup"
fi

# Add dbus package, recommended if using systemd
if [ "${ENABLE_DBUS}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},dbus,libdbus-1-dev"
fi

if [ "${ENABLE_X11}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},libx11-dev,libxshmfence-dev"
fi

# Add iptables IPv4/IPv6 package
if [ "${ENABLE_IPTABLES}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},iptables"
fi

if [ "${ENABLE_SOUND}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},alsa-utils,libasound2-dev"
fi

# Add openssh server package
if [ "${ENABLE_SSHD}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},openssh-server"
fi

if [ "${ENABLE_WIRELESS}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},wpasupplicant"
fi

SCRIPTS_DIR=$BASEDIR/scripts
BOOTSTRAP_DIR=$(mktemp -u $SCRIPTS_DIR/bootstrap.d.XXXXXXXXX)
CUSTOM_DIR=$(mktemp -u $SCRIPTS_DIR/custom.d.XXXXXXXXX)
FILES_DIR=$(mktemp -u $SCRIPTS_DIR/files.XXXXXXXXX)
DEBS_DIR=$(mktemp -u $SCRIPTS_DIR/debs.XXXXXXXXX)

mkdir -p $SCRIPTS_DIR

# Cleanup possible left-overs
rm -rf $SCRIPTS_DIR/*

mkdir $FILES_DIR
mkdir $BOOTSTRAP_DIR
mkdir $CUSTOM_DIR
mkdir $DEBS_DIR

# Prepare files for bootstrapping
FILE_COUNT=$(count_files "${FILES_D}/common/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $FILES_D/common/* $FILES_DIR/
fi
FILE_COUNT=$(count_files "${FILES_D}/${SOC_FAMILY}/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $FILES_D/$SOC_FAMILY/* $FILES_DIR/
fi
FILE_COUNT=$(count_files "${FILES_D}/${SOC_FAMILY}/${BOARD}/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $FILES_D/$SOC_FAMILY/$BOARD/* $FILES_DIR/
  rm -rf $FILES_DIR/$BOARD
fi

# Prepare bootstrap scripts
FILE_COUNT=$(count_files "${BOOTSTRAP_D}/common/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $BOOTSTRAP_D/common/* $BOOTSTRAP_DIR/
fi
FILE_COUNT=$(count_files "${BOOTSTRAP_D}/${SOC_FAMILY}/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $BOOTSTRAP_D/$SOC_FAMILY/* $BOOTSTRAP_DIR/
fi
FILE_COUNT=$(count_files "${BOOTSTRAP_D}/${SOC_FAMILY}/${BOARD}/*")
if [ $FILE_COUNT -gt 0 ] ; then
  cp -R $BOOTSTRAP_D/$SOC_FAMILY/$BOARD/* $BOOTSTRAP_DIR/
  rm -rf $BOOTSTRAP_DIR/$BOARD
fi

FILE_COUNT=$(count_files "${BOOTSTRAP_DIR}/*.sh")
if [ $FILE_COUNT -gt 0 ] ; then
  # Execute bootstrap scripts
  for SCRIPT in $BOOTSTRAP_DIR/*.sh; do
    head -n 3 $SCRIPT
    . $SCRIPT
  done
fi

if [ -d "${CUSTOM_D}" ] ; then
  # Prepare custom scripts
  if [ -d "${CUSTOM_D}/${CONFIG}" ] ; then
    FILE_COUNT=$(count_files "${CUSTOM_D}/${CONFIG}/common/*")
    if [ $FILE_COUNT -gt 0 ] ; then
      cp -R $CUSTOM_D/$CONFIG/common/* $CUSTOM_DIR/
    fi
    FILE_COUNT=$(count_files "${CUSTOM_D}/${CONFIG}/${SOC_FAMILY}/*")
    if [ $FILE_COUNT -gt 0 ] ; then
      cp -R $CUSTOM_D/$CONFIG/$SOC_FAMILY/* $CUSTOM_DIR/
    fi
    FILE_COUNT=$(count_files "${CUSTOM_D}/${CONFIG}/${SOC_FAMILY}/${BOARD}/*")
    if [ $FILE_COUNT -gt 0 ] ; then
      cp -R $CUSTOM_D/$CONFIG/$SOC_FAMILY/$BOARD/* $CUSTOM_DIR/
      rm -rf $CUSTOM_DIR/$BOARD
    fi
  fi

  FILE_COUNT=$(count_files "${CUSTOM_DIR}/*.sh")
  if [ $FILE_COUNT -gt 0 ] ; then
    # Execute custom bootstrap scripts
    for SCRIPT in $CUSTOM_DIR/*.sh; do
      head -n 3 $SCRIPT
      . $SCRIPT
    done
  fi
fi

# Execute custom scripts in chroot
if [ -n "${CHROOT_SCRIPTS}" ] && [ -d "${CHROOT_SCRIPTS}" ] ; then
  cp -r "${CHROOT_SCRIPTS}" "${R}/chroot_scripts"
  chroot_exec /bin/bash -x <<'EOF'
for SCRIPT in /chroot_scripts/* ; do
  if [ -f $SCRIPT -a -x $SCRIPT ] ; then
    $SCRIPT
  fi
done
EOF
  rm -rf "${R}/chroot_scripts"
fi

# Remove apt-utils
chroot_exec apt-get purge -qq -y $APT_FORCE_YES apt-utils

# Generate required machine-id
MACHINE_ID=$(dbus-uuidgen)
echo -n "${MACHINE_ID}" > "${R}/var/lib/dbus/machine-id"
echo -n "${MACHINE_ID}" > "${ETC_DIR}/machine-id"

# APT Cleanup
chroot_exec apt-get -y --purge autoremove
chroot_exec apt-get -y clean

# Unmount mounted filesystems
umount -l "${R}/proc"
umount -l "${R}/sys"

# Clean up directories
rm -rf "${R}/run/*"
rm -rf "${R}/tmp/*"

# Clean up files
rm -f "${ETC_DIR}/ssh/ssh_host_*"
rm -f "${ETC_DIR}/dropbear/dropbear_*"
rm -f "${ETC_DIR}/apt/sources.list.save"
rm -f "${ETC_DIR}/resolvconf/resolv.conf.d/original"
rm -f "${ETC_DIR}/*-"
rm -f "${ETC_DIR}/apt/apt.conf.d/10proxy"
rm -f "${ETC_DIR}/resolv.conf"
rm -f "${R}/root/.bash_history"
rm -f "${R}/var/lib/urandom/random-seed"
rm -f "${R}/initrd.img"
rm -f "${R}/vmlinuz"
rm -f "${R}${QEMU_BINARY}"

echo ""
echo "DONE!"
echo ""
