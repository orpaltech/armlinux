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
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


update_bootloader()
{
    if [ "${BOOTLOADER}" = uboot ] ; then
        UBOOT_SOURCE_DIR="${UBOOT_BASE_DIR}"

	mkdir -p $UBOOT_BASE_DIR

	local uboot_repo_url="${UBOOT_REPO_URL}"

	if [ -n "${GIT_MIRROR_ROOT}" ]; then
		local mirror_repo_url="${GIT_MIRROR_ROOT}/uboot_${UBOOT_REPO_NAME}.git"
		if git_repo_exists "${mirror_repo_url}"; then
			uboot_repo_url=${mirror_repo_url}
		fi
	fi

	[[ -n "${UBOOT_REPO_TAG}" ]] && branch_or_tag="tags/${UBOOT_REPO_TAG}" || branch_or_tag="${UBOOT_REPO_BRANCH}"

	if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		local old_url=$($REALGIT -C $UBOOT_SOURCE_DIR config --get remote.origin.url)
		if [ "${old_url}" != "${uboot_repo_url}" ] ; then
			echo "U-Boot repository has changed, clean up working dir ?"
			pause
			rm -rf $UBOOT_SOURCE_DIR
		fi
	fi
	if [ -d "${UBOOT_SOURCE_DIR}" ] && [ -d "${UBOOT_SOURCE_DIR}/.git" ] ; then
		display_alert "Updating U-Boot from" "${UBOOT_REPO_NAME} | ${uboot_repo_url} | ${branch_or_tag}" "info"

		sudo chown -R ${CURRENT_USER}:${CURRENT_USER} $UBOOT_SOURCE_DIR

                # update sources
		$GIT -C $UBOOT_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		$GIT -C $UBOOT_SOURCE_DIR reset --hard
		if [[ $CLEAN =~ (^|,)"uboot"(,|$) ]] ; then
			$GIT -C $UBOOT_SOURCE_DIR clean -fdx
		else
			$GIT -C $UBOOT_SOURCE_DIR clean -fd
		fi

                echo "Checking out branch: ${UBOOT_REPO_BRANCH}"
		$GIT -C $UBOOT_SOURCE_DIR checkout -B $UBOOT_REPO_BRANCH origin/$UBOOT_REPO_BRANCH
		$GIT -C $UBOOT_SOURCE_DIR pull

		rm -f "${UBOOT_SOURCE_DIR}/*.bin"
        else
		display_alert "Cloning U-Boot from" "${UBOOT_REPO_NAME} | ${uboot_repo_url} | ${branch_or_tag}" "info"

		[[ -d $UBOOT_SOURCE_DIR ]] && rm -rf $UBOOT_SOURCE_DIR

		$GIT clone ${uboot_repo_url} -b $UBOOT_REPO_BRANCH --depth=1 $UBOOT_SOURCE_DIR
		[ $? -eq 0 ] || exit $?;

		$GIT -C $UBOOT_SOURCE_DIR fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;
        fi

        if [ -n "${UBOOT_REPO_TAG}" ] ; then
		echo "Checking out u-boot tag: tags/${UBOOT_REPO_TAG}"
		$GIT -C $UBOOT_SOURCE_DIR checkout tags/$UBOOT_REPO_TAG
		[ $? -eq 0 ] || exit $?;
	fi

	echo "Done."
    fi
}

#-----------------------------------------------------------------------

