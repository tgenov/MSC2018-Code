#!/bin/bash
set -eux
set -o pipefail

URL="http://master-thesis-lede-images.s3-eu-west-1.amazonaws.com/arm/openwrt-armvirt-64-Image-initramfs"
ARCH="aarch64"
CPU="cortex-a57"
MACHINE="virt"
RAM=64
LISTEN_PORT=2122

function get_kernel()
{
   wget -O openwrt-kernel $URL
}

function start-qemu() {
  qemu-system-$ARCH -m $RAM -M $MACHINE -cpu $CPU \
  -net user,hostfwd=tcp::$LISTEN_PORT-:22 \
  -net nic \
  -kernel openwrt-kernel \
  -nographic
}

if [ ! -f 'openwrt-kernel' ]; then
  get_kernel
fi

start-qemu
