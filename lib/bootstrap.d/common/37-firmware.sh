#
# Install firmware files
#

wlan_fw_update()
{
	local FW_REPO_URL=$1
	local FW_BRANCH=$2
	local FW_ROOT_DIR=$3

	if [ -d $FW_ROOT_DIR ] && [ -d $FW_ROOT_DIR/.git ] ; then
		local OLD_URL=$(git -C $FW_ROOT_DIR config --get remote.origin.url)
		if [ "${OLD_URL}" != "${FW_REPO_URL}" ] ; then
			rm -rf $FW_ROOT_DIR
		fi
	fi
	if [ -d $FW_ROOT_DIR ] && [ -d $FW_ROOT_DIR/.git ] ; then
                # update sources
                git -C $FW_ROOT_DIR fetch origin --tags --depth=1

                git -C $FW_ROOT_DIR reset --hard
                git -C $FW_ROOT_DIR clean -fd

                echo "Checking out branch: ${FW_BRANCH}"
                git -C $FW_ROOT_DIR checkout -B $FW_BRANCH origin/$FW_BRANCH
                git -C $FW_ROOT_DIR pull
        else
                [[ -d $FW_ROOT_DIR ]] && rm -rf $FW_ROOT_DIR

                # clone sources
                git clone $FW_REPO_URL -b $FW_BRANCH --depth=1 $FW_ROOT_DIR
		[ $? -eq 0 ] || exit $?;
        fi
}


wlan_fw_update "https://github.com/RPi-Distro/firmware-nonfree.git" "master" "${EXTRADIR}/rpi-wlan-firmware"
rsync -avz "${EXTRADIR}/rpi-wlan-firmware/brcm" ${LIB_DIR}/firmware

rsync -avz "${FILES_DIR}/firmware/" ${LIB_DIR}/firmware
