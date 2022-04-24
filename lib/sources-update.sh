#!/bin/bash

########################################################################
# sources-update.sh
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


update_uboot()
{
if [ "${ENABLE_UBOOT}" = yes ] ; then
        UBOOT_SOURCE_DIR="${UBOOT_BASE_DIR}"

	mkdir -p $UBOOT_BASE_DIR

        if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		local uboot_old_url=$(git -C $UBOOT_SOURCE_DIR config --get remote.origin.url)
		if [ "${uboot_old_url}" != "${UBOOT_REPO_URL}" ] ; then
			echo "U-Boot repository has changed, clean up working dir ?"
			pause
			rm -rf $UBOOT_SOURCE_DIR
		fi
	fi
	if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		display_alert "Updating U-Boot from" "${UBOOT_REPO_NAME} | ${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

		sudo chown -R ${CURRENT_USER}:${CURRENT_USER} $UBOOT_SOURCE_DIR

                # update sources
		git -C $UBOOT_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		git -C $UBOOT_SOURCE_DIR reset --hard
		if [[ $CLEAN =~ (^|,)"uboot"(,|$) ]] ; then
			git -C $UBOOT_SOURCE_DIR clean -fdx
		else
			git -C $UBOOT_SOURCE_DIR clean -fd
		fi

                echo "Checking out branch: ${UBOOT_REPO_BRANCH}"
                git -C $UBOOT_SOURCE_DIR checkout -B $UBOOT_REPO_BRANCH origin/$UBOOT_REPO_BRANCH
                git -C $UBOOT_SOURCE_DIR pull

		rm -f "${UBOOT_SOURCE_DIR}/*.bin"
        else
		display_alert "Cloning U-Boot from" "${UBOOT_REPO_URL} | ${UBOOT_REPO_BRANCH}" "info"

		[[ -d $UBOOT_SOURCE_DIR ]] && rm -rf $UBOOT_SOURCE_DIR

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

	UBOOT_SOURCE_DIR="${UBOOT_BASE_DIR}${UBOOT_REPO_SUBDIR}"

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

		sudo chown -R ${CURRENT_USER}:${CURRENT_USER} $KERNEL_SOURCE_DIR

		# update sources
		git -C ${KERNEL_SOURCE_DIR} fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		git -C ${KERNEL_SOURCE_DIR} reset --hard
		if [[ ${CLEAN} =~ (^|,)"kernel"(,|$) ]] ; then
			git -C ${KERNEL_SOURCE_DIR} clean -fdx
		else
			git -C ${KERNEL_SOURCE_DIR} clean -fd
		fi

		echo "Checking out branch: ${KERNEL_REPO_BRANCH}"
                git -C ${KERNEL_SOURCE_DIR} checkout -B ${KERNEL_REPO_BRANCH} origin/${KERNEL_REPO_BRANCH}
                git -C ${KERNEL_SOURCE_DIR} pull
	else
		display_alert "Cloning kernel from" "${KERNEL_REPO_NAME} | ${KERNEL_REPO_URL} | ${KERNEL_REPO_BRANCH}" "info"

		[[ -d ${KERNEL_SOURCE_DIR} ]] && rm -rf ${KERNEL_SOURCE_DIR}

		git clone ${KERNEL_REPO_URL} -b ${KERNEL_REPO_BRANCH} --depth=1 ${KERNEL_SOURCE_DIR}
		[ $? -eq 0 ] || exit $?;

		git -C ${KERNEL_SOURCE_DIR} fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;
	fi

	if [ -n "${KERNEL_REPO_TAG}" ] ; then
		display_alert "Checking out kernel tag" "tags/${KERNEL_REPO_TAG}" "info"
		git -C ${KERNEL_SOURCE_DIR} checkout tags/${KERNEL_REPO_TAG}
		[ $? -eq 0 ] || exit $?;
	fi

	KERNEL_SOURCE_DIR="${KERNEL_SOURCE_DIR}${KERNEL_REPO_SUBDIR}"

	echo "Done."
}

fw_update()
{
	fw_name=$1
	fw_url=$2
	fw_branch=$3
	fw_force=$4
	fw_src_dir="${FIRMWARE_BASE_DIR}/${fw_name}"

	mkdir -p ${FIRMWARE_BASE_DIR}

	if [ -d "${fw_src_dir}" ] && [ "${fw_force}" = yes ] ; then
		rm -rf ${fw_src_dir}
	fi

	if [ ! -z "${fw_url}" ] ; then

		if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
			fw_old_url=$(git -C ${fw_src_dir} config --get remote.origin.url)
			if [ "${fw_old_url}" != "${fw_url}" ] ; then
                                echo "Firmware repository has changed, clean up working dir ?"
                                pause
                                rm -rf ${fw_src_dir}
			fi
		fi

		if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
			# see if branch has changed
			cur_branch=$(git -C ${fw_src_dir} symbolic-ref --short -q HEAD)
			[[ "${cur_branch}" != "${fw_branch}" ]] && rm -rf ${fw_src_dir}
		fi

                if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
                        display_alert "Updating Firmware from" "${fw_url} | ${fw_branch}" "info"

                        sudo chown -R ${CURRENT_USER}:${CURRENT_USER} ${fw_src_dir}

                         # update sources
                        git -C ${fw_src_dir} fetch origin --depth=1
                        [ $? -eq 0 ] || exit $?;

                        git -C ${fw_src_dir} reset --hard

                        if [[ $CLEAN =~ (^|,)"firmware"(,|$) ]] ; then
                                git -C ${fw_src_dir} clean -fdx
                        else
                                git -C ${fw_src_dir} clean -fd
                        fi

                        echo "Checking out branch: ${fw_branch}"
                        git -C ${fw_src_dir} checkout -B ${fw_branch} origin/${fw_branch}
                        git -C ${fw_src_dir} pull
                else
                        display_alert "Cloning Firmware from" "${fw_url} | ${fw_branch}" "info"

                        [[ -d ${fw_src_dir} ]] && rm -rf ${fw_src_dir}

                        git clone ${fw_url} -b ${fw_branch} --depth=1 ${fw_src_dir}
                        [ $? -eq 0 ] || exit $?;
                fi

                echo "Done."
        fi
}

