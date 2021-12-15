#
# Build and Setup Kernel (sunxi script)
#

# Setup kernel boot cmdline
CMDLINE="console=tty1 ${CMDLINE}"
KERNEL_BOOT_ARGS="root=ROOTPARTUUID ${KERNEL_BOOT_ARGS}"

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"

  # Enable serial console systemd style
  chroot_exec systemctl --no-reload enable serial-getty\@ttyS0.service
fi
