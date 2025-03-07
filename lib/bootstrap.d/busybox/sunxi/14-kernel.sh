#
# Setup Kernel (sunxi)
#

# Setup kernel boot cmdline
CMDLINE="console=tty1 ${CMDLINE}"
KERNEL_BOOT_ARGS="root=ROOTPART ${KERNEL_BOOT_ARGS}"

# Add serial console support
if [ "$ENABLE_CONSOLE" = yes ] ; then
  CMDLINE="console=ttyS0,115200 ${CMDLINE}"

  # TODO: find out what to do for busybox

  # Enable serial console systemd style
#  chroot_exec systemctl --no-reload enable serial-getty\@ttyS0.service
fi
