#
# Install firmware files
#
LINUX_FIRMWARE_REPO_URL="git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
LINUX_FIRMWARE_BRANCH="main"

repo_update()
{
	local repo_url=$1
	local repo_branch=$2
	local target_dir=$3

	if [ -d ${target_dir} ] && [ -d ${target_dir}/.git ] ; then
		local old_url=$(git -C ${target_dir} config --get remote.origin.url)
		if [ "${old_url}" != "${repo_url}" ] ; then
			rm -rf $target_dir
		fi
	fi
	if [ -d ${target_dir} ] && [ -d ${target_dir}/.git ] ; then
                # update sources
                git -C ${target_dir} fetch origin --tags --depth=1 || return $?;

                git -C ${target_dir} reset --hard
                git -C ${target_dir} clean -fd

                echo "Checking out branch: ${repo_branch}"
                git -C ${target_dir} checkout -B ${repo_branch} origin/${repo_branch} || return $?;
                git -C ${target_dir} pull || return $?;
        else
                [[ -d ${target_dir} ]] && rm -rf ${target_dir}

                # clone sources
                git clone ${repo_url} -b ${repo_branch} --depth=1 ${target_dir} || return $?;
        fi
	return 0
}

repo_update_safe()
{
	local repo_url=$1
	local repo_branch=$2
	local target_dir=$3
	local retries=3
	local now=1
	status=0
	while [ $now -le $retries ]; do
		repo_update "$1" "$2" "$3"
		status=$?
		if [ $status -ne 0 ]; then
			sleep_time=$(((RANDOM % 60)+ 1))
			echo "WARNING: Git operation failed. Waiting '${sleep_time} seconds' before re-trying..."
			/usr/bin/sleep ${sleep_time}s
		else
			break # All good, no point on waiting...
		fi
		((now=now+1))
	done
	return $status
}

set +e

repo_update_safe "${LINUX_FIRMWARE_REPO_URL}" "${LINUX_FIRMWARE_BRANCH}" "${EXTRADIR}/linux-firmware"
[ $? -ne 0 ] && exit $?;

set -e

rsync -avz ${EXTRADIR}/linux-firmware/brcm ${LIB_DIR}/firmware
rsync -avz ${FILES_DIR}/firmware/ ${LIB_DIR}/firmware
