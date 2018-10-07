# Summary
This directory contains LEDE (previously: OpenWRT) firmwares for ARM, MIPS and x86-64 which can be booted in QEMU giving us a number of embeded platforms to play with.
The images run in a RAM filesystem. All changes will be lost on reboot.

# Requirements/Assumptions
1. QEMU is installed 

QEMU maps port 2122/tcp on localhoste to 22/tcp on the virtual machine. If you want to run two QEMU instances simultaneously  update the start.sh and specify unique listen ports.

# How to get going
1. Go into the directory for your desired platform 
2. Run 'start.sh' it will download/start LEDE in QEMU. 
3. SSH into the virtual machine with ```ssh root@localhost -p 2122```. The password is 'admin'
