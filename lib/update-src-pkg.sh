#!/bin/bash

########################################################################
# update_src_pkg.sh
#
# Description:  The function for updating source packages.
#
# Author:       Sergey Suloev <ssuloev@orpaltech.ru>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Copyright (C) 2013-2025 ORPAL Technology, Inc.
#
########################################################################


update_src_pkg()
{
    local pkg_name=$1
    local pkg_ver=$2
    local pkg_src_dir=$3
    local pkg_repo_url=$4
    local pkg_branch=$5
    local pkg_tag=$6


    if [ -n "${GIT_MIRROR_ROOT}" ]; then
	local mirror_repo_url="${GIT_MIRROR_ROOT}/${pkg_name}.git"
	if git_repo_exists "${mirror_repo_url}"; then
		pkg_repo_url=${mirror_repo_url}
	fi
    fi
    [[ -n "${pkg_tag}" ]] && branch_or_tag="tags/${pkg_tag}" || branch_or_tag="${pkg_branch}"

    display_alert "Prepare sources..." "${pkg_name} ${pkg_ver} | ${pkg_repo_url} | ${branch_or_tag}" "info"

    if [ "${PKG_FORCE_UPDATE}" = yes ] ; then
	echo "Force ${pkg_name} source update"
	rm -rf ${pkg_src_dir}
    fi

    if [ -d ${pkg_src_dir} ] && [ -d ${pkg_src_dir}/.git ] ; then
	# see if repo has changed
	local old_url=$($REALGIT -C ${pkg_src_dir} config --get remote.origin.url)
	if [ "${old_url}" != "${pkg_repo_url}" ]; then
		rm -rf ${pkg_src_dir}
	fi
    fi

    if [ "${PKG_ASSUME_OFFLINE}" != yes ] ; then
	local pkg_fetch_depth=
	if [ -n "${PKG_FETCH_DEPTH}" ];then
		pkg_fetch_depth="--depth=${PKG_FETCH_DEPTH}"
	fi

	if [ -d ${pkg_src_dir} ] && [ -d ${pkg_src_dir}/.git ] ; then
		# update sources
		$GIT -C ${pkg_src_dir} fetch origin ${pkg_fetch_depth} --tags --recurse-submodules

		$GIT -C ${pkg_src_dir} reset --hard
		if [ "${PKG_FORCE_CLEAN}" = yes ] ; then
			$GIT -C ${pkg_src_dir} clean -fdx
		fi

		echo "Checking out branch: ${pkg_branch}"
		$GIT -C ${pkg_src_dir} checkout -B ${pkg_branch} origin/${pkg_branch}
		$GIT -C ${pkg_src_dir} pull
	else
		[ -d ${pkg_src_dir} ] && rm -rf ${pkg_src_dir}

		# clone sources
		$GIT clone ${pkg_repo_url} -b ${pkg_branch} ${pkg_fetch_depth} --recurse-submodules --tags ${pkg_src_dir}
	fi

	if [ -n "${pkg_tag}" ] ; then
		echo "Checking out tag: tags/${pkg_tag}"
		$GIT -C ${pkg_src_dir} checkout tags/${pkg_tag}
	fi

	$GIT -C ${pkg_src_dir} submodule update --init --recursive
    fi

    display_alert "Sources ready" "${pkg_name} ${pkg_ver}" "info"
}
