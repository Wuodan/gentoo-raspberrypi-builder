#!/bin/bash

# Created by argbash-init v2.9.0
# ARG_OPTIONAL_SINGLE([rpi-folder],[f],[root folder for chroot],[/home/vagrant/rpi-install])
# ARG_OPTIONAL_SINGLE([share],[s],[folder with files from vbox host],[/home/vagrant/shared])
# ARG_OPTIONAL_SINGLE([rpi-resource],[r],[folder with files for rpi installation],[~/rpi-files])
# ARG_DEFAULTS_POS()
# ARG_HELP([<The general help message of my script>])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.9.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='fsrh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_rpi_folder="/home/vagrant/rpi-install"
_arg_share="/home/vagrant/shared"
_arg_rpi_resource="~/rpi-files"


print_help()
{
	printf '%s\n' "<The general help message of my script>"
	printf 'Usage: %s [-f|--rpi-folder <arg>] [-s|--share <arg>] [-r|--rpi-resource <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-f, --rpi-folder: root folder for chroot (default: '/home/vagrant/rpi-install')"
	printf '\t%s\n' "-s, --share: folder with files from vbox host (default: '/home/vagrant/shared')"
	printf '\t%s\n' "-r, --rpi-resource: folder with files for rpi installation (default: '~/rpi-files')"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-f|--rpi-folder)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_rpi_folder="$2"
				shift
				;;
			--rpi-folder=*)
				_arg_rpi_folder="${_key##--rpi-folder=}"
				;;
			-f*)
				_arg_rpi_folder="${_key##-f}"
				;;
			-s|--share)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_share="$2"
				shift
				;;
			--share=*)
				_arg_share="${_key##--share=}"
				;;
			-s*)
				_arg_share="${_key##-s}"
				;;
			-r|--rpi-resource)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_rpi_resource="$2"
				shift
				;;
			--rpi-resource=*)
				_arg_rpi_resource="${_key##--rpi-resource=}"
				;;
			-r*)
				_arg_rpi_resource="${_key##-r}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash



set -eu

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
sudo cp $_arg_share/vagrant-box/crossdev.conf /etc/portage/repos.conf

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
mkdir $_arg_rpi_resource
cd $_arg_rpi_resource
git clone -b stable --depth=1 https://github.com/raspberrypi/firmware

# printf '# ################## #\n'
# printf '# Fetch, configure and build the Raspberry Pi kernel\n'
# printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch.2C_configure_and_build_the_Raspberry_Pi_kernel\n'
# printf '# ################## #\n'
# git clone https://github.com/raspberrypi/linux
# cd $_arg_rpi_resource/linux
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make bcm2711_defconfig
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make menuconfig
# cp $_arg_share/rpi/config-5.4.y .config
# ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"


printf '# ################## #\n'
printf '# Fetch the Gentoo bits of the install\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Fetch_the_Gentoo_bits_of_the_install\n'
printf '# ################## #\n'
sudo mkdir -p $_arg_rpi_folder
cd $_arg_rpi_folder

