logger -t "rc.firstboot" "Creating /etc/resolv.conf symlink"

# Check if systemd resolve directory exists
if [ ! -d "/run/systemd/resolve" ] ; then
  systemctl enable systemd-resolved.service
  systemctl restart systemd-resolved.service
fi

# Create resolv.conf file if it does not exists
if [ ! -f "/run/systemd/resolve/resolv.conf" ] ; then
  touch /run/systemd/resolve/resolv.conf
fi

# Create symlink to /etc/resolv.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
