# gentoo-raspberrypi-builder
Crossdev and distcc in a vagrant virtualbox as builder for raspberry pi

## What's this about
I want Gentoo on my Raspberry Pi:
- when: now
- how: easy
- with: sugar and cream (crossdev and distcc)

This sets up a vagrant box containing everything one needs to run Gentoo on a Raspberry Pi.

## Usage
1. Clone this repo with ```git clone ...```.
1. Plug SD card into the PC
1. Identify SD card with: ```VBoxManage list usbhost```
1. ```cd``` into the project folder
1. Open the Vagrantfile to edit:
1. Change ```vendorid``` and ```productid``` to match your SD card
1. For USB 2: toggle all the ```--usb...``` options
1. From the project folder, run:
1. ```vagrant up```
1. ```vagrant ssh```

## Limits
- Raspberry Pi 4 64bit only at the moment.

## Requirements
- Vagrant
- Virtualbox
