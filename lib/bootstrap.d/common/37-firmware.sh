#
# Install firmware files
#

LINUX_FIRMWARE_REPO_URL="git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"

repo_update()
{
	local repo_url=$1
	local repo_branch=$2
	local target_dir=$3

	if [ -d $target_dir ] && [ -d $target_dir/.git ] ; then
		local old_url=$(git -C $target_dir config --get remote.origin.url)
		if [ "${old_url}" != "${repo_url}" ] ; then
			rm -rf $target_dir
		fi
	fi
	if [ -d $target_dir ] && [ -d $target_dir/.git ] ; then
                # update sources
                git -C $target_dir fetch origin --tags --depth=1

                git -C $target_dir reset --hard
                git -C $target_dir clean -fd

                echo "Checking out branch: ${repo_branch}"
                git -C $target_dir checkout -B $repo_branch origin/$repo_branch
                git -C $target_dir pull
        else
                [[ -d $target_dir ]] && rm -rf $target_dir

                # clone sources
                git clone $repo_url -b $repo_branch --depth=1 $target_dir
		[ $? -eq 0 ] || exit $?;
        fi
}


repo_update "${LINUX_FIRMWARE_REPO_URL}" "master" "${EXTRADIR}/rpi-wlan-firmware"
rsync -avz "${EXTRADIR}/rpi-wlan-firmware/brcm" ${LIB_DIR}/firmware

rsync -avz "${FILES_DIR}/firmware/" ${LIB_DIR}/firmware
