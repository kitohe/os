#!/bin/bash

echo "Building linkable bootloader..."
eval make bootloader-linkable

echo "Building kernel..."
eval make kernel

echo "Linking..."
eval make link

cd ./build

echo "Transfering to bin..."
eval objcopy -O binary os.bin bootloader.bin

echo "Building bootable image..."
eval genisoimage -no-emul-boot -boot-load-size 4 -input-charset iso8859-1 -o bootloader.iso -b bootloader.bin .

echo "Done"