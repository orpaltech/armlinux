#!/bin/bash

########################################################################
# image-gen.sh					       2017-2018
#
# Advanced Debian "jessie" and "stretch"  bootstrap script for RPi2/3
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2018 Sergey Suloev <ssuloev@orpaltech.com>
#
########################################################################

# Are we running as root?
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

# Fix issue that BOARD is cleared by config
BOARD_=$BOARD

if [ ! -f $ARMLINUX_CONF ] ; then
  echo "No config file found. Cannot continue."
  exit 1
fi
. $ARMLINUX_CONF

BOARD=${BOARD:="${BOARD_}"}

if [ -z "${BOARD}" ] ; then
  echo "error: board must be specified!"
  exit 1
fi

SRCDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
BASEDIR=${OUTPUTDIR:="${SRCDIR}"}
EXTRADIR=${BUILD_EXTRA_DIR:="${BASEDIR}/extra"}
BOARD_CONF="${SRCDIR}/boards/${BOARD}.conf"

if [ ! -d "${EXTRADIR}" ] ; then
  echo "error: '${EXTRADIR}' directory not found!"
  exit 1
fi

# Check if ./functions.sh script exists
if [ ! -r "${SRCDIR}/functions.sh" ] ; then
  echo "error: 'functions.sh' required script not found!"
  exit 1
fi

# Load utility functions
. $SRCDIR/functions.sh

# Introduce settings
set -e
echo -n -e "\n#\n# Bootstrap Settings\n#\n"
set -x

NUM_CPU_CORES=$(grep -c ^processor /proc/cpuinfo)

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
KERNEL_DIR="${R}/usr/src/linux"

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
ENABLE_NONFREE=${ENABLE_NONFREE:="no"}
ENABLE_WIRELESS=${ENABLE_WIRELESS:="no"}
ENABLE_SOUND=${ENABLE_SOUND:="yes"}
ENABLE_DBUS=${ENABLE_DBUS:="yes"}
ENABLE_GDB=${ENABLE_GDB:="no"}
ENABLE_X11=${ENABLE_X11:="no"}
ENABLE_RSYSLOG=${ENABLE_RSYSLOG:="yes"}
ENABLE_USER=${ENABLE_USER:="no"}
USER_NAME=${USER_NAME:="pi"}
ENABLE_ROOT=${ENABLE_ROOT:="yes"}
ENABLE_ROOT_SSH=${ENABLE_ROOT_SSH:="yes"}

# Advanced settings
ENABLE_MINBASE=${ENABLE_MINBASE:="no"}
ENABLE_REDUCE=${ENABLE_REDUCE:="no"}
ENABLE_HARDNET=${ENABLE_HARDNET:="no"}
ENABLE_IPTABLES=${ENABLE_IPTABLES:="no"}

# Kernel installation settings
KERNEL_HEADERS=${KERNEL_HEADERS:="yes"}

# Reduce disk usage settings
REDUCE_APT=${REDUCE_APT:="yes"}
REDUCE_DOC=${REDUCE_DOC:="yes"}
REDUCE_MAN=${REDUCE_MAN:="yes"}
REDUCE_BASH=${REDUCE_BASH:="no"}
REDUCE_HWDB=${REDUCE_HWDB:="yes"}
REDUCE_LOCALE=${REDUCE_LOCALE:="yes"}

# Chroot scripts directory
CHROOT_SCRIPTS=${CHROOT_SCRIPTS:=""}

# Packages required in the chroot build environment
APT_INCLUDES=${APT_INCLUDES:=""}

# Packages required for bootstrapping  (host PC)
REQUIRED_PACKAGES="debootstrap debian-archive-keyring qemu-user-static binfmt-support dosfstools rsync bmap-tools whois git"
MISSING_PACKAGES=""


set +x


if [ -f $BOARD_CONF ] ; then
  . $BOARD_CONF

  echo "Selected platform: ${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])"
else
  echo "error: Board ${BOARD} is not supported!"
  exit 1
fi

APT_INCLUDES="${APT_INCLUDES},avahi-daemon,rsync,apt-transport-https,apt-utils,ca-certificates,debian-archive-keyring,systemd"
APT_INCLUDES="${APT_INCLUDES},psmisc,u-boot-tools,i2c-tools,usbutils,initramfs-tools,console-setup"

# See if board requires additional packages to install
if [ ! -z "${APT_EXTRA_PACKAGES}" ] ; then
  APT_INCLUDES="${APT_INCLUDES},${APT_EXTRA_PACKAGES}"
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

