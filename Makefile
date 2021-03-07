AS=nasm
ASFLAGS=-Wall

GCC=i686-elf-gcc
CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra

LFLAGS=-ffreestanding -O2 -nostdlib -lgcc
# LFLAGS=-melf_i386 --build-id=none
LINK=link.ld

bootloader: 
	$(AS) $(ASFLAGS) -f bin stage0.asm -o ./build/bootloader.bin 

bootloader-linkable:
	$(AS) $(ASFLAGS) -f elf32 stage0.asm -o ./build/bootloader_linkable.o

kernel:
	$(GCC) $(CFLAGS) -c kernel.c -o ./build/kernel.o

# link:
# 	$(LD) $(LFLAGS) -T $(LINK) ./build/bootloader_linkable.o -o ./build/kernel.elf

link:
	$(GCC) $(LFLAGS) -T $(LINK) ./build/bootloader_linkable.o ./build/kernel.o -o ./build/os.bin

all:
	bootloader_linkable kernel link

clean:
	rm ./build/*.o
	rm ./build/*.bin
