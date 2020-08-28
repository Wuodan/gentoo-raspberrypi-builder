#!/bin/bash

set -eu

printf '# ################## #\n'
printf '# Rebuild kernel for USB 3\n'
printf '# https://wiki.gentoo.org/wiki/USB/Guide\n'
printf '# ################## #\n'
cd /usr/src/linux
cp .config .config.old
patch < /home/vagrant/shared/vagrant-box/kernel.5.4.48-gentoo.config.patch
make -j"$(($(nproc)+1))"
make install
make clean
rm -rf /boot/*.old