# Check if all required packages are installed on the build system
for package in $REQUIRED_PACKAGES ; do
  if [ "`dpkg-query -W -f='${Status}' $package`" != "install ok installed" ] ; then
    MISSING_PACKAGES="${MISSING_PACKAGES} $package"
  fi
done

# Ask if missing packages should be installed right now
if [ -n "$MISSING_PACKAGES" ] ; then
  echo "the following packages needed by this script are not installed:"
  echo "$MISSING_PACKAGES"

  echo -n "\ndo you want to install the missing packages right now? [y/n] "
  read confirm
  [ "$confirm" != "y" ] && exit 1
fi

# Make sure all required packages are installed
apt-get -qq -y install $REQUIRED_PACKAGES

# Check if ./bootstrap.d directory exists
if [ ! -d "./bootstrap.d/" ] ; then
  echo "error: './bootstrap.d' required directory not found!"
  exit 1
fi

# Check if ./files directory exists
if [ ! -d "./files/" ] ; then
  echo "error: './files' required directory not found!"
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

set -x

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

if [ "${ENABLE_GDB}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},gdb,gdbserver"
fi

if [ "${ENABLE_WIRELESS}" = yes ] ; then
  APT_INCLUDES="${APT_INCLUDES},wpasupplicant"
fi

SCRIPTS_DIR=$BASEDIR/scripts
BOOTSTRAP_D=$SRCDIR/bootstrap.d
CUSTOM_D=$SRCDIR/custom.d
BOOTSTRAP_DIR=$(mktemp -u $SCRIPTS_DIR/bootstrap.d.XXXXXXXXX)
CUSTOM_DIR=$(mktemp -u $SCRIPTS_DIR/custom.d.XXXXXXXXX)
FILES_DIR=$(mktemp -u $SCRIPTS_DIR/files.XXXXXXXXX)

mkdir -p $SCRIPTS_DIR

# Cleanup possible left-overs
rm -rf $SCRIPTS_DIR/bootstrap.d.*
rm -rf $SCRIPTS_DIR/custom.d.*
rm -rf $SCRIPTS_DIR/files.*

# Prepare files for bootstrapping
mkdir $FILES_DIR
cp -R $SRCDIR/files/common/* $FILES_DIR/
if [ -d $SRCDIR/files/$SOC_FAMILY ] ; then
  cp -R $SRCDIR/files/$SOC_FAMILY/* $FILES_DIR/
fi
if [ -d $SRCDIR/files/$SOC_FAMILY/$BOARD ] ; then
  cp -R $SRCDIR/files/$SOC_FAMILY/$BOARD/* $FILES_DIR/
fi

# Prepare bootstrap scripts
mkdir $BOOTSTRAP_DIR
cp -R $BOOTSTRAP_D/common/* $BOOTSTRAP_DIR/
if [ -d $BOOTSTRAP_D/$SOC_FAMILY ] ; then
  cp -R $BOOTSTRAP_D/$SOC_FAMILY/* $BOOTSTRAP_DIR/
fi
if [ -d $BOOTSTRAP_D/$SOC_FAMILY/$BOARD ] ; then
  cp -R $BOOTSTRAP_D/$SOC_FAMILY/$BOARD/* $BOOTSTRAP_DIR/
fi

# Execute bootstrap scripts
for SCRIPT in $BOOTSTRAP_DIR/*.sh; do
  head -n 3 $SCRIPT
  . $SCRIPT
done

if [ -d $CUSTOM_D ] ; then
  # Prepare custom scripts
  mkdir $CUSTOM_DIR
  cp -R $CUSTOM_D/common/* $CUSTOM_DIR/
  if [ -d $CUSTOM_D/$SOC_FAMILY ] ; then
    cp -R $CUSTOM_D/$SOC_FAMILY/* $CUSTOM_DIR/
  fi
  if [ -d $CUSTOM_D/$SOC_FAMILY/$BOARD ] ; then
    cp -R $CUSTOM_D/$SOC_FAMILY/$BOARD/* $CUSTOM_DIR/
  fi

  # Execute custom bootstrap scripts
  for SCRIPT in $CUSTOM_DIR/*.sh; do
    head -n 3 $SCRIPT
    . $SCRIPT
  done
fi

# Execute custom scripts inside the chroot
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
chroot_exec apt-get -y clean
chroot_exec apt-get -y autoclean
chroot_exec apt-get -y autoremove

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
