#
# Install DT overlays
#

BOOT_OVERLAY_DIR="${BOOT_DIR}/overlays"

BUILD_OVERLAY_DIR="${KERNEL_SOURCE_DIR}/arch/${KERNEL_ARCH}/boot/dts"
if [ -z "${KERNEL_OVERLAY_DIR}" ] ; then
  BUILD_OVERLAY_DIR="${BUILD_OVERLAY_DIR}/overlays"
else
  BUILD_OVERLAY_DIR="${BUILD_OVERLAY_DIR}/${KERNEL_OVERLAY_DIR}"
fi

if [ -d $BUILD_OVERLAY_DIR ] ; then
	mkdir -p ${BOOT_OVERLAY_DIR}

	for path in ${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.dtbo ; do
		test -f "$path" || continue
		install_readonly "$path" "${BOOT_OVERLAY_DIR}/$(basename ${path})"
	done

	for path in ${BUILD_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.scr ; do
		test -f "$path" || continue
		install_readonly "$path" "${BOOT_OVERLAY_DIR}/$(basename ${path})"
	done

	README_OVERLAY_FILE="README.${OVERLAY_PREFIX}-overlays"

	if [ -f ${BUILD_OVERLAY_DIR}/${README_OVERLAY_FILE} ] ; then
		install_readonly "${BUILD_OVERLAY_DIR}/${README_OVERLAY_FILE}" "${BOOT_OVERLAY_DIR}/${README_OVERLAY_FILE}"
	fi
fi
