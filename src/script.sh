#!/bin/bash

# ensure latest version of puppet (3.X)
wget http://apt.puppetlabs.com/puppetlabs-release-raring.deb
dpkg -i puppetlabs-release-raring.deb

# add foreman installer repo
echo "deb http://deb.theforeman.org/ precise 1.2" > /etc/apt/sources.list.d/foreman.list
wget -q http://deb.theforeman.org/foreman.asc -O- | apt-key add -

#update and upgrade
apt-get update 
apt-get upgrade -y
# apt-get dist-upgrade -y

#install foreman
apt-get install -y foreman-installer

# install git
apt-get install -y git
# install puppet module
gem install puppet-module

# setup the dhcp
echo "Setting up DHCP params..."
cp /tmp/files-to-go/proxydhcp.pp /usr/share/foreman-installer/foreman_proxy/manifests/proxydhcp.pp

echo "Setting up Foreman params..."
cp /tmp/files-to-go/answers.yaml /usr/share/foreman-installer/foreman_installer/answers.yaml
#wget -O /usr/share/foreman-installer/foreman/templates/external_node.rb.erb https://raw.github.com/theforeman/puppet-foreman/master/templates/external_node_v2.rb.erb
#wget -O /usr/share/foreman-installer/foreman/templates/foreman-report.rb.erb https://raw.github.com/theforeman/puppet-foreman/master/templates/foreman-report_v2.rb.erb

#install apt-cache
puppet module install markhellewell/aptcacherng --target-dir /usr/share/foreman-installer

echo "Running foreman installer..."
puppet apply --modulepath /usr/share/foreman-installer -v /tmp/files-to-go/install-fman.pp

echo "Setting the Net forwarding rules now."
cp /tmp/files-to-go/fwd-traff /etc/init.d/fwd-traff
chmod a+x /etc/init.d/fwd-traff
#set to run on boot
ln -s /etc/init.d/fwd-traff /etc/rc2.d/S96forwardtraffic

# install the rules
/etc/init.d/fwd-traff

#install common modules
puppet module install puppetlabs/ntp --target-dir /etc/puppet/environments/common/modules
git clone http://github.com/joemiller/puppet-newrelic /etc/puppet/environments/common/modules/newrelic

#install stable modules
#puppet module install puppetlabs/openstack
git clone https://github.com/stackforge/puppet-openstack -b stable/grizzly /etc/puppet/environments/production/modules/openstack
cd /etc/puppet/environments/production/modules/openstack
gem install librarian-puppet
librarian-puppet install --verbose --path ../

git clone http://github.com/dizz/icclab-os /etc/puppet/environments/production/modules/icclab

cat > /etc/resolvconf/resolv.conf.d/head  << EOF
nameserver 127.0.0.1
search cloudcomplab.dev
EOF

# setup resolv.conf
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
search cloudcomplab.dev
EOF

#enable the foreman service to run
sed -i 's/^START=no/START=yes/' /etc/default/foreman

#install host discovery
echo "Installing host discovery plugin"
apt-get install -y libsqlite3-dev squashfs-tools advancecomp
echo "gem 'foreman_discovery', :git => \"https://github.com/theforeman/foreman_discovery.git\"" >> /usr/share/foreman/bundler.d/Gemfile.local.rb
echo "gem 'sqlite3'" >> /usr/share/foreman/bundler.d/Gemfile.local.rb
cd /usr/share/foreman/
bundle update

echo "Building discovery PXE boot image"
rake discovery:build_image mode=prod #takes time
cp /usr/share/foreman/discovery_image/initrd.gz /var/lib/tftpboot/boot/disco-initrd.gz
cp /usr/share/foreman/discovery_image/vmlinuz /var/lib/tftpboot/boot/disco-vmlinuz

# fix puppet common environment
sed -i 's/\/etc\/puppet\/environments\/common/\/etc\/puppet\/environments\/common\/modules/' /etc/puppet/puppet.conf

#start foreman
service foreman start

#clean up apt
apt-get -y autoremove
