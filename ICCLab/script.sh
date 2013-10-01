#!/bin/bash

# add foreman installer repo
echo "deb http://deb.theforeman.org/ precise stable" > /etc/apt/sources.list.d/foreman.list
wget -q http://deb.theforeman.org/foreman.asc -O- | apt-key add -
apt-get update 
apt-get upgrade -y
# apt-get dist-upgrade -y
apt-get install -y foreman-installer

cat > /usr/share/foreman-installer/foreman_installer/answers.yaml << EOF
foreman:
  authentication: false
  ssl: false
  organizations_enabled: false
  locations_enabled: false
puppet:
  version: latest
puppetmaster:
  git_repo: false
foreman_proxy:
  tftp_servername: 192.168.56.2
  dhcp: true
  dhcp_interface: eth1
  dhcp_gateway: 192.168.56.2
  dhcp_range: 192.168.56.50 192.168.56.250
  dhcp_nameservers: 192.168.56.2
  dns: true
  dns_interface: eth1
  dns_reverse: 56.168.192.in-addr.arpa
  dns_server: 127.0.0.1
  dns_forwarders: ['8.8.8.8']
EOF

#cat >> /etc/resolvconf/resolv.conf.d/head << EOF
#domain cloudcomp.ch
#nameserver 8.8.8.8
#EOF

echo include foreman_installer | puppet apply --modulepath /usr/share/foreman-installer -v

echo "Now installing foreman-compute"

apt-get -y install foreman-compute

echo "Setting the Net forwarding rules now."
/sbin/iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
/sbin/iptables --append FORWARD --in-interface eth1 -j ACCEPT
sysctl net.ipv4.ip_forward=1
sysctl -p

echo "Installing git now."
apt-get install -y git

gem install puppet-module
puppet module install puppetlabs/openstack

#wget https://raw.github.com/theforeman/puppet-foreman/master/templates/foreman-report.rb.erb
#mv foreman-report.rb.erb foreman.rb
#mv foreman.rb /usr/lib/ruby/1.8/puppet/resolvports/

#sed -i 's/(<)(%)(=)( )(@)foreman(_)url( )(%)(>)/foreman.cloudcomp.ch/g' /usr/lib/ruby/1.8/puppet/reports/foreman.rb

#git clone https://github.com/dizz/icclab-puppet-openstack.git
#cd icclab-puppet-openstack
#./get_modules.sh

cat >> /etc/puppet/puppet.conf << EOF
[grizzly]
    modulepath     = /home/vagrant/icclab-puppet-openstack/modules
EOF

#this below will replace https to http in the foreman URL
cd /etc/puppet/
grep -rl 'https:' /etc/puppet/ | xargs sed -i 's/https:/http:/g'

echo "Modifying the default environment in puppet.conf"
grep -rl '=( )production' /etc/puppet/ | xargs sed -i '=( )production/=( )grizzly/g'

#grep -rl 'zhaw.ch' /etc/ | xargs sed -i 's/zhaw.ch/cloudcomp.ch/g'
#cat > /etc/resolvconf/resolv.conf.d/original << EOF
#nameserver 127.0.0.1
#EOF

cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
search cloudcomp.ch
EOF

#enable the foreman service to run
sed -i 's/^START=no/START=yes/' /etc/default/foreman

#start foreman
service foreman start

#clean up apt
apt-get autoremove

echo "End of script."