printf '## ################## #\n'
printf '## Install the arm64 stage 3\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_arm64_stage_3\n'
printf '## ################## #\n'
cd $_arg_rpi_folder
sudo wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2.DIGESTS
sudo wget http://distfiles.gentoo.org/experimental/arm64/stage3-arm64-20200609.tar.bz2
b2sum stage3-arm64-20200609.tar.bz2 | grep -q -f - stage3-arm64-20200609.tar.bz2.DIGESTS || (printf 'verify failed\n' && exit 1)
sudo tar xpvf stage3-*.tar.bz2 --xattrs-include='*.*' --numeric-owner
sudo rm stage3-arm64-20200609.tar.bz2*
sudo rm -rf $_arg_rpi_folder/tmp/*

printf '## ################## #\n'
printf '## Install a Gentoo repository snapshot\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_a_Gentoo_repository_snapshot\n'
printf '## ################## #\n'
cd $_arg_rpi_folder
sudo wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2.md5sum
sudo wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2
cd $_arg_rpi_folder
md5sum portage-latest.tar.bz2 | grep -q -f - portage-latest.tar.bz2.md5sum || (printf 'verify failed\n' && exit 1)
sudo mkdir --parents $_arg_rpi_folder/var/db/repos/gentoo
sudo tar xvpf portage-latest.tar.bz2 --strip-components=1 -C $_arg_rpi_folder/var/db/repos/gentoo
sudo rm portage-latest.tar.bz2*
sudo mkdir --parents $_arg_rpi_folder/etc/portage/repos.conf
sudo cp $_arg_rpi_folder/usr/share/portage/config/repos.conf $_arg_rpi_folder/etc/portage/repos.conf/gentoo.conf
sudo cp --dereference /etc/resolv.conf $_arg_rpi_folder/etc/

sudo cp /home/vagrant/shared/rpi/make.conf $_arg_rpi_folder/etc/portage

# ########################## QEMU CHROOT START ####################
# Setup chroot
sudo cp $_arg_share/vagrant-box/package.use.qemu /etc/portage/package.use/qemu
sudo emerge qemu
quickpkg qemu
cd $_arg_rpi_folder
sudo ROOT=$PWD/ emerge --usepkgonly --oneshot --nodeps qemu

# Configure
sudo $_arg_share/vagrant-box/chroot-rpi.sh 'eselect profile set default/linux/arm64/17.0'
sudo $_arg_share/vagrant-box/chroot-rpi.sh 'ln -s /tmp /usr/aarch64-unknown-linux-gnu/tmp'
sudo $_arg_share/vagrant-box/chroot-rpi.sh locale-gen
# sudo $_arg_share/vagrant-box/chroot-rpi.sh gcc-config -l
# sudo $_arg_share/vagrant-box/chroot-rpi.sh ldconfig -v
sudo $_arg_share/vagrant-box/chroot-rpi.sh 'ROOT=/ env-update'

sudo cp $_arg_share/rpi/emerge-chroot $_arg_rpi_folder/usr/local/sbin

sudo mv $_arg_rpi_folder/etc/portage/package.keywords \
    $_arg_rpi_folder/etc/portage/package.accept_keywords
sudo cp $_arg_share/rpi/accept_keywords-raspberrypi \
    $_arg_rpi_folder/etc/portage/package.accept_keywords/raspberrypi

# Emerge rpi-sources
sudo $_arg_share/vagrant-box/chroot-rpi.sh \
    'emerge-chroot raspberrypi-sources'

sudo $_arg_share/vagrant-box/chroot-rpi.sh \
    "printf 'sys-boot/raspberrypi-firmware raspberrypi-videocore-bin\n' >> /etc/portage/package.license"
# ########################## QEMU CHROOT END ####################

# build kernel
cd $_arg_rpi_folder/usr/src/linux
cp $_arg_share/rpi/config-5.4.y .config
ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make -j"$(($(nproc)+1))"

printf '# ################## #\n'
printf '# Populating /boot\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Populating_.2Fboot\n'
printf '# ################## #\n'
sudo cp -rv $_arg_rpi_resource/firmware/boot/* $_arg_rpi_folder/boot/
sudo cp $_arg_rpi_folder/usr/src/linux/arch/arm64/boot/Image $_arg_rpi_folder/boot/kernel8.img

printf '## ################## #\n'
printf '## Install the device tree\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_device_tree\n'
printf '## ################## #\n'
sudo mv $_arg_rpi_folder/boot/bcm2711-rpi-4-b.dtb $_arg_rpi_folder/boot/bcm2711-rpi-4-b.dtb_32
sudo cp $_arg_rpi_folder/usr/src/linux/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb $_arg_rpi_folder/boot/

printf '## ################## #\n'
printf '## Install the kernel modules\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_the_kernel_modules\n'
printf '## ################## #\n'
cd $_arg_rpi_folder/usr/src/linux/
sudo ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- make modules_install INSTALL_MOD_PATH=$_arg_rpi_folder


printf '# ################## #\n'
printf '# Raspberry Pi 3 peripherals\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Raspberry_Pi_3_peripherals\n'
printf '# ################## #\n'

printf '## ################## #\n'
printf '## Serial port configuration\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Serial_port_configuration\n'
printf '## ################## #\n'
sudo sed -iE 's@^f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100$@# \0@' $_arg_rpi_folder/etc/inittab
sudo cp $_arg_share/rpi/99-com.rules $_arg_rpi_folder/etc/udev/rules.d/99-com.rules
printf '## ################## #\n'
printf '## Install WiFi firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_WiFi_firmware\n'
printf '## ################## #\n'
cd $_arg_rpi_resource/
git clone https://github.com/RPi-Distro/firmware-nonfree
sudo mkdir -p $_arg_rpi_folder/lib/firmware/brcm
sudo cp $_arg_rpi_resource/firmware-nonfree/brcm/brcmfmac43455-sdio.* $_arg_rpi_folder/lib/firmware/brcm/

printf '## ################## #\n'
printf '## Install Bluetooth firmware\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Install_Bluetooth_firmware\n'
printf '## ################## #\n'
sudo wget -P $_arg_rpi_folder/lib/firmware/brcm https://raw.githubusercontent.com/RPi-Distro/bluez-firmware/master/broadcom/BCM4345C0.hcd


printf '# ################## #\n'
printf '# Setup\n'
printf '# https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Setup\n'
printf '# ################## #\n'

printf '## ################## #\n'
printf '## rasberrypi/tools\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi4_64_Bit_Install#rasberrypi.2Ftools\n'
printf '## ################## #\n'
cd $_arg_rpi_resource
git clone https://github.com/raspberrypi/tools
cd tools/armstubs
make CC8=aarch64-unknown-linux-gnu-gcc LD8=aarch64-unknown-linux-gnu-ld OBJCOPY8=aarch64-unknown-linux-gnu-objcopy OBJDUMP8=aarch64-unknown-linux-gnu-objdump armstub8-gic.bin
sudo cp armstub8-gic.bin $_arg_rpi_folder/boot/

printf '## ################## #\n'
printf '## Root password\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#Root_Password\n'
printf '## ################## #\n'
sudo sed -iE 's#^root:.*$#root:$6$xxPVR/Td5iP$/7Asdgq0ux2sgNkklnndcG4g3493kUYfrrdenBXjxBxEsoLneJpDAwOyX/kkpFB4pU5dlhHEyN0SK4eh/WpmO0::0:99999:7:::#' \
    $_arg_rpi_folder/etc/shadow

printf '## ################## #\n'
printf '## /etc/fstab\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fetc.2Ffstab\n'
printf '## ################## #\n'
sudo cp $_arg_share/rpi/fstab $_arg_rpi_folder/etc/fstab

printf '## ################## #\n'
printf '## /boot/config.txt\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fboot.2Fconfig.txt\n'
printf '## ################## #\n'
sudo cp $_arg_share/rpi/config.txt $_arg_rpi_folder/boot/config.txt

printf '## ################## #\n'
printf '## /boot/cmdline.txt\n'
printf '## https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install#.2Fboot.2Fcmdline.txt\n'
printf '## ################## #\n'
sudo cp $_arg_share/rpi/cmdline.txt $_arg_rpi_folder/boot

# parted to setup SD card
emerge parted

# more configuration in chroot

printf '## ################## #\n'
printf '## ssh on boot\n'
printf '## ################## #\n'
sudo $_arg_share/vagrant-box/chroot-rpi.sh \
    'rc-update add sshd default'

printf '## ################## #\n'
printf '## emerge wpa_supplicant\n'
printf '## ################## #\n'
sudo $_arg_share/vagrant-box/chroot-rpi.sh \
   'emerge-chroot  net-misc/dhcpcd net-wireless/wpa_supplicant net-misc/openssh'
sudo $_arg_share/vagrant-box/chroot-rpi.sh \
    'rc-update add dhcpcd default'
sudo $_arg_share/vagrant-box/chroot-rpi.sh \
    'rc-update add wpa_supplicant default'

# add a wifi network to wpa_supplicant

# ] <-- needed because of Argbash
