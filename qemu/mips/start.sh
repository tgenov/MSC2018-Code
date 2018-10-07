#!/bin/bash
set -eu
set -o pipefail

URL="http://master-thesis-lede-images.s3-eu-west-1.amazonaws.com/mips/openwrt-malta-le-vmlinux-initramfs.elf"
ARCH="mipsel"
MACHINE="malta"
RAM=64
LISTEN_PORT=2122

function get_kernel()
{
   wget -O openwrt-kernel $URL
}

function start_qemu() {
  qemu-system-$ARCH -M $MACHINE -m $RAM  \
  -kernel openwrt-kernel \
  -net user,hostfwd=tcp::2122-:22 \
  -net nic \
  -nographic
}

if [ ! -f 'openwrt-kernel' ]; then
  get_kernel
fi

start_qemu
