#!/bin/bash
set -eu
set -o pipefail

VERSION="v18.06.0"
NCPU=$(grep -c ^processor /proc/cpuinfo )
git clone https://github.com/openwrt/openwrt.git || true
cd openwrt && git checkout $VERSION && cd ..
# Add custom config files to our images. https://openwrt.org/docs/guide-developer/quickstart-build-images
cp -rp files openwrt/

# Config files were generated with 'make menuconfig' in LEDE SDK
for config in $(ls -1 build-configs/);do
  mkdir -p images/$config
  rm -f openwrt/.config && cp build-configs/$config openwrt/.config
  cd openwrt && make -j$NCPU && cd ..
done

cp -f openwrt/bin/targets/x86/64/openwrt-x86-64-ramfs.bzImage images/x86/
cp -f openwrt/bin/targets/malta/le/openwrt-malta-le-vmlinux-initramfs.elf images/mips/
cp -f openwrt/bin/targets/armvirt/64/openwrt-armvirt-64-Image-initramfs images/arm/

aws --profile subnet s3 sync images/ s3://master-thesis-lede-images/
