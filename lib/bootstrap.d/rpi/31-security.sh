#
# Setup users and security settings (RPi 2/3 script)
#

# Enable serial console systemd style
if [ "$ENABLE_CONSOLE" = yes ] ; then
  chroot_exec systemctl --no-reload enable serial-getty\@ttyAMA0.service
fi
