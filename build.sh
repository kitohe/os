#!/bin/bash

echo "Building bootloader..."
eval make bootloader

cd build

echo "Generating iso..."
eval genisoimage -no-emul-boot -boot-load-size 4 -input-charset iso8859-1 -o bootloader.iso -b bootloader.bin .

echo "Done"
