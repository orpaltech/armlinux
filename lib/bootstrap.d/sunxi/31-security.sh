#
# Setup users and security settings (sunxi script)
#

# Enable serial console systemd style
if [ "$ENABLE_CONSOLE" = yes ] ; then
  chroot_exec systemctl --no-reload enable serial-getty\@ttyS0.service
fi
