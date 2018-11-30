#!/bin/bash

########################################################################
# update-sources.sh
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
# Copyright (C) 2013-2018 ORPAL Technology, Inc.
#
########################################################################


update_uboot()
{
#	local BRANCH_FIXED=$(echo $UBOOT_REPO_BRANCH | sed -e 's/\//-/g')
        UBOOT_SOURCE_DIR="${UBOOT_BASE_DIR}"

        if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		local UBOOT_OLD_URL=$(git -C $UBOOT_SOURCE_DIR config --get remote.origin.url)
		if [ "${UBOOT_OLD_URL}" != "${UBOOT_REPO_URL}" ] ; then
			echo "U-Boot repository has changed, clean up working dir ?"
			pause
			rm -rf $UBOOT_SOURCE_DIR
		fi
	fi
	if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		display_alert "Updating U-Boot from" "${UBOOT_REPO_NAME} | ${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

                # update sources
		git -C $UBOOT_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		git -C $UBOOT_SOURCE_DIR reset --hard origin/$UBOOT_REPO_BRANCH
		git -C $UBOOT_SOURCE_DIR clean -fd

                echo "Checking out branch: ${UBOOT_REPO_BRANCH}"
                git -C $UBOOT_SOURCE_DIR checkout -B $UBOOT_REPO_BRANCH origin/$UBOOT_REPO_BRANCH
                git -C $UBOOT_SOURCE_DIR pull

		rm -f "${UBOOT_SOURCE_DIR}/*.bin"
        else
		display_alert "Cloning U-Boot from" "${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

		[[ -d $UBOOT_SOURCE_DIR ]] && rm -rf $UBOOT_SOURCE_DIR
		mkdir -p $UBOOT_BASE_DIR

                git clone $UBOOT_REPO_URL -b $UBOOT_REPO_BRANCH --depth=1 $UBOOT_SOURCE_DIR
		[ $? -eq 0 ] || exit $?;

		git -C $UBOOT_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;
        fi

        if [ -n "${UBOOT_REPO_TAG}" ] ; then
		display_alert "Checking out u-boot tag" "tags/${UBOOT_REPO_TAG}" "info"
		git -C $UBOOT_SOURCE_DIR checkout tags/$UBOOT_REPO_TAG
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
}

