#!/bin/bash

echo "Building linkable bootloader..."
eval make bootloader-linkable

echo "Linking..."
eval make link

cd ./build

echo "Transfering to bin..."
eval objcopy -O binary kernel.elf bootloader.bin

echo "Building bootable image..."
eval genisoimage -no-emul-boot -boot-load-size 4 -input-charset iso8859-1 -o bootloader.iso -b bootloader.bin .

echo "Done"