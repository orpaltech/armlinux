#
# First boot actions
#

echo "Prepare rc.firstboot script"

# Prepare rc.firstboot script
cat ${FILES_DIR}/firstboot/10-begin.sh > "${ETC_DIR}/rc.firstboot"

# Ensure openssh server host keys are regenerated on first boot
if [ "$ENABLE_SSHD" = yes ] ; then
  cat ${FILES_DIR}/firstboot/21-generate-ssh-keys.sh >> "${ETC_DIR}/rc.firstboot"
fi

# Ensure that dbus machine-id exists
cat ${FILES_DIR}/firstboot/24-generate-machineid.sh >> "${ETC_DIR}/rc.firstboot"

# Create /etc/resolv.conf symlink
cat ${FILES_DIR}/firstboot/25-create-resolv-symlink.sh >> "${ETC_DIR}/rc.firstboot"

# Resize rootfs partition
cat ${FILES_DIR}/firstboot/40-resize-rootfs.sh >> "${ETC_DIR}/rc.firstboot"


if [ -n "${DISABLE_NETWORK_IFACES}" ] ; then
  IFS=, read -ra disable_net_ifaces <<< "${DISABLE_NETWORK_IFACES}"
  for disable_net_iface in "${disable_net_ifaces[@]}"
  do
    echo "ip link set ${disable_net_iface} down" >> "${ETC_DIR}/rc.firstboot"
  done
fi

# Finalize rc.firstboot script
cat ${FILES_DIR}/firstboot/99-finish.sh >> "${ETC_DIR}/rc.firstboot"
chmod +x "${ETC_DIR}/rc.firstboot"

# Install default rc.local if it does not exist
if [ ! -f "${ETC_DIR}/rc.local" ] ; then
  install_exec ${FILES_DIR}/etc/rc.local "${ETC_DIR}/rc.local"
fi

echo "Add rc.firstboot script to rc.local"

# Add rc.firstboot script to rc.local
sed -i '/exit 0/d' "${ETC_DIR}/rc.local"
echo /etc/rc.firstboot >> "${ETC_DIR}/rc.local"
echo exit 0 >> "${ETC_DIR}/rc.local"

echo "Done."
