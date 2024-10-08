#!/bin/bash

# CCA root directory
HOME_DIR="${HOME}"

NUM_CPUS=8
MAX_RAM=8192

CPU_FEATURES="pmu=on,sve=on,sve128=on,sve256=on,neon=on"
CPU="${CPU},$CPU_FEATURES"

# QEMU command with parameters
sudo qemu-system-aarch64 \
    -smp ${NUM_CPUS} \
    -m ${MAX_RAM} \
    -cpu max \
    -M virt,secure=on,mte=off \
    -nographic \
    -bios arm-trusted-firmware/flash.bin \
    -kernel linux/arch/arm64/boot/Image \
    -append 'console=ttyAMA0,38400 keep_bootcon root=/dev/vda1 rw' \
    -drive format=qcow2,if=none,file=rootfs.qcow2,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -virtfs local,path="${HOME_DIR}",mount_tag=host0,security_model=mapped,id=host0 \
    -fsdev local,id=fsdev0,path="${HOME_DIR}",security_model=none \
    -device virtio-9p-device,fsdev=fsdev0,mount_tag=hosts \
    -chardev socket,id=char0,path=/tmp/vhostqemu \
    -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=myfs \
    -object memory-backend-memfd,id=mem,size=8G,share=on \
    -numa node,memdev=mem \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0,max-bytes=1024,period=1000 \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2221-:22 \
    -serial mon:stdio \
    -d unimp,guest_errors \
    -no-acpi
