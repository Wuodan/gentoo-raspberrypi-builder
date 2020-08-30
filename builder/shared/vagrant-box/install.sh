#!/bin/bash

set -eu

SHARE=/home/vagrant/shared
RPI_FILES=~/rpi-files
RPI_TARGET=/home/vagrant/rpi-install

function thisWorked(){
sudo sed -Ei "s@^MAKEOPTS=\"-j8\"\$@# \0\nMAKEOPTS=\"-j$(($(nproc)+1))\"@" /etc/portage/make.conf

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

# printf '# ################## #\n'
# printf '# Fetch, configure and build the Raspberry Pi kernel\n'
# printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch.2C_configure_and_build_the_Raspberry_Pi_kernel\n'
# printf '# ################## #\n'
# git clone https://github.com/raspberrypi/linux
# cd $RPI_FILES/linux
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make bcm2711_defconfig
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make menuconfig
# cp $SHARE/rpi/config-5.4.y .config
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"


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
sudo rm stage3-arm64-20200609.tar.bz2*
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
sudo rm portage-latest.tar.bz2*
sudo mkdir --parents $RPI_TARGET/etc/portage/repos.conf
sudo cp $RPI_TARGET/usr/share/portage/config/repos.conf $RPI_TARGET/etc/portage/repos.conf/gentoo.conf
sudo cp --dereference /etc/resolv.conf $RPI_TARGET/etc/

sudo cp /home/vagrant/shared/rpi/make.conf $RPI_TARGET/etc/portage

# ########################## QEMU CHROOT START ####################
# Setup chroot
sudo cp $SHARE/vagrant-box/package.use.qemu /etc/portage/package.use/qemu
sudo emerge qemu
quickpkg qemu
cd $RPI_TARGET
sudo ROOT=$PWD/ emerge --usepkgonly --oneshot --nodeps qemu

# Configure
sudo $SHARE/vagrant-box/chroot-rpi.sh 'eselect profile set default/linux/arm64/17.0'
sudo $SHARE/vagrant-box/chroot-rpi.sh 'ln -s /tmp /usr/aarch64-unknown-linux-gnu/tmp'
sudo $SHARE/vagrant-box/chroot-rpi.sh locale-gen
# sudo $SHARE/vagrant-box/chroot-rpi.sh gcc-config -l
# sudo $SHARE/vagrant-box/chroot-rpi.sh ldconfig -v
sudo $SHARE/vagrant-box/chroot-rpi.sh 'ROOT=/ env-update'

sudo cp $SHARE/rpi/emerge-chroot $RPI_TARGET/etc/bash/bashrc.d/emerge-chroot

sudo mv $RPI_TARGET/etc/portage/package.keywords \
    $RPI_TARGET/etc/portage/package.accept_keywords
sudo cp $SHARE/rpi/accept_keywords-raspberrypi \
    $RPI_TARGET/etc/portage/package.accept_keywords/raspberrypi

}
# Emerge rpi-sources
sudo $SHARE/vagrant-box/chroot-rpi.sh \
    'ROOT=/ CBUILD=$(portageq envvar CHOST) HOSTCC=$CBUILD-gcc USE=symlink emerge raspberrypi-sources'

sudo $SHARE/vagrant-box/chroot-rpi.sh \
    "printf 'sys-boot/raspberrypi-firmware raspberrypi-videocore-bin\n' >> /etc/portage/package.license"
# ########################## QEMU CHROOT END ####################

# build kernel
cd $RPI_TARGET/usr/src/linux
cp $SHARE/rpi/config-5.4.y .config
ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"

printf '# ################## #\n'
printf '# Populating /boot\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Populating_.2Fboot\n'
printf '# ################## #\n'
sudo cp -rv $RPI_FILES/firmware/boot/* $RPI_TARGET/boot/
sudo cp $RPI_TARGET/usr/src/linux/arch/arm64/boot/Image $RPI_TARGET/boot/kernel8.img

printf '## ################## #\n'
printf '## Install the device tree\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_device_tree\n'
printf '## ################## #\n'
sudo mv $RPI_TARGET/boot/bcm2711-rpi-4-b.dtb $RPI_TARGET/boot/bcm2711-rpi-4-b.dtb_32
sudo cp $RPI_TARGET/usr/src/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb $RPI_TARGET/boot/

printf '## ################## #\n'
printf '## Install the kernel modules\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_kernel_modules\n'
printf '## ################## #\n'
cd $RPI_TARGET/usr/src/linux/
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

printf '## ################## #\n'
printf '## rasberrypi/tools\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi4_64_Bit_Install#rasberrypi.2Ftools\n'
printf '## ################## #\n'
cd $RPI_FILES
git clone https://github.com/raspberrypi/tools
cd tools/armstubs
make CC8=aarch64-unknown-linux-gnu-gcc LD8=aarch64-unknown-linux-gnu-ld OBJCOPY8=aarch64-unknown-linux-gnu-objcopy OBJDUMP8=aarch64-unknown-linux-gnu-objdump armstub8-gic.bin
sudo cp armstub8-gic.bin $RPI_TARGET/boot/

printf '## ################## #\n'
printf '## Root password\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Root_Password\n'
printf '## ################## #\n'
sudo sed -iE 's#^root:.*$#root:$6$xxPVR/Td5iP$/7Asdgq0ux2sgNkklnndcG4g3493kUYfrrdenBXjxBxEsoLneJpDAwOyX/kkpFB4pU5dlhHEyN0SK4eh/WpmO0::0:99999:7:::#' \
    $RPI_TARGET/etc/passwd

printf '## ################## #\n'
printf '## /etc/fstab\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fetc.2Ffstab\n'
printf '## ################## #\n'
sudo cp $SHARE/rpi/fstab $RPI_TARGET/etc/fstab

printf '## ################## #\n'
printf '## /boot/config.txt\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fboot.2Fconfig.txt\n'
printf '## ################## #\n'
sudo cp $SHARE/rpi/config.txt $RPI_TARGET/boot/config.txt

printf '## ################## #\n'
printf '## /boot/cmdline.txt\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fboot.2Fcmdline.txt\n'
printf '## ################## #\n'
sudo cp $SHARE/rpi/cmdline.txt $RPI_TARGET/boot
