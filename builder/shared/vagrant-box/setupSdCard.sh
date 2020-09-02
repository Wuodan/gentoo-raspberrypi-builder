#!/bin/bash

set -eu

RPI_TARGET=/home/vagrant/rpi-install
MOUNT=/mnt/gentoo

DISK="${1:-/dev/sdb}"

parted -s "${DISK}" mklabel msdos

parted -s "${DISK}" unit mib mkpart primary fat32 1 129
parted -s "${DISK}" unit mib mkpart primary linux-swap 129 $((16384 + 129))
parted -s "${DISK}" unit mib mkpart primary ext4 $((16384 + 129)) 100%

parted "${DISK}" set 1 boot on

emerge sys-fs/dosfstools

mkfs -t vfat -F 32 "${DISK}"1
mkswap "${DISK}"2
mkfs -F -i 8192 -t ext4 "${DISK}"3
sync

mount "${DISK}"3 $MOUNT
mkdir $MOUNT/boot
mount "${DISK}"1 $MOUNT/boot

rsync -a --info=progress2,stats $RPI_TARGET/ $MOUNT
sync

umount $MOUNT{/boot,}
