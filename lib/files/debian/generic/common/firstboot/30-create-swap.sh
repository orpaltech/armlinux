logger -t "rc.firstboot" "Creating swap file"

dd if=/dev/zero of=/var/swap count=100 bs=1MiB
chmod 0600 /var/swap
mkswap /var/swap

