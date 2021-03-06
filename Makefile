AS=nasm
ASFLAGS=-Wall

GCC=gcc
CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra

LD=ld
LFLAGS=-melf_i386 --build-id=none
LINK=link.ld

bootloader: 
	$(AS) $(ASFLAGS) -f bin stage0.asm -o ./build/bootloader.bin 

bootloader-linkable:
	$(AS) $(ASFLAGS) -f elf32 stage0.asm -o ./build/bootloader_linkable.o

kernel:
	$(GCC) $(CFLAGS) kernel.c -o ./build/kernel.o

link:
	$(LD) $(LFLAGS) -T $(LINK) ./build/bootloader_linkable.o -o ./build/kernel.elf
