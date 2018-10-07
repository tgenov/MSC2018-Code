#!/bin/bash
set -eu
set -o pipefail

URL="http://master-thesis-lede-images.s3-eu-west-1.amazonaws.com/x86/openwrt-x86-64-ramfs.bzImage"
ARCH="x86_64"
MACHINE="q35"
CPU='core2duo'
RAM=64
LISTEN_PORT=2122

function get_kernel()
{
   wget -O openwrt-kernel $URL
}

function start_qemu() {
  qemu-system-$ARCH -M $MACHINE -m $RAM -cpu $CPU \
  -kernel openwrt-kernel \
  -append "root=/dev/sda debug verbose console=ttyS0" \
  -net user,hostfwd=tcp::$LISTEN_PORT-:22 \
  -net nic \
  -nographic
}

if [ ! -f 'openwrt-kernel' ]; then
  get_kernel
fi

start_qemu
