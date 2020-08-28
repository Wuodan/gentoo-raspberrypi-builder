#!/bin/bash

set -eu

SHARE=/home/vagrant/shared
RPI_FILES=~/raspberrypi
RPI_TARGET=/mnt/gentoo

printf '# ################## #\n'
printf '# Install crossdev on the PC\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_crossdev_on_the_PC\n'
printf '# ################## #\n'
sudo emerge sys-devel/crossdev

printf '## ################## #\n'
printf '## Setup crossdev repo\n'
printf '## https://wiki.gentoo.org/wiki/Custom_repository#Crossdev\n'
printf '## ################## #\n'
sudo mkdir -p /var/db/repos/localrepo-crossdev/{profiles,metadata}
printf 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name
printf 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
sudo chown -R portage:portage /var/db/repos/localrepo-crossdev
sudo mkdir -p /etc/portage/repos.conf
sudo cp $SHARE/vagrant-box/crossdev.conf /etc/portage/repos.conf

printf '## ################## #\n'
printf '## Using crossdev to build a cross compiler\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Using_crossdev_to_build_a_cross_compiler\n'
printf '## ################## #\n'
sudo crossdev -t aarch64-unknown-linux-gnu

printf '# ################## #\n'
printf '# Fetch the Raspberry Pi firmware\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch_the_Raspberry_Pi_firmware\n'
printf '# ################## #\n'
sudo emerge dev-vcs/git
mkdir $RPI_FILES
cd $RPI_FILES
git clone -b stable --depth=1 https://github.com/raspberrypi/firmware

printf '# ################## #\n'
printf '# Fetch, configure and build the Raspberry Pi kernel\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch.2C_configure_and_build_the_Raspberry_Pi_kernel\n'
printf '# ################## #\n'
git clone https://github.com/raspberrypi/linux
cd $RPI_FILES/linux
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make bcm2711_defconfig
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make menuconfig
cp $SHARE/rpi/config-5.4.y .config
ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"


printf '# ################## #\n'
printf '# Fetch the Gentoo bits of the install\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch_the_Gentoo_bits_of_the_install\n'
printf '# ################## #\n'
sudo mkdir -p $RPI_TARGET
cd $RPI_TARGET

printf '## ################## #\n'
printf '## Install the arm64 stage 3\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_arm64_stage_3\n'
printf '## ################## #\n'
cd $RPI_TARGET
sudo wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2.DIGESTS
sudo wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2
b2sum stage3-arm64-20200609.tar.bz2 | grep -q -f - stage3-arm64-20200609.tar.bz2.DIGESTS || (printf 'verify failed\n' && exit 1)
sudo tar xpvf stage3-*.tar.bz2 --xattrs-include='*.*' --numeric-owner
sudo rm -rf $RPI_TARGET/tmp/*

printf '## ################## #\n'
printf '## Install a Gentoo repository snapshot\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_a_Gentoo_repository_snapshot\n'
printf '## ################## #\n'
cd $RPI_TARGET
sudo wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2.md5sum
sudo wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2
cd $RPI_TARGET
md5sum portage-latest.tar.bz2 | grep -q -f - portage-latest.tar.bz2.md5sum || (printf 'verify failed\n' && exit 1)
sudo mkdir --parents $RPI_TARGET/var/db/repos/gentoo
sudo tar xvpf portage-latest.tar.bz2 --strip-components=1 -C $RPI_TARGET/var/db/repos/gentoo
sudo mkdir --parents $RPI_TARGET/etc/portage/repos.conf
sudo cp $RPI_TARGET/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
sudo cp --dereference /etc/resolv.conf $RPI_TARGET/etc/


printf '# ################## #\n'
printf '# Populating /boot\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Populating_.2Fboot\n'
printf '# ################## #\n'
sudo cp -rv $RPI_FILES/firmware/boot/* $RPI_TARGET/boot/
sudo cp $RPI_FILES/linux/arch/arm64/boot/Image $RPI_TARGET/boot/kernel8.img

printf '## ################## #\n'
printf '## Install the device tree\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_device_tree\n'
printf '## ################## #\n'
sudo mv $RPI_TARGET/boot/bcm2711-rpi-4-b.dtb /mnt/gentoo/boot/bcm2711-rpi-4-b.dtb_32
sudo cp $RPI_FILES/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb $RPI_TARGET/boot/

printf '## ################## #\n'
printf '## Install the kernel modules\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_kernel_modules\n'
printf '## ################## #\n'
cd $RPI_FILES/linux/
sudo ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make modules_install INSTALL_MOD_PATH=$RPI_TARGET


printf '# ################## #\n'
printf '# Raspberry Pi 3 peripherals\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Raspberry_Pi_3_peripherals\n'
printf '# ################## #\n'

printf '## ################## #\n'
printf '## Serial port configuration\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Serial_port_configuration\n'
printf '## ################## #\n'
sudo sed -iE 's@^f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100$@# \0@' $RPI_TARGET/etc/inittab
sudo cp $SHARE/rpi/99-com.rules $RPI_TARGET/etc/udev/rules.d/99-com.rules
printf '## ################## #\n'
printf '## Install WiFi firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_WiFi_firmware\n'
printf '## ################## #\n'
cd $RPI_FILES/
git clone https://github.com/RPi-Distro/firmware-nonfree
sudo mkdir -p $RPI_TARGET/lib/firmware/brcm 
sudo cp $RPI_FILES/firmware-nonfree/brcm/brcmfmac43455-sdio.* $RPI_TARGET/lib/firmware/brcm/

printf '## ################## #\n'
printf '## Install Bluetooth firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_Bluetooth_firmware\n'
printf '## ################## #\n'
sudo wget -P $RPI_TARGET/lib/firmware/brcm https://raw.githubusercontent.com/RPi-Distro/bluez-firmware/master/broadcom/BCM4345C0.hcd


printf '# ################## #\n'
printf '# Setup\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Setup\n'
printf '# ################## #\n'
sudo cp $SHARE/rpi/config.txt $RPI_TARGET/boot/config.txt
sudo cp $SHARE/rpi/cmdline.txt $RPI_TARGET/boot
sudo sed -Ei 's@^CFLAGS=.*$@# \0\nCFLAGS="-march=armv8-a+crc+simd -mtune=cortex-a72 -ftree-vectorize -O2 -pipe -fomit-frame-pointer"@' $RPI_TARGET/etc/portage/make.conf

printf '## ################## #\n'
printf '## rasberrypi/tools\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi4_64_Bit_Install#rasberrypi.2Ftools\n'
printf '## ################## #\n'
cd $RPI_FILES
git clone https://github.com/raspberrypi/tools
cd tools/armstubs
make CC8=aarch64-unknown-linux-gnu-gcc LD8=aarch64-unknown-linux-gnu-ld OBJCOPY8=aarch64-unknown-linux-gnu-objcopy OBJDUMP8=aarch64-unknown-linux-gnu-objdump armstub8-gic.bin
sudo cp armstub8-gic.bin $RPI_TARGET/boot/
