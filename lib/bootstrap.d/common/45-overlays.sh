#
# Install DT overlays
#

install_overlays()
{
	local DEST_OVERLAY_DIR="${BOOT_DIR}/overlays"

	if [ -z "${KERNEL_OVERLAY_DIR}" ] ; then
		local BUILD_OVERLAY_DIR="${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/dts/overlays"
	else
		local BUILD_OVERLAY_DIR="${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/dts/${KERNEL_OVERLAY_DIR}"
	fi

	local DTBO_COUNT=$(count_files "${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.dtbo")
	if [ $DTBO_COUNT -gt 0 ] ; then
		echo "Found ${DTBO_COUNT} overlays in ${BUILD_OVERLAY_DIR}"
		mkdir -p ${DEST_OVERLAY_DIR}

		for path in ${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.dtbo ; do
			test -f "$path" || continue
			echo "Installing $path"
			install_readonly "$path" "${DEST_OVERLAY_DIR}/$(basename ${path})"
		done

		for path in ${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.scr ; do
			test -f "$path" || continue
			echo "Installing $path"
			install_readonly "$path" "${DEST_OVERLAY_DIR}/$(basename ${path})"
		done

		local README_FILE="README.${OVERLAY_PREFIX}-overlays"

		if [ -f ${BUILD_OVERLAY_DIR}/${README_FILE} ] ; then
			echo "Installing ${BUILD_OVERLAY_DIR}/${README_FILE}"
			install_readonly "${BUILD_OVERLAY_DIR}/${README_FILE}" "${DEST_OVERLAY_DIR}/${README_FILE}"
		fi
	elif [ -d $BUILD_OVERLAY_DIR ] ; then
		echo "WARNING: Directory ${BUILD_OVERLAY_DIR} exists but 0 overlays found"

	else
		echo "No overlays found, skip"
	fi
}

install_overlays
