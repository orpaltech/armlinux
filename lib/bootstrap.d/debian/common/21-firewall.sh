#
# Setup Firewall
#

if [ "${ENABLE_IPTABLES}" = yes ] ; then
  chroot_exec update-alternatives --set iptables /usr/sbin/iptables-legacy

  # Create iptables configuration directory
  mkdir -p "${ETC_DIR}/iptables"

  # Reload systemd configuration and enable iptables service
  chroot_exec systemctl --no-reload enable netfilter-persistent.service
  chroot_exec systemctl daemon-reload

  if [ "${ENABLE_IPV6}" = yes ] ; then
    chroot_exec update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

    # Reload systemd configuration and enable iptables service
    chroot_exec systemctl daemon-reload
  fi
fi

#if [ "$ENABLE_SSHD" != yes ] ; then
 # Remove SSHD related iptables rules
# sed -i "/^#/! {/SSH/ s/^/# /}" "${ETC_DIR}/iptables/iptables.rules" 2> /dev/null
# sed -i "/^#/! {/SSH/ s/^/# /}" "${ETC_DIR}/iptables/ip6tables.rules" 2> /dev/null
#fi
