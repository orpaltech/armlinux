#
# Setup Networking (Main script)
#

# Install hostname file
install_readonly ${FILES_DIR}/network/hostname  ${ETC_DIR}/hostname
sed -i "s/^raspberry/${HOST_NAME}/"  ${ETC_DIR}/hostname

# Install hosts file
install_readonly ${FILES_DIR}/network/hosts  ${ETC_DIR}/hosts
sed -i "s/raspberry/${HOST_NAME}/"  ${ETC_DIR}/hosts

# Setup hostname entry with static IP
if [ -n "${NET_ADDRESS}" ] ; then
  NET_IP=$(echo "${NET_ADDRESS}" | cut -f 1 -d'/')
  sed -i "s/^127.0.0.1/${NET_IP}/"  ${ETC_DIR}/hosts
fi

# Remove IPv6 hosts
if [ "${ENABLE_IPV6}" != yes ] ; then
  sed -i -e "/::[1-9]/d" -e "/^$/d"  ${ETC_DIR}/hosts
fi

# Install hint about network configuration
install_readonly ${FILES_DIR}/network/interfaces  ${ETC_DIR}/network/interfaces

# Install configuration for interfaces
install_readonly ${FILES_DIR}/network/eth.network  ${ETC_DIR}/systemd/network/10-eth.network

if is_true "${ENABLE_WLAN}"; then

  # Install configuration for interface wlan0
  install_readonly ${FILES_DIR}/network/wireless.network  ${ETC_DIR}/systemd/network/00-wireless.network

  mkdir -p ${R}/var/run/wpa_supplicant

cat << EOF > ${ETC_DIR}/wpa_supplicant/wpa_supplicant-wlan0.conf
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
network={
	ssid="${WLAN_SSID}"
	scan_ssid=1
	key_mgmt=WPA-PSK
	psk="${WLAN_PASSWD}"
}
EOF

  echo "Enable wpa_supplicant service..."
  chroot_exec systemctl --no-reload enable wpa_supplicant@wlan0.service
else
  echo "Disable wpa_supplicant service..."
  chroot_exec systemctl disable wpa_supplicant
fi

echo "Enable network services..."
chroot_exec systemctl --no-reload enable systemd-networkd.service
chroot_exec systemctl --no-reload enable systemd-resolved.service

# Install host.conf resolver configuration
install_readonly ${FILES_DIR}/network/host.conf  ${ETC_DIR}/host.conf

# Enable network stack hardening
if [ "${ENABLE_HARDNET}" = yes ] ; then
  # Install sysctl.d configuration files
  install_readonly ${FILES_DIR}/sysctl.d/82-net-hardening.conf  ${ETC_DIR}/sysctl.d/82-net-hardening.conf

  # Setup resolver warnings about spoofed addresses
  sed -i "s/^# spoof warn/spoof warn/"  ${ETC_DIR}/host.conf
fi

# Enable time sync
if [ -n "${NET_NTP_1}" ] ; then
  chroot_exec systemctl --no-reload enable systemd-timesyncd.service
fi

chroot_exec update-ca-certificates -f
