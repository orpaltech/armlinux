iptables-save > /etc/iptables/rules.v4

systemctl restart netfilter-persistent.service

ip6tables-save > /etc/iptables/rules.v6
