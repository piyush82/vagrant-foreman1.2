# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.hostname = "foreman.cloudcomplab.dev"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu1204-latest"
  # config.vm.box_url = "http://domain.com/path/to/above.box"
  # config.ssh.private_key_path = "id_vagrant"

  # private management networks
  config.vm.network :private_network, ip: "10.10.10.2" # stable
  config.vm.network :private_network, ip: "10.10.11.2" # research

  # public data networks
  config.vm.network :private_network, ip: "192.168.100.2" # stable
  config.vm.network :private_network, ip: "192.168.101.2" # research

  #config.vm.network :forwarded_port, host: 8080, guest: 80

  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.name = "vagrant_foreman"
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  config.vm.synced_folder "src/", "/tmp/files-to-go"
  config.vm.provision     :shell, :path => "src/script.sh"

end
