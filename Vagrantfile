# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vagrant.plugins = ["vagrant-reload"]

  config.vm.box = "generic/gentoo"
  config.vm.box_version = "3.0.28"
  config.vm.synced_folder "shared/", "/home/vagrant/shared"

  config.vm.provider "virtualbox" do |vb|
    # cpu, memory
    vb.memory = 8192
    vb.cpus = 8
    # usb Smartcard Reader
    vb.customize ["modifyvm", :id, "--usb", "on"]
    vb.customize ["modifyvm", :id, "--usbohci", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
    vb.customize ["modifyvm", :id, "--usbxhci", "on"]
    vb.customize ["usbfilter", "add", "0", 
      "--target", :id, 
      "--name", "SmartcardReader",
      "--vendorid", "0x8564",
      "--productid", "0x4000"]
  end

  config.vm.provision "shell",
    inline: "sudo /home/vagrant/shared/vagrant-box/patchKernel.sh"

  config.vm.provision :reload

  config.vm.provision "shell",
    inline: "sudo /home/vagrant/shared/vagrant-box/install.sh"

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
