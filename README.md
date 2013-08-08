vagrant-foreman1.2
==================

Vagrant Project to create Foreman 1.2 server in ubuntu 12.04 x86_64 base box file

* Get the Vagrant box file from http://goo.gl/oGlx2Z
* Make sure you also download the private key as Vagrant will need that to log you via 'vagrant ssh' command
* Change the Vagrant file with appropriate private IP address
* On your host - update your /etc/hosts file and add appropriate entry for your vagrant-foreman VM
** an example entry could be: 192.xxx.xxx.xxx foreman.cloudcomp.ch foreman
** The VM's FQDN is foreman.cloudcomp.ch, once the VM boots up completely, you can point your browser to this address

Enjoy!
