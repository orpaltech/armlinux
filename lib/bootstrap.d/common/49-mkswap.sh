#
# Create linux swap
#

chroot_exec dd if=/dev/zero of=/var/swap count=100 bs=1MiB
chroot_exec chmod 0600 /var/swap
chroot_exec mkswap /var/swap

