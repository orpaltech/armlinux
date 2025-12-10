#
# Setup Networking (Main script)
#


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#


#
# ########## network configuration  ##########
#

mkdir -p ${ETC_DIR}/network \
	${ETC_DIR}/network/if-down.d \
	${ETC_DIR}/network/if-post-down.d \
	${ETC_DIR}/network/if-pre-up.d \
	${ETC_DIR}/network/if-up.d

mkdir ${ETC_DIR}/wpa_supplicant

mkdir -p ${USR_DIR}/share/udhcpc

mkdir -p ${R}/var/run/network


# Install and setup hostname
install_readonly ${FILES_DIR}/network/hostname	${ETC_DIR}/
sed -i "s/^raspberry/${HOST_NAME}/"  ${ETC_DIR}/hostname

# Install and setup hosts
install_readonly ${FILES_DIR}/network/hosts	${ETC_DIR}/
sed -i "s/raspberry/${HOST_NAME}/"  ${ETC_DIR}/hosts

# Setup hostname entry with static IP
if [ "${NET_ADDRESS}" != "" ] ; then
  NET_IP=$(echo "${NET_ADDRESS}" | cut -f 1 -d'/')
  sed -i "s/^127.0.0.1/${NET_IP}/"  ${ETC_DIR}/hosts
fi

# Remove IPv6 hosts
if is_false "${ENABLE_IPV6}"; then
  sed -i -e "/::[1-9]/d" -e "/^$/d"  ${ETC_DIR}/hosts
fi

# Install network interfaces configuration file
install_readonly ${FILES_DIR}/network/interfaces  ${ETC_DIR}/network/

if is_true "${ENABLE_ETHERNET}"; then
  cat << EOF >> ${ETC_DIR}/network/interfaces

# Ethernet
allow-hotplug eth0
auto eth0
iface eth0 inet dhcp
    hostname myhostname
EOF
fi

if is_true "${ENABLE_WLAN}"; then

  WPA_IFACE=wlan0

  cat << EOF >> ${ETC_DIR}/network/interfaces

# Wireles
allow-hotplug wlan0
auto wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant-${WPA_IFACE}.conf
    hostname myhostname
EOF

  cat << EOF > ${ETC_DIR}/wpa_supplicant/wpa_supplicant-${WPA_IFACE}.conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1
ap_scan=1

network={
	ssid="${WLAN_SSID}"
	psk="${WLAN_PASSWD}"
	scan_ssid=1
}
EOF

  chmod 644 ${ETC_DIR}/wpa_supplicant/wpa_supplicant-${WPA_IFACE}.conf

  install_exec	   ${FILES_DIR}/network/wpa/ifupdown.sh	  ${ETC_DIR}/wpa_supplicant/
  install_readonly ${FILES_DIR}/network/wpa/functions.sh  ${ETC_DIR}/wpa_supplicant/

  ln -sf ../../wpa_supplicant/ifupdown.sh  ${ETC_DIR}/network/if-pre-up.d/ifupdown.sh
  ln -sf ../../wpa_supplicant/ifupdown.sh  ${ETC_DIR}/network/if-up.d/ifupdown.sh
  ln -sf ../../wpa_supplicant/ifupdown.sh  ${ETC_DIR}/network/if-down.d/ifupdown.sh
  ln -sf ../../wpa_supplicant/ifupdown.sh  ${ETC_DIR}/network/if-post-down.d/ifupdown.sh

fi

sed -i "s/\s*hostname[ \t]*myhostname\s*/    hostname ${HOST_NAME}/"  ${ETC_DIR}/network/interfaces

install_exec ${FILES_DIR}/udhcp/default.script	${USR_DIR}/share/udhcpc/

# Install host.conf resolver configuration
install_readonly ${FILES_DIR}/network/host.conf	${ETC_DIR}/


# Enable network stack hardening
if is_true "${ENABLE_HARDNET}"; then
  # Install sysctl.d configuration files
  install_readonly ${FILES_DIR}/sysctl/82-net-hardening.conf	${ETC_DIR}/sysctl.d/

  # Setup resolver warnings about spoofed addresses
  sed -i "s/^# spoof warn/spoof warn/"	${ETC_DIR}/host.conf
fi
