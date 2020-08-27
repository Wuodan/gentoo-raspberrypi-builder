#!/bin/bash

set -eu

function thisWorked() {
printf '# ################## #\n'
printf '# Install crossdev on the PC\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_crossdev_on_the_PC\n'
printf '# ################## #\n'
emerge sys-devel/crossdev

printf '## ################## #\n'
printf '## Setup crossdev repo\n'
printf '## https://wiki.gentoo.org/wiki/Custom_repository#Crossdev\n'
printf '## ################## #\n'
printf 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name
printf 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
chown -R portage:portage /var/db/repos/localrepo-crossdev
mkdir -p /etc/portage/repos.conf
cat <<EOF > /etc/portage/repos.conf/crossdev.conf
[crossdev]
location = /var/db/repos/localrepo-crossdev
priority = 10
masters = gentoo
auto-sync = no
EOF

printf '## ################## #\n'
printf '## Using crossdev to build a cross compiler\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Using_crossdev_to_build_a_cross_compiler\n'
printf '## ################## #\n'
crossdev -t aarch64-unknown-linux-gnu

printf '# ################## #\n'
printf '# Fetch the Raspberry Pi firmware\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch_the_Raspberry_Pi_firmware\n'
printf '# ################## #\n'
emerge dev-vcs/git
mkdir ~/raspberrypi
cd ~/raspberrypi
git clone -b stable --depth=1 https://github.com/raspberrypi/firmware

# TODO: Place this section here again
# printf '# Fetch, configure and build the Raspberry Pi kernel\n'


printf '# ################## #\n'
printf '# Fetch the Gentoo bits of the install\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch_the_Gentoo_bits_of_the_install\n'
printf '# ################## #\n'
mkdir -p /mnt/gentoo
cd /mnt/gentoo

printf '## ################## #\n'
printf '## Install the arm64 stage 3\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_arm64_stage_3\n'
printf '## ################## #\n'
cd /mnt/gentoo
wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2.DIGESTS
wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2
b2sum stage3-arm64-20200609.tar.bz2 | grep -q -f - stage3-arm64-20200609.tar.bz2.DIGESTS || (printf 'verify failed\n' && exit 1)
tar xpvf stage3-*.tar.bz2 --xattrs-include='*.*' --numeric-owner
rm -rf /mnt/gentoo/tmp/*

printf '## ################## #\n'
printf '## Install a Gentoo repository snapshot\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_a_Gentoo_repository_snapshot\n'
printf '## ################## #\n'
cd /mnt/gentoo
wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2.md5sum
wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2
cd /mnt/gentoo
md5sum portage-latest.tar.bz2 | grep -q -f - portage-latest.tar.bz2.md5sum || (printf 'verify failed\n' && exit 1)
mkdir --parents /mnt/gentoo/var/db/repos/gentoo
tar xvpf portage-latest.tar.bz2 --strip-components=1 -C /mnt/gentoo/var/db/repos/gentoo
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


printf '# ################## #\n'
printf '# Populating /boot\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Populating_.2Fboot\n'
printf '# ################## #\n'
cp -rv ~/raspberrypi/firmware/boot/* /mnt/gentoo/boot/
cp ~/raspberrypi/linux/arch/arm64/boot/Image /mnt/gentoo/boot/kernel8.img

printf '# ################## #\n'
printf '# Fetch, configure and build the Raspberry Pi kernel\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch.2C_configure_and_build_the_Raspberry_Pi_kernel\n'
printf '# ################## #\n'
git clone https://github.com/raspberrypi/linux
cd ~/raspberrypi/linux
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make bcm2711_defconfig
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make menuconfig
cp /home/vagrant/script/config-5.4.y .config
ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"

printf '## ################## #\n'
printf '## Install the device tree\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_device_tree\n'
printf '## ################## #\n'
mv /mnt/gentoo/boot/bcm2711-rpi-4-b.dtb /mnt/gentoo/boot/bcm2711-rpi-4-b.dtb_32
cp ~/raspberrypi/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb /mnt/gentoo/boot/

printf '## ################## #\n'
printf '## Install the kernel modules\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_kernel_modules\n'
printf '## ################## #\n'
cd ~/raspberrypi/linux/
ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make modules_install INSTALL_MOD_PATH=/mnt/gentoo


printf '# ################## #\n'
printf '# Raspberry Pi 3 peripherals\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Raspberry_Pi_3_peripherals\n'
printf '# ################## #\n'

printf '## ################## #\n'
printf '## Serial port configuration\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Serial_port_configuration\n'
printf '## ################## #\n'
sed -iE 's@^f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100$@# \0@' /mnt/gentoo/etc/inittab
cp /home/vagrant/script/99-com.rules /mnt/gentoo/etc/udev/rules.d/99-com.rules
printf '## ################## #\n'
printf '## Install WiFi firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_WiFi_firmware\n'
printf '## ################## #\n'
cd ~/raspberrypi/
git clone https://github.com/RPi-Distro/firmware-nonfree
mkdir -p /mnt/gentoo/lib/firmware/brcm 
cp ~/raspberrypi/firmware-nonfree/brcm/brcmfmac43455-sdio.* /mnt/gentoo/lib/firmware/brcm/

printf '## ################## #\n'
printf '## Install Bluetooth firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_Bluetooth_firmware\n'
printf '## ################## #\n'
wget -P /mnt/gentoo/lib/firmware/brcm https://raw.githubusercontent.com/RPi-Distro/bluez-firmware/master/broadcom/BCM4345C0.hcd
}


printf '# ################## #\n'
printf '# Setup\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Setup\n'
printf '# ################## #\n'
cp /home/vagrant/script/config.txt /mnt/gentoo/boot/config.txt
printf 'root=/dev/mmcblk0p3 rootfstype=ext4 rootwait' > /mnt/gentoo/boot/cmdline.txt
sed -Ei 's@^CFLAGS=.*$@# \0\nCFLAGS="-march=armv8-a+crc+simd -mtune=cortex-a72 -ftree-vectorize -O2 -pipe -fomit-frame-pointer"@' /mnt/gentoo/etc/portage/make.conf

printf '## ################## #\n'
printf '## rasberrypi/tools\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi4_64_Bit_Install#rasberrypi.2Ftools\n'
printf '## ################## #\n'
cd ~/raspberrypi
git clone https://github.com/raspberrypi/tools
cd tools/armstubs
make CC8=aarch64-unknown-linux-gnu-gcc LD8=aarch64-unknown-linux-gnu-ld OBJCOPY8=aarch64-unknown-linux-gnu-objcopy OBJDUMP8=aarch64-unknown-linux-gnu-objdump armstub8-gic.bin
cp armstub8-gic.bin /mnt/gentoo/boot/

