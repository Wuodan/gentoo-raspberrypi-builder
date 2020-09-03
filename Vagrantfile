# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vagrant.plugins = ["vagrant-reload"]

  config.vm.box = "generic/gentoo"
  config.vm.box_version = "3.0.28"

  config.vm.provider "virtualbox" do |vb|
    # cpu, memory
    vb.memory = 8192
    vb.cpus = 6
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
end
