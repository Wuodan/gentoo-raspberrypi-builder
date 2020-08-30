#!/bin/bash

set -eu

RPI_TARGET=/home/vagrant/rpi-install

# [ -e /proc/sys/fs/binfmt_misc/register ] || \
echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64:' \
    2>/dev/null \
    > /proc/sys/fs/binfmt_misc/register || true

mount -o bind /dev "${RPI_TARGET}"/dev
mount -o bind /proc "${RPI_TARGET}"/proc
mount -o bind /sys "${RPI_TARGET}"/sys
mount -o rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000 devpts "${RPI_TARGET}"/dev/pts -t devpts

cp /etc/resolv.conf "${RPI_TARGET}"/etc/

RETURN=0
if [ $# -gt 0 ]; then
    chroot "${RPI_TARGET}" /bin/bash -c "${@}" || RETURN=$?
else
    chroot "${RPI_TARGET}" /bin/bash --login
fi

umount "${RPI_TARGET}"/{proc,sys,dev/pts,dev}

exit $RETURN
