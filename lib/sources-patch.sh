#!/bin/bash

########################################################################
# sources-patch.sh
#
# Description:	U-Boot, Firmware and Kernel preparation script
#		for ORPALTECH ARMLINUX build framework.
#
# Author:	Sergey Suloev <ssuloev@orpaltech.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2022 ORPAL Technology, Inc.
#
########################################################################


copy_patches()
{
	local PATCH_SRC_DIR=$1
	local PATCH_TMP_DIR=$2
	local PATCH_OVERLAY_DIR="${PATCH_SRC_DIR}/overlays"
	local PATCH_SOC_DIR="${PATCH_SRC_DIR}/${SOC_FAMILY}"
	local PATCH_BOARD_DIR="${PATCH_SOC_DIR}/${BOARD}"

	#
	# Phase 1 - copy common patches
	#
	echo "--- 1) Copy common patches from '${PATCH_SRC_DIR}/common'"
	cp $PATCH_SRC_DIR/common/*.patch $PATCH_TMP_DIR/ 2> /dev/null

	#
	# Pahes 2 - copy SoC-spec patches, allow overwrite the common patches
	#
	if [ -d "${PATCH_SOC_DIR}" ] ; then
		echo "--- 2) Copy SoC-specific patches from '${PATCH_SOC_DIR}'"
		cp $PATCH_SOC_DIR/*.patch $PATCH_TMP_DIR/ 2> /dev/null
	fi

	#
	# Phase 3 - copy board-spec patches, allow overwrite the common & SoC-spec patches
	#
	if [ -d "${PATCH_BOARD_DIR}" ] ; then
		echo "--- 3) Copy board-specific patches '${PATCH_BOARD_DIR}'"
		cp $PATCH_BOARD_DIR/*.patch $PATCH_TMP_DIR/ 2> /dev/null
	fi

	#
	# Phase 4 - kernel specific - copy DT-overlay patches
	#
	if [ ! -z "${OVERLAY_PREFIX}" ]  &&  [ -d "${PATCH_OVERLAY_DIR}" ] ; then
		local PATCHFILE=$(find $PATCH_OVERLAY_DIR -regextype posix-extended -regex ".*[0-9]+-${OVERLAY_PREFIX}-.*\.patch")
		if [ ! -z "${PATCHFILE}" ] && [ -f $PATCHFILE ] ; then
			echo "--- 4) Copy DT-overlays patch '${PATCHFILE}'"
                	cp $PATCHFILE $PATCH_TMP_DIR/
        	fi
	fi
}

#-----------------------------------------------------------------------

patch_uboot()
{
if [ "${ENABLE_UBOOT}" = yes ] ; then

	local PATCH_BASE_DIR=${BASEDIR}/patch/u-boot
	local PATCH_OUT_DIR=${OUTPUTDIR}/patches

	rm -rf ${PATCH_OUT_DIR}/u-boot.*

	if [ "${UBOOT_PATCH_DISABLE}" != yes ]  && [ -d "${PATCH_BASE_DIR}" ] ; then
		local PATCH_TMP_DIR=$(mktemp -u ${PATCH_OUT_DIR}/u-boot.XXXXXXXXX)

		# Prepare files for patching
		mkdir -p $PATCH_TMP_DIR

		echo "Copy U-Boot base patches"

		# Copy normal-priority patches
		copy_patches $PATCH_BASE_DIR $PATCH_TMP_DIR

		# Check if high-priority patches are available and, if yes, copy too
		local PATCH_HIGH_DIR="${UBOOT_PATCH_HIGH_PRIORITY_DIR}"
		if [ -z "${PATCH_HIGH_DIR}" ] ; then
			PATCH_HIGH_DIR="${UBOOT_REPO_TAG}"
		fi
		if [ -n "${PATCH_HIGH_DIR}" ]  && [ -d "${PATCH_BASE_DIR}/${PATCH_HIGH_DIR}" ] ; then
			echo "Copy U-Boot high-priority patches from '${PATCH_HIGH_DIR}', allow overwrite base patches"

			copy_patches $PATCH_BASE_DIR/$PATCH_HIGH_DIR  $PATCH_TMP_DIR
		fi

		display_alert "Patching U-Boot..." "" "info"

		local patch_count=$(count_files "${PATCH_TMP_DIR}/*.patch")
		if [ $patch_count -gt 0 ] ; then
			# patching
			for PATCHFILE in $PATCH_TMP_DIR/*.patch; do
				echo "Applying patch '${PATCHFILE}' to U-Boot..."
				patch -d $UBOOT_SOURCE_DIR --batch -p1 -N < $PATCHFILE
# TODO: An alternative way to apply patches, needs to be investigated
#				git -C $UBOOT_SOURCE_DIR apply $PATCHFILE
#				git -C $UBOOT_SOURCE_DIR add --patch
#				git -C $UBOOT_SOURCE_DIR commit
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
fi
}

#-----------------------------------------------------------------------

patch_kernel()
{
	local PATCH_BASE_DIR=${BASEDIR}/patch/kernel/${CONFIG}/${KERNEL_REPO_NAME}
	local PATCH_OUT_DIR=${OUTPUTDIR}/patches

	rm -rf $PATCH_OUT_DIR/kernel.*

	if [[ "${KERNEL_PATCH_DISABLE}" != "yes"  &&  -d "${PATCH_BASE_DIR}" ]] ; then
                local PATCH_TMP_DIR=$(mktemp -u $PATCH_OUT_DIR/kernel.XXXXXXXXX)

		display_alert "Patching kernel..." "" "info"

		mkdir -p $PATCH_TMP_DIR

                echo "Copy Kernel base patches"

		# Copy base/normal-priority patches
                copy_patches $PATCH_BASE_DIR $PATCH_TMP_DIR

		# Check if high-priority patches are available and, if yes, copy too
		local PATCH_HIGH_DIR="${KERNEL_PATCH_HIGH_PRIORITY_DIR}"
		if [ -z "${PATCH_HIGH_DIR}" ] ; then
			PATCH_HIGH_DIR="${KERNEL_RELEASE}"
		fi
                if [ -n "${PATCH_HIGH_DIR}" ] && [ -d "${PATCH_BASE_DIR}/${PATCH_HIGH_DIR}" ] ; then
                        echo "Copy Kernel high-priority patches from '${PATCH_HIGH_DIR}', allow overwrite base patches"

                        copy_patches $PATCH_BASE_DIR/$PATCH_HIGH_DIR  $PATCH_TMP_DIR
                fi

		local patch_count=$(count_files "$PATCH_TMP_DIR/*.patch")
		if [ $patch_count -gt 0 ] ; then
			# patching
			for PATCHFILE in $PATCH_TMP_DIR/*.patch; do
				echo "Applying patch '${PATCHFILE}' to kernel..."
				patch -d $KERNEL_SOURCE_DIR --batch -p1 -N -F5 < $PATCHFILE
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
}
