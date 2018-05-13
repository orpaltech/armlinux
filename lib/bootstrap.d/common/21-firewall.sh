#
# Setup Firewall
#

if [ "${ENABLE_IPTABLES}" = yes ] ; then
  # Create iptables configuration directory
  mkdir -p "${ETC_DIR}/iptables"

  # Install iptables systemd service
  install_readonly ${FILES_DIR}/iptables/iptables.service "${ETC_DIR}/systemd/system/iptables.service"

  # Install flush-table script called by iptables service
  install_exec ${FILES_DIR}/iptables/flush-iptables.sh "${ETC_DIR}/iptables/flush-iptables.sh"

  # Install iptables rule file
  install_readonly ${FILES_DIR}/iptables/iptables.rules "${ETC_DIR}/iptables/iptables.rules"

  # Reload systemd configuration and enable iptables service
  chroot_exec systemctl daemon-reload
  chroot_exec systemctl enable iptables.service

  if [ "${ENABLE_IPV6}" = yes ] ; then
    # Install ip6tables systemd service
    install_readonly ${FILES_DIR}/iptables/ip6tables.service "${ETC_DIR}/systemd/system/ip6tables.service"

    # Install ip6tables file
    install_exec ${FILES_DIR}/iptables/flush-ip6tables.sh "${ETC_DIR}/iptables/flush-ip6tables.sh"

    install_readonly ${FILES_DIR}/iptables/ip6tables.rules "${ETC_DIR}/iptables/ip6tables.rules"

    # Reload systemd configuration and enable iptables service
    chroot_exec systemctl daemon-reload
    chroot_exec systemctl enable ip6tables.service
  fi
fi

if [ "$ENABLE_SSHD" = false ] ; then
 # Remove SSHD related iptables rules
 sed -i "/^#/! {/SSH/ s/^/# /}" "${ETC_DIR}/iptables/iptables.rules" 2> /dev/null
 sed -i "/^#/! {/SSH/ s/^/# /}" "${ETC_DIR}/iptables/ip6tables.rules" 2> /dev/null
fi
