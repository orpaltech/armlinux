#
# Install firmware files
#
WLAN_FW_ROOT_DIR="${EXTRADIR}/wlan-firmware"
WLAN_FW_REPO_URL="https://github.com/RPi-Distro/firmware-nonfree.git"
WLAN_FW_BRANCH="master"


wlan_fw_update()
{
	if [ -d $WLAN_FW_ROOT_DIR ] && [ -d $WLAN_FW_ROOT_DIR/.git ] ; then
		local OLD_URL=$(git -C $WLAN_FW_ROOT_DIR config --get remote.origin.url)
		if [ "${OLD_URL}" != "${WLAN_FW_REPO_URL}" ] ; then
			rm -rf $WLAN_FW_ROOT_DIR
		fi
	fi
	if [ -d $WLAN_FW_ROOT_DIR ] && [ -d $WLAN_FW_ROOT_DIR/.git ] ; then
                # update sources
                git -C $WLAN_FW_ROOT_DIR fetch origin --tags --depth=1

                git -C $WLAN_FW_ROOT_DIR reset --hard
                git -C $WLAN_FW_ROOT_DIR clean -fd

                echo "Checking out branch: ${WLAN_FW_BRANCH}"
                git -C $WLAN_FW_ROOT_DIR checkout -B $WLAN_FW_BRANCH origin/$WLAN_FW_BRANCH
                git -C $WLAN_FW_ROOT_DIR pull
        else
                [[ -d $WLAN_FW_ROOT_DIR ]] && rm -rf $WLAN_FW_ROOT_DIR

                # clone sources
                git clone $WLAN_FW_REPO_URL -b $WLAN_FW_BRANCH --depth=1 $WLAN_FW_ROOT_DIR
		[ $? -eq 0 ] || exit $?;
        fi
}


wlan_fw_update

rsync -avz ${WLAN_FW_ROOT_DIR}/brcm ${LIB_DIR}/firmware

rsync -avz ${FILES_DIR}/firmware/edid ${LIB_DIR}/firmware
