#!/bin/bash

echo "Building binaries..."
eval make all

echo "Generating iso..."
eval genisoimage -no-emul-boot -boot-load-size 4 -input-charset iso8859-1 -o bootloader.iso -b bootloader.img .

cd ..
echo "Cleaning..."
eval make clean

echo "Done"
