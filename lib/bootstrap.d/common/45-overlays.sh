#
# Install DT overlays
#

BOOT_OVERLAY_DIR="${BOOT_DIR}/overlays"

if [ -d ${KERNEL_OVERLAY_DIR} ] ; then
	mkdir -p ${BOOT_OVERLAY_DIR}

	for path in ${KERNEL_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.dtbo ; do
		test -f "$path" || continue
		install_readonly "$path" "${BOOT_OVERLAY_DIR}/$(basename ${path})"
	done

	for path in ${KERNEL_OVERLAY_DIR}/${OVERLAY_PREFIX}-*.scr ; do
		test -f "$path" || continue
		install_readonly "$path" "${BOOT_OVERLAY_DIR}/$(basename ${path})"
	done

	README_OVERLAY_FILE="README.${OVERLAY_PREFIX}-overlays"

	if [ -f ${KERNEL_OVERLAY_DIR}/${README_OVERLAY_FILE} ] ; then
		install_readonly "${KERNEL_OVERLAY_DIR}/${README_OVERLAY_FILE}" "${BOOT_OVERLAY_DIR}/${README_OVERLAY_FILE}"
	fi
fi
