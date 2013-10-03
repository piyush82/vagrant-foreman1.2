#!/bin/bash

# ensure latest version of puppet (3.X)
wget http://apt.puppetlabs.com/puppetlabs-release-raring.deb
dpkg -i puppetlabs-release-raring.deb

# add foreman installer repo
echo "deb http://deb.theforeman.org/ precise stable" > /etc/apt/sources.list.d/foreman.list
wget -q http://deb.theforeman.org/foreman.asc -O- | apt-key add -

#update and upgrade
apt-get update 
apt-get upgrade -y
# apt-get dist-upgrade -y

#install foreman
apt-get install -y foreman-installer

#setup the answers file - 
# TODO modify to support another DHCP range (eth2)
# TODO modify to setup puppet environments named as wanted
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

# run foreman installer
echo include foreman_installer | puppet apply --modulepath /usr/share/foreman-installer -v

echo "Setting the Net forwarding rules now."
# setup fowarding rules and on boot
# eth0 is NAT'ed adapter and the outbound route, eth{1,2} are the internal network
cat >> /etc/init.d/fwd-traff.sh << EOF
/sbin/iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
/sbin/iptables --append FORWARD --in-interface eth1 -j ACCEPT
/sbin/iptables --append FORWARD --in-interface eth2 -j ACCEPT
EOF
chmod a+x /etc/init.d/fwd-traff.sh
ln -s /etc/init.d/fwd-traff.sh /etc/rc2.d/S96forwardtraffic

# install the rules
/etc/init.d/fwd-traff.sh

# enable traffic fowarding
sysctl net.ipv4.ip_forward=1
sysctl -p

# install git
apt-get install -y git

# install puppet modules
gem install puppet-module
puppet module install puppetlabs/openstack

# or
# cd /etc/puppet/environments/development/modules
# git clone https://github.com/stackforge/puppet-openstack.git -b stable/grizzly openstack
# gem install librarian-puppet

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
grep -rl 'https:' /etc/puppet/node.rb | xargs sed -i 's/https:/http:/g'

cat > /etc/resolvconf/resolv.conf.d/head  << EOF
nameserver 127.0.0.1
search cloudcomp.ch
EOF

# setup resolv.conf
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
search cloudcomp.ch
EOF

#enable the foreman service to run
sed -i 's/^START=no/START=yes/' /etc/default/foreman

#start foreman
service foreman start

#clean up apt
apt-get -y autoremove

echo "End of script."
