#!/bin/bash

cat > /usr/share/foreman-installer/foreman_installer/answers.yaml << EOF
foreman:
  authentication: false
  ssl: false
  organizations_enabled: true
  locations_enabled: true
puppet:
  version: latest
puppetmaster:
  git_repo: false
foreman_proxy:
  tftp_servername: 192.168.59.105
  dhcp: true
  dhcp_interface: eth1
  dhcp_gateway: 192.168.59.105
  dhcp_range: 192.168.59.110 192.168.59.250
  dhcp_nameservers: 192.168.59.105
  dns: true
  dns_interface: eth1
  dns_reverse: 59.168.192.in-addr.arpa
  dns_server: 127.0.0.1
  dns_forwarders: ['8.8.8.8']
EOF

echo include foreman_installer | puppet apply --modulepath /usr/share/foreman-installer -v

apt-get -y install foreman-compute

echo include foreman_installer | puppet apply --modulepath /usr/share/foreman-installer -v

/sbin/iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
/sbin/iptables --append FORWARD --in-interface eth1 -j ACCEPT

sysctl net.ipv4.ip_forward=1

iptables -t nat -L -v
