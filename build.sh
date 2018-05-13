#!/bin/bash

#--------------------------------------------------------------

BASEDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
SRCDIR=$BASEDIR/sources
LIBDIR=$BASEDIR/lib
TOOLCHAINDIR=$BASEDIR/toolchains
OUTPUTDIR=$BASEDIR/output

. $LIBDIR/common.sh

#--------------------------------------------------------------

if [ ! -f $BASEDIR/armlinux.conf ] ; then
    echo "No config file found. Cannot continue."
    exit 1
fi

display_alert "Using config file" "${BASEDIR}/armlinux.conf" "info"

. $BASEDIR/armlinux.conf

# ---------------------------------------------------------------
# Start background sudo monitor
# ---------------------------------------------------------------
display_alert "This script requires root privileges, entering sudo" "" "wrn"

sudo_init


if [ ! -d "${BUILD_EXTRA_DIR}" ] ; then
  echo "error: '${BUILD_EXTRA_DIR}' directory not found!"
  exit 1
fi

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

[[ -z "${FIRMWARE_NAME}" ]] && FIRMWARE_NAME="${SOC_FAMILY}"

FIRMWARE_BASE_DIR=$SRCDIR/firmware
FIRMWARE_SOURCE_DIR=$FIRMWARE_BASE_DIR/$FIRMWARE_NAME

UBOOT_BASE_DIR=$SRCDIR/u-boot
KERNEL_BASE_DIR=$SRCDIR/linux-$KERNEL_REPO_NAME


. $LIBDIR/update-packages.sh
. $LIBDIR/update-sources.sh
. $LIBDIR/compile.sh
. $LIBDIR/create-image.sh

# ---------------------------------------------------------------

echo "Selected platform: ${BOARD_NAME} (SoC: ${SOC_NAME} [${KERNEL_ARCH}])"

# ---------------------------------------------------------------
# Prepare build system
# ---------------------------------------------------------------

TICKS_BEGIN=$SECONDS
DATETIME_BEGIN=$(date '+%d/%m/%Y %H:%M:%S')

get_host_pkgs

get_toolchains

get_firmware

get_uboot_source

patch_uboot

get_kernel_source

patch_kernel

# ---------------------------------------------------------------
# Build U-boot & Kernel & optional firmware
# ---------------------------------------------------------------

compile_firmware

compile_uboot

compile_kernel


# ---------------------------------------------------------------
# Create a SD-card image
# ---------------------------------------------------------------

create_image

DATETIME_END=$(date '+%d/%m/%Y %H:%M:%S')
DURATION=$(( SECONDS - TICKS_BEGIN ))

display_alert "Build finished" "${DATETIME_BEGIN} - ${DATETIME_END} | $(($DURATION / 60))m $(($DURATION % 60))s elapsed" "info"
