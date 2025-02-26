ip6tables-save > /etc/iptables/rules.v6

systemctl restart netfilter-persistent.service