update_kernel()
{
    KERNEL_BASE_DIR="${KERNEL_ROOT_DIR}/${KERNEL_REPO_NAME}"
    mkdir -p ${KERNEL_BASE_DIR}

    if [[ "${KERNEL_USE_ALT}" =~ ^(y|yes)$ ]]; then
	display_alert "Extracting kernel from" "${KERNEL_REPO_NAME} | ${KERNEL_ALT_URL}" "info"

	KERNEL_SOURCE_DIR=${KERNEL_BASE_DIR}/alt

	mkdir -p ${KERNEL_SOURCE_DIR}
	sudo rm -rf ${KERNEL_SOURCE_DIR}/*

	local tar_name=$(basename "${KERNEL_ALT_URL}")
        local tar_path="${KERNEL_BASE_DIR}/${tar_name}"
        if [ ! -f ${tar_path} ] ; then
		wget -O ${tar_path} ${KERNEL_ALT_URL}
		[ $? -eq 0 ] || exit $?
	fi
        tar -xvf ${tar_path} --strip-components=1 -C ${KERNEL_SOURCE_DIR}
#        rm -f ${tar_path}

    else

	KERNEL_SOURCE_DIR=${KERNEL_BASE_DIR}/git

	local kernel_repo_url="${KERNEL_REPO_URL}"

	if [ -n "${GIT_MIRROR_ROOT}" ]; then
		local mirror_repo_url="${GIT_MIRROR_ROOT}/kernel_${KERNEL_REPO_NAME}.git"
		if git_repo_exists "${mirror_repo_url}"; then
			kernel_repo_url=${mirror_repo_url}
		fi
	fi

	[[ -n "${KERNEL_REPO_TAG}" ]] && branch_or_tag="tags/${KERNEL_REPO_TAG}" || branch_or_tag="${KERNEL_REPO_BRANCH}"

	if [ -d "${KERNEL_SOURCE_DIR}" ] && [ -d "${KERNEL_SOURCE_DIR}/.git" ] ; then
                local old_url=$($REALGIT -C $KERNEL_SOURCE_DIR config --get remote.origin.url)
                if [ "${old_url}" != "${kernel_repo_url}" ] ; then
			echo "Kernel repository has changed, clean up working dir ?"
			pause
                        rm -rf ${KERNEL_SOURCE_DIR}
                fi
        fi

	if [ -d "${KERNEL_SOURCE_DIR}" ] && [ -d "${KERNEL_SOURCE_DIR}/.git" ] ; then
		display_alert "Updating kernel from" "${KERNEL_REPO_NAME} | ${kernel_repo_url} | ${branch_or_tag}" "info"

		sudo chown -R ${CURRENT_USER}:${CURRENT_USER} $KERNEL_SOURCE_DIR

		# update sources
		$GIT -C ${KERNEL_SOURCE_DIR} fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;

		$GIT -C ${KERNEL_SOURCE_DIR} reset --hard
		if [[ ${CLEAN} =~ (^|,)"kernel"(,|$) ]] ; then
			$GIT -C ${KERNEL_SOURCE_DIR} clean -fdx
		else
			$GIT -C ${KERNEL_SOURCE_DIR} clean -fd
		fi

		echo "Checking out branch: ${KERNEL_REPO_BRANCH}"
		$GIT -C ${KERNEL_SOURCE_DIR} checkout -B ${KERNEL_REPO_BRANCH} origin/${KERNEL_REPO_BRANCH}
		$GIT -C ${KERNEL_SOURCE_DIR} pull
	else
		display_alert "Cloning kernel from" "${KERNEL_REPO_NAME} | ${kernel_repo_url} | ${branch_or_tag}" "info"

		[[ -d ${KERNEL_SOURCE_DIR} ]] && rm -rf ${KERNEL_SOURCE_DIR}

		$GIT clone ${kernel_repo_url} -b ${KERNEL_REPO_BRANCH} --depth=1 ${KERNEL_SOURCE_DIR}
		[ $? -eq 0 ] || exit $?;

		$GIT -C ${KERNEL_SOURCE_DIR} fetch origin --tags --depth=1
		[ $? -eq 0 ] || exit $?;
	fi

	if [ -n "${KERNEL_REPO_TAG}" ] ; then
		echo "Checking out kernel tag: tags/${KERNEL_REPO_TAG}"
		$GIT -C ${KERNEL_SOURCE_DIR} checkout tags/${KERNEL_REPO_TAG}
		[ $? -eq 0 ] || exit $?;
	fi

    fi

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

	if [ -n "${GIT_MIRROR_ROOT}" ]; then
		local mirror_repo_url="${GIT_MIRROR_ROOT}/fw_${fw_name}.git"
		if git_repo_exists "${mirror_repo_url}"; then
			fw_url=${mirror_repo_url}
                fi
	fi

	if [ ! -z "${fw_url}" ] ; then

		if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
			local old_url=$($REALGIT -C ${fw_src_dir} config --get remote.origin.url)
			if [ "${old_url}" != "${fw_url}" ] ; then
                                echo "Firmware repository has changed, clean up working dir ?"
                                pause
                                rm -rf ${fw_src_dir}
			fi
		fi

		if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
			# see if branch has changed
			cur_branch=$($GIT -C ${fw_src_dir} symbolic-ref --short -q HEAD)
			[[ "${cur_branch}" != "${fw_branch}" ]] && rm -rf ${fw_src_dir}
		fi

                if [ -d "${fw_src_dir}" ] && [ -d "${fw_src_dir}/.git" ] ; then
                        display_alert "Updating Firmware from" "${fw_url} | ${fw_branch}" "info"

                        sudo chown -R ${CURRENT_USER}:${CURRENT_USER} ${fw_src_dir}

                         # update sources
			$GIT -C ${fw_src_dir} fetch origin --depth=1
                        [ $? -eq 0 ] || exit $?;

			$GIT -C ${fw_src_dir} reset --hard

                        if [[ $CLEAN =~ (^|,)"firmware"(,|$) ]] ; then
				$GIT -C ${fw_src_dir} clean -fdx
                        else
				$GIT -C ${fw_src_dir} clean -fd
                        fi

                        echo "Checking out branch: ${fw_branch}"
			$GIT -C ${fw_src_dir} checkout -B ${fw_branch} origin/${fw_branch}
			$GIT -C ${fw_src_dir} pull

                else
                        display_alert "Cloning Firmware from" "${fw_url} | ${fw_branch}" "info"

                        [[ -d ${fw_src_dir} ]] && rm -rf ${fw_src_dir}

			$GIT clone ${fw_url} -b ${fw_branch} --depth=1 ${fw_src_dir}
                        [ $? -eq 0 ] || exit $?;
                fi

                echo "Done."
        fi
}
