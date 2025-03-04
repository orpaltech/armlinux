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
	local patch_src_dir=$1
	local patch_tmp_dir=$2
	local patch_soc_dir="${patch_src_dir}/${SOC_FAMILY}"
	local patch_board_dir="${patch_soc_dir}/${BOARD}"
	local patch_ovlay_dir="${patch_src_dir}/overlays"

	#
	# Phase 1 - copy common patches
	#
	echo "--- 1) Copy common patches from '${patch_src_dir}/common'"
	cp ${patch_src_dir}/common/*.patch ${patch_tmp_dir}/ 2> /dev/null

	#
	# Phase 2 - copy SoC-specific patches (allow overwrite the common patches)
	#
	if [ -d ${patch_soc_dir} ] ; then
		echo "--- 2) Copy SoC-specific patches from '${patch_soc_dir}'"
		cp ${patch_soc_dir}/*.patch ${patch_tmp_dir}/ 2> /dev/null
	fi

	#
	# Phase 3 - copy board-specific patches (allow overwrite the common & SoC-specific patches)
	#
	if [ -d ${patch_board_dir} ] ; then
		echo "--- 3) Copy board-specific patches '${patch_board_dir}'"
		cp ${patch_board_dir}/*.patch ${patch_tmp_dir}/ 2> /dev/null
	fi

	#
	# Phase 4 - SoC specific - copy DT-overlay patches
	#
	if [ -n "${OVERLAY_PREFIX}" ]  &&  [ -d ${patch_ovlay_dir} ] ; then
		local patch_file=$(find ${patch_ovlay_dir} -regextype posix-extended -regex ".*[0-9]+-${OVERLAY_PREFIX}-.*\.patch")
		if [ -n "${patch_file}" ] && [ -f ${patch_file} ] ; then
			echo "--- 4) Copy DT-overlays patch '${patch_file}'"
                	cp ${patch_file} ${patch_tmp_dir}/
        	fi
	fi
}

#-----------------------------------------------------------------------

patch_bootloader()
{
if [ "${BOOTLOADER}" = uboot ] ; then

	local patch_base_dir=${BASEDIR}/patch/u-boot/${UBOOT_REPO_NAME}
	local patch_out_dir=${OUTPUTDIR}/patches

	rm -rf ${patch_out_dir}/u-boot.*

	if [ "${UBOOT_PATCH_DISABLE}" != yes ]  && [ -d $patch_base_dir ] ; then
		local patch_tmp_dir=$(mktemp -u ${patch_out_dir}/u-boot.XXXXXXXXX)

		# Prepare files for patching
		mkdir -p $patch_tmp_dir

		echo "Copy U-Boot base patches"

		# Copy normal-priority patches
		copy_patches  $patch_base_dir  $patch_tmp_dir

		# Check if high-priority patches are available and, if yes, copy too
		local dir_name="${UBOOT_PATCH_HIGH_PRIORITY_DIR}"
		if [ -z "${dir_name}" ] ; then
			dir_name="${UBOOT_RELEASE}"
		fi
		if [ -n "${dir_name}" ]  && [ -d ${patch_base_dir}/${dir_name} ] ; then
			echo "Copy U-Boot high-priority patches from '${dir_name}', allow overwrite base patches"

			copy_patches  ${patch_base_dir}/${dir_name}  $patch_tmp_dir
		fi

		display_alert "Patching U-Boot..." "" "info"

		local patch_count=$(count_files "${patch_tmp_dir}/*.patch")
		if [ $patch_count -gt 0 ] ; then
			# patching
			for patch_file in ${patch_tmp_dir}/*.patch; do
				echo "Applying patch '${patch_file}' to U-Boot..."
				patch -d $UBOOT_SOURCE_DIR --batch -p1 -N -F5 < $patch_file
# TODO: An alternative way to apply patches, needs to be investigated
#				git -C $UBOOT_SOURCE_DIR apply $patch_file
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
	local patch_base_dir=${BASEDIR}/patch/kernel/${CONFIG}/${KERNEL_REPO_NAME}
	local patch_out_dir=${OUTPUTDIR}/patches

	rm -rf ${patch_out_dir}/kernel.*

	if [ "${KERNEL_PATCH_DISABLE}" != yes ]  && [ -d $patch_base_dir ] ; then
                local patch_tmp_dir=$(mktemp -u ${patch_out_dir}/kernel.XXXXXXXXX)

		display_alert "Patching kernel..." "" "info"

		mkdir -p $patch_tmp_dir

                echo "Copy Kernel base patches"

		# Copy normal-priority patches
                copy_patches  $patch_base_dir  $patch_tmp_dir

		# Check if high-priority patches are available and, if yes, copy too
		local dir_name="${KERNEL_PATCH_HIGH_PRIORITY_DIR}"
		if [ -z "${dir_name}" ] ; then
			dir_name="${KERNEL_RELEASE}"
		fi
                if [ -n "${dir_name}" ] && [ -d ${patch_base_dir}/${dir_name} ] ; then
                        echo "Copy Kernel high-priority patches from '${dir_name}', allow overwrite base patches"

                        copy_patches ${patch_base_dir}/${dir_name}  ${patch_tmp_dir}
                fi

		local patch_count=$(count_files "${patch_tmp_dir}/*.patch")
		if [ $patch_count -gt 0 ] ; then
			# patching
			for patch_file in ${patch_tmp_dir}/*.patch; do
				echo "Applying patch '${patch_file}' to kernel..."
				patch -d ${KERNEL_SOURCE_DIR} --batch -p1 -N -F5 < ${patch_file}
				[ $? -eq 0 ] || exit $?;
				echo "Patched."
			done
		fi

		echo "Done."
	fi
}