#-----------------------------------------------------------------------
# copy_patches(src_dir, patch_dir)
#-----------------------------------------------------------------------
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
	# Pahes 2 - copy SoC-spec patches, allow ovewrite the common patches
	#
	if [ -d "${PATCH_SOC_DIR}" ] ; then
		echo "--- 2) Copy SoC-specific patches from '${PATCH_SOC_DIR}'"
		cp $PATCH_SOC_DIR/*.patch $PATCH_TMP_DIR/ 2> /dev/null
	fi

	#
	# Phase 3 - copy board-spec patches, allow ovewrite the common & SoC-spec patches
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
	local PATCH_BASE_DIR=$BASEDIR/patch/u-boot
	local PATCH_OUT_DIR=$OUTPUTDIR/patches

	rm -rf $PATCH_OUT_DIR/u-boot.*

	if [ "${UBOOT_PATCH_DISABLE}" != yes ]  && [ -d "${PATCH_BASE_DIR}" ] ; then
		local PATCH_TMP_DIR=$(mktemp -u $PATCH_OUT_DIR/u-boot.XXXXXXXXX)

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
			echo "Copy U-Boot high-priority patches from '${PATCH_HIGH_DIR}', allow ovewrite base patches"

			copy_patches $PATCH_BASE_DIR/$PATCH_HIGH_DIR  $PATCH_TMP_DIR
		fi

		display_alert "Patching U-Boot..." "" "info"

		local PATCH_COUNT=$(count_files "${PATCH_TMP_DIR}/*.patch")
		if [ $PATCH_COUNT -gt 0 ] ; then
			# patching
			for PATCHFILE in $PATCH_TMP_DIR/*.patch; do
				echo "Applying patch '${PATCHFILE}' to U-Boot..."
				patch -d $UBOOT_SOURCE_DIR --batch -p1 -N < $PATCHFILE
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
}

#-----------------------------------------------------------------------

update_kernel()
{
	KERNEL_SOURCE_DIR="${KERNEL_BASE_DIR}"
	mkdir -p $KERNEL_BASE_DIR

	if [ -d "${KERNEL_SOURCE_DIR}" ] && [ -d "${KERNEL_SOURCE_DIR}/.git" ] ; then
                local KERNEL_OLD_URL=$(git -C $KERNEL_SOURCE_DIR config --get remote.origin.url)
                if [ "${KERNEL_OLD_URL}" != "${KERNEL_REPO_URL}" ] ; then
			echo "Kernel repository has changed, clean up working dir ?"
			pause
                        rm -rf $KERNEL_SOURCE_DIR
                fi
        fi

	if [ -d "${KERNEL_SOURCE_DIR}" ] && [ -d "${KERNEL_SOURCE_DIR}/.git" ] ; then
		display_alert "Updating kernel from" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_URL} | ${KERNEL_REPO_BRANCH}" "info"

		# update sources
		git -C $KERNEL_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		git -C $KERNEL_SOURCE_DIR reset --hard origin/$KERNEL_REPO_BRANCH
		git -C $KERNEL_SOURCE_DIR clean -fd

		echo "Checking out branch: ${KERNEL_REPO_BRANCH}"
                git -C $KERNEL_SOURCE_DIR checkout -B $KERNEL_REPO_BRANCH origin/$KERNEL_REPO_BRANCH
                git -C $KERNEL_SOURCE_DIR pull
	else
		display_alert "Cloning kernel from" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_URL} | ${KERNEL_REPO_BRANCH}" "info"

		[[ -d $KERNEL_SOURCE_DIR ]] && rm -rf $KERNEL_SOURCE_DIR

		git clone $KERNEL_REPO_URL -b $KERNEL_REPO_BRANCH --depth=1 $KERNEL_SOURCE_DIR
		[ $? -eq 0 ] || exit $?;

		git -C $KERNEL_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;
	fi

	if [ -n "${KERNEL_REPO_TAG}" ] ; then
		display_alert "Checking out kernel tag" "tags/${KERNEL_REPO_TAG}" "info"
		git -C $KERNEL_SOURCE_DIR checkout tags/$KERNEL_REPO_TAG
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
}

#-----------------------------------------------------------------------

patch_kernel()
{
	local PATCH_BASE_DIR=$BASEDIR/patch/kernel/$KERNEL_REPO_NAME
	local PATCH_OUT_DIR=$OUTPUTDIR/patches

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
                        echo "Copy Kernel high-priority patches from '${PATCH_HIGH_DIR}', allow ovewrite base patches"

                        copy_patches $PATCH_BASE_DIR/$PATCH_HIGH_DIR  $PATCH_TMP_DIR
                fi

		local PATCH_COUNT=$(count_files "$PATCH_TMP_DIR/*.patch")
		if [ $PATCH_COUNT -gt 0 ] ; then
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

#-----------------------------------------------------------------------

update_firmware()
{
	if [ ! -z "${FIRMWARE_URL}" ] ; then
		mkdir -p $FIRMWARE_BASE_DIR

		if [ -d "${FIRMWARE_SOURCE_DIR}" ] && [ -d "${FIRMWARE_SOURCE_DIR}/.git" ] ; then
			display_alert "Updating Firmware from" "${FIRMWARE_URL} | ${FIRMWARE_BRANCH}" "info"

			# update sources
			git -C $FIRMWARE_SOURCE_DIR fetch origin --tags --depth=1
			[ $? -eq 0 ] || exit $?;

			git -C $FIRMWARE_SOURCE_DIR reset --hard origin/$FIRMWARE_BRANCH
			git -C $FIRMWARE_SOURCE_DIR clean -fd

			echo "Checking out branch: ${FIRMWARE_BRANCH}"
			git -C $FIRMWARE_SOURCE_DIR checkout -B $FIRMWARE_BRANCH origin/$FIRMWARE_BRANCH
			git -C $FIRMWARE_SOURCE_DIR pull
	        else
			display_alert "Cloning Firmware from" "${FIRMWARE_URL} | ${FIRMWARE_BRANCH}" "info"

			[[ -d $FIRMWARE_SOURCE_DIR ]] && rm -rf $FIRMWARE_SOURCE_DIR

	                git clone $FIRMWARE_URL -b $FIRMWARE_BRANCH --depth=1 $FIRMWARE_SOURCE_DIR
			[ $? -eq 0 ] || exit $?;
        	fi

		echo "Done."
	fi
}
