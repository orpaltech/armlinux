#
# Install DT overlays
#

DEST_OVERLAY_DIR="${BOOT_DIR}/overlays"

BUILD_BOOT_DTS_DIR="${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/dts"
if [ -z "${KERNEL_OVERLAY_DIR}" ] ; then
  BUILD_OVERLAY_DIR="${BUILD_BOOT_DTS_DIR}/overlays"
else
  BUILD_OVERLAY_DIR="${BUILD_BOOT_DTS_DIR}/${KERNEL_OVERLAY_DIR}"
fi

OVERLAY_DTBO_COUNT=$(count_files "${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.dtbo")
if [ $OVERLAY_DTBO_COUNT -gt 0 ] ; then
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

	OVERLAY_README_FILE="README.${OVERLAY_PREFIX}-overlays"

	if [ -f "${BUILD_OVERLAY_DIR}/${OVERLAY_README_FILE}" ] ; then
		echo "Installing ${BUILD_OVERLAY_DIR}/${OVERLAY_README_FILE}"
		install_readonly "${BUILD_OVERLAY_DIR}/${OVERLAY_README_FILE}" "${DEST_OVERLAY_DIR}/${OVERLAY_README_FILE}"
	fi
elif [ -d $BUILD_OVERLAY_DIR ] ; then
	echo "WARNING: Overlay directory exists in linux source tree, but no overlay has been built."
fi
