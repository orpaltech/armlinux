#
# Build and Setup Kernel (sunxi script)
#
if [ "$DRM_USE_FIRMWARE_EDID" = yes ] ; then
  EXTRAARGS="drm_kms_helper.edid_firmware=${DRM_CONNECTOR}:${DRM_EDID_BINARY} video=${DRM_CONNECTOR}:${DRM_VIDEO_MODE} ${EXTRAARGS}"
fi

# Setup kernel boot cmdline
CMDLINE="root=/dev/mmcblk0p1 console=tty1 ${CMDLINE}"

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"

  # Enable serial console systemd style
  chroot_exec systemctl --no-reload enable serial-getty\@ttyS0.service
fi
