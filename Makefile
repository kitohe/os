AS=nasm
ASFLAGS=-Wall

GCC=i686-elf-gcc
CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra

LFLAGS=-ffreestanding -O2 -nostdlib -lgcc
# LFLAGS=-melf_i386 --build-id=none
LINK=link.ld

KERNEL_ENTRY=0x7e00

all: bootloader kernel kernel-obj img

bootloader: 
	$(AS) $(ASFLAGS) -f bin stage0.asm -o ./build/bootloader.bin -Dkmain=$(KERNEL_ENTRY)

bootloader-linkable:
	$(AS) $(ASFLAGS) -f elf32 stage0.asm -o ./build/bootloader_linkable.o

kernel:
	$(GCC) $(CFLAGS) -T $(LINK) -c kernel.c -o ./build/kernel.o

# link:
# 	$(LD) $(LFLAGS) -T $(LINK) ./build/bootloader_linkable.o -o ./build/kernel.elf

link:
	$(GCC) $(LFLAGS) -T $(LINK) ./build/bootloader_linkable.o ./build/kernel.o -o ./build/os.bin

kernel-obj:
	objcopy -O binary ./build/kernel.o ./build/kernel.bin

img:
	dd if=/dev/zero of=./build/bootloader.img bs=1024 count=1440
	dd if=./build/bootloader.bin of=./build/bootloader.img conv=notrunc
	dd if=./build/kernel.bin of=./build/bootloader.img conv=notrunc seek=1

clean:
	rm ./build/*.o
	rm ./build/*.bin
	rm ./build/*.img
