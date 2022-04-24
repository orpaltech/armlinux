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
PATCHDIR=$(realpath -s "${LIBDIR}/../patch")
ARMLINUX_CONF=${LIBDIR}/../${CONFIG}.conf
WLAN_CONF=${LIBDIR}/../wlan

# Fix possible clearing up variables by config
_BOARD_="${BOARD}"
_CLEAN_="${CLEAN}"

if [ ! -f ${ARMLINUX_CONF} ] ; then
  echo "No config file found. Cannot continue."
  exit 1
fi
. ${ARMLINUX_CONF}

if [ -f ${WLAN_CONF} ] ; then
. ${WLAN_CONF}
fi

VERSION=${PROD_VERSION}
FULL_VERSION=${PROD_VERSION}-${PROD_BUILD}

BOARD=${BOARD:="${_BOARD_}"}
BOARD_CONF=${LIBDIR}/boards/${BOARD}.conf
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

. $LIBDIR/toolchains.sh

set_cross_compile

[[ "${SUPPORT_WLAN}" != "yes" ]] && ENABLE_WLAN="no"

# Introduce settings
echo -n -e "\n#\n# Bootstrap Settings\n#\n"
set -x

# (!!!) Do not overload CPU, use only half of CPU cores
NUM_CPU_CORES=$((CPUINFO_NUM_CORES / 2))

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
APT_SERVER=${APT_SERVER:="deb.debian.org"}

# Feature settings
ENABLE_CONSOLE=${ENABLE_CONSOLE:="yes"}
ENABLE_IPV6=${ENABLE_IPV6:="yes"}
ENABLE_SSHD=${ENABLE_SSHD:="yes"}
DEBIAN_NONFREE=${DEBIAN_NONFREE:="no"}
ENABLE_SOUND=${ENABLE_SOUND:="no"}
ENABLE_DBUS=${ENABLE_DBUS:="yes"}
ENABLE_X11=${ENABLE_X11:="no"}
ENABLE_RSYSLOG=${ENABLE_RSYSLOG:="yes"}
ENABLE_USER=${ENABLE_USER:="no"}
USER_NAME=${USER_NAME:="pi"}
ENABLE_ROOT=${ENABLE_ROOT:="yes"}
ENABLE_ROOT_SSH=${ENABLE_ROOT_SSH:="yes"}
ENABLE_WLAN=${ENABLE_WLAN:="no"}

# Advanced settings
DEBIAN_MINBASE=${DEBIAN_MINBASE:="no"}
ENABLE_REDUCE=${ENABLE_REDUCE:="no"}
ENABLE_HARDNET=${ENABLE_HARDNET:="no"}
ENABLE_IPTABLES=${ENABLE_IPTABLES:="no"}
ENABLE_GDB=${ENABLE_GDB:="no"}
ENABLE_QT=${ENABLE_QT:="no"}

# Allows for installation of experimental/unstable Debian packages
DEBIAN_EXPERIMENTAL=${DEBIAN_EXPERIMENTAL:="no"}

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


display_alert "Selected platform:" "${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])" "info"


APT_INCLUDES="avahi-daemon,rsync,apt-transport-https,apt-utils,ca-certificates,debian-archive-keyring,systemd,systemd-timesyncd,psmisc,u-boot-tools,i2c-tools,usbutils,initramfs-tools,console-setup,sudo,software-properties-common,swupdate"

# See if additional packages are required
if [ ! -z "${APT_CONFIG_INCLUDES}" ] ; then
  APT_INCLUDES="${APT_INCLUDES},${APT_CONFIG_INCLUDES}"
fi

APT_FORCE_YES="--allow-downgrades --allow-remove-essential"

# Make absolute path to output rootfs
BOOT_DIR="${R}${BOOT_DIR}"

# individual toolchain components
DEV_GCC="${CROSS_COMPILE}gcc"
DEV_CXX="${CROSS_COMPILE}g++"
DEV_LD="${CROSS_COMPILE}ld.gold"
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

# Fail early: Is u-boot ready?
if [ "${ENABLE_UBOOT}" = yes ] && [ ! -e "${UBOOT_SOURCE_DIR}/u-boot.bin" ] ; then
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
if [ "${DEBIAN_MINBASE}" = yes ] ; then
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
  APT_INCLUDES="${APT_INCLUDES},libx11-dev,libxshmfence-dev,libxext-dev,libxrender-dev,libxfixes-dev,libxi-dev,libxcb1-dev,libx11-xcb-dev,libxkbcommon-dev,libxkbcommon-x11-dev"
fi

# Add iptables IPv4/IPv6 package
if [ "${ENABLE_IPTABLES}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},iptables,iptables-persistent"
fi

if [ "${ENABLE_SOUND}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},alsa-utils,libasound2-dev"
fi

# Add openssh server package
if [ "${ENABLE_SSHD}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},openssh-server"
fi

if [ "${ENABLE_WLAN}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},wpasupplicant"
fi


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

set -e

SCRIPTS_DIR=${BASEDIR}/scripts
BOOTSTRAP_DIR=$(mktemp -u ${SCRIPTS_DIR}/bootstrap.d.XXXXXXXXX)
CUSTOM_DIR=$(mktemp -u ${SCRIPTS_DIR}/custom.d.XXXXXXXXX)
FILES_DIR=$(mktemp -u ${SCRIPTS_DIR}/files.XXXXXXXXX)
DEBS_DIR=$(mktemp -u ${SCRIPTS_DIR}/debs.XXXXXXXXX)

mkdir -p ${SCRIPTS_DIR}

# Cleanup possible left-overs
rm -rf ${SCRIPTS_DIR}/*

mkdir ${FILES_DIR}
mkdir ${BOOTSTRAP_DIR}
mkdir ${CUSTOM_DIR}
mkdir ${DEBS_DIR}

# Prepare required files
copy_custom_files "${FILES_D}" "${FILES_DIR}"

# Prepare bootstrap scripts
copy_custom_files "${BOOTSTRAP_D}" "${BOOTSTRAP_DIR}" ".sh"


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
  copy_custom_files "${CUSTOM_D}/generic" "${CUSTOM_DIR}" ".sh"
  copy_custom_files "${CUSTOM_D}/${CONFIG}" "${CUSTOM_DIR}" ".sh"

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
