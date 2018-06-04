#
# Build and Setup Kernel (sunxi script)
#

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"
fi

if [ "$DRM_USE_FIRMWARE_EDID" = yes ] ; then
  EXTRAARGS="drm_kms_helper.edid_firmware=${DRM_CONNECTOR}:${DRM_EDID_BINARY} video=${DRM_CONNECTOR}:${DRM_VIDEO_MODE} ${EXTRAARGS}"
fi

# Setup kernel boot cmdline
CMDLINE="root=/dev/mmcblk0p1 rootfstype=ext4 ${CMDLINE}"
