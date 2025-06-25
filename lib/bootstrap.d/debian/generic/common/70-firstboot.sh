#
# First boot actions
#

echo "Prepare rc.firstboot script"

# Prepare rc.firstboot script
cat ${FILES_DIR}/firstboot/10-begin.sh > ${ETC_DIR}/rc.firstboot

# Ensure openssh server host keys are regenerated on first boot
if [ "$ENABLE_SSHD" = yes ] ; then
  cat ${FILES_DIR}/firstboot/21-generate-ssh-keys.sh >> ${ETC_DIR}/rc.firstboot
fi

# Ensure that dbus machine-id exists
cat ${FILES_DIR}/firstboot/24-generate-machineid.sh >> ${ETC_DIR}/rc.firstboot

# Create /etc/resolv.conf symlink
cat ${FILES_DIR}/firstboot/25-create-resolv-symlink.sh >> ${ETC_DIR}/rc.firstboot

if [ "${ENABLE_IPTABLES}" = yes ] ; then
  # Save iptables configuration
  cat ${FILES_DIR}/firstboot/26-iptables.sh >> ${ETC_DIR}/rc.firstboot
  if [ "${ENABLE_IPV6}" = yes ] ; then
    cat ${FILES_DIR}/firstboot/27-ip6tables.sh >> ${ETC_DIR}/rc.firstboot
  fi
fi

# Resize rootfs partition
#sed -i "s#^\(BLOCK_DEV=\).*#\1${DEST_BLOCK_DEV}#"  ${FILES_DIR}/firstboot/40-resize-rootfs.sh
#sed -i "s#^\(PART_NUM=\).*#\1${RESIZE_PART_NUM}#"  ${FILES_DIR}/firstboot/40-resize-rootfs.sh
cat ${FILES_DIR}/firstboot/40-resize-rootfs.sh >> ${ETC_DIR}/rc.firstboot


if [ ! -z "${SHUTDOWN_NETWORK_IFACES}" ] ; then
  IFS=, read -ra net_ifaces <<< "${SHUTDOWN_NETWORK_IFACES}"
  for net_iface in "${net_ifaces[@]}"
  do
    echo "ip link set ${net_iface} down" >> ${ETC_DIR}/rc.firstboot
  done
fi

# Add custom scripts in the range 50..89
for custom_script in ${FILES_DIR}/firstboot/{5..8}{0..9}-*.sh; do
  if [ -f "${custom_script}" ] ; then
    cat ${custom_script} >> ${ETC_DIR}/rc.firstboot
  fi
done

# Finalize rc.firstboot script
cat ${FILES_DIR}/firstboot/99-finish.sh >> ${ETC_DIR}/rc.firstboot
chmod +x "${ETC_DIR}/rc.firstboot"

# Install default rc.local if it does not exist
if [ ! -f "${ETC_DIR}/rc.local" ] ; then
  install_exec ${FILES_DIR}/etc/rc.local ${ETC_DIR}/rc.local
fi

#if [ ! -f "${ETC_DIR}/systemd/system/rc-local.service" ] ; then
#  mkdir -p ${ETC_DIR}/systemd/system
#  install_exec ${FILES_DIR}/etc/systemd/system/rc-local.service ${ETC_DIR}/systemd/system/rc-local.service
#  chroot_exec systemctl --no-reload enable rc-local.service
#fi

echo "Add rc.firstboot script to rc.local"

# Add rc.firstboot script to rc.local
sed -i '/exit 0/d' ${ETC_DIR}/rc.local
echo /etc/rc.firstboot >> ${ETC_DIR}/rc.local
echo exit 0 >> ${ETC_DIR}/rc.local

echo "Done."
