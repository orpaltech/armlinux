#
# Create linux swap
#

chroot_exec dd if=/dev/zero of=/var/swap count=${SWAP_SIZE_MB} bs=1048576
chroot_exec chmod 0600 /var/swap
chroot_exec mkswap /var/swap
