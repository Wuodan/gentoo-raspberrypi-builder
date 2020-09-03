#!/bin/bash

# Created by argbash-init v2.9.0
# ARG_OPTIONAL_SINGLE([rpi-folder],[f],[root folder for chroot],[/home/vagrant/rpi-install])
# ARG_OPTIONAL_SINGLE([disk],[d],[disk of the SD card],[/dev/sdb])
# ARG_OPTIONAL_SINGLE([mountpoint],[m],[mountpoint for the rpi root partition on the SD card],[/mnt/gentoo])
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
	local first_option all_short_options='fdmh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_rpi_folder="/home/vagrant/rpi-install"
_arg_disk="/dev/sdb"
_arg_mountpoint="/mnt/gentoo"


print_help()
{
	printf '%s\n' "<The general help message of my script>"
	printf 'Usage: %s [-f|--rpi-folder <arg>] [-d|--disk <arg>] [-m|--mountpoint <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-f, --rpi-folder: root folder for chroot (default: '/home/vagrant/rpi-install')"
	printf '\t%s\n' "-d, --disk: disk of the SD card (default: '/dev/sdb')"
	printf '\t%s\n' "-m, --mountpoint: mountpoint for the rpi root partition on the SD card (default: '/mnt/gentoo')"
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
			-d|--disk)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_disk="$2"
				shift
				;;
			--disk=*)
				_arg_disk="${_key##--disk=}"
				;;
			-d*)
				_arg_disk="${_key##-d}"
				;;
			-m|--mountpoint)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_mountpoint="$2"
				shift
				;;
			--mountpoint=*)
				_arg_mountpoint="${_key##--mountpoint=}"
				;;
			-m*)
				_arg_mountpoint="${_key##-m}"
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

parted -s "${_arg_disk}" mklabel msdos

parted -s "${_arg_disk}" unit mib mkpart primary fat32 1 129
parted -s "${_arg_disk}" unit mib mkpart primary linux-swap 129 $((16384 + 129))
parted -s "${_arg_disk}" unit mib mkpart primary ext4 $((16384 + 129)) 100%

parted "${_arg_disk}" set 1 boot on

emerge sys-fs/dosfstools

mkfs -t vfat -F 32 "${_arg_disk}"1
mkswap "${_arg_disk}"2
mkfs -F -i 8192 -t ext4 "${_arg_disk}"3
sync

mount "${_arg_disk}"3 $_arg_mountpoint
mkdir $_arg_mountpoint/boot
mount "${_arg_disk}"1 $_arg_mountpoint/boot
rsync -aAx \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/var/tmp/*","/lost+found/*"} \
    --info=progress2,stats \
    $_arg_rpi_folder/ \
    $_arg_mountpoint
sync

umount $_arg_mountpoint{/boot,}

# ] <-- needed because of Argbash
