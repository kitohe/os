AS=nasm
ASFLAGS=-Wall

GCC=i686-elf-gcc
CFLAGS=-std=gnu99 -ffreestanding -O0 -Wall -Wextra

LFLAGS=-ffreestanding -O0 -nostdlib -lgcc
LINK=../link.ld

BOOTLOADER_ENTRY=0x7e00
OUT=../build

all: stage0 idt bootloader link bootloader-obj img

stage0: 
	$(AS) $(ASFLAGS) -f bin stage0.asm -o $(OUT)/stage0.bin -Dbmain=$(BOOTLOADER_ENTRY)

bootloader-linkable:
	$(AS) $(ASFLAGS) -f elf32 stage0.asm -o $(OUT)/bootloader_linkable.o

idt:
	$(AS) $(ASFLAGS) -f elf32 idt.asm -o $(OUT)/idt_asm.o

bootloader:
	$(GCC) $(CFLAGS) -c bootloader.c -o $(OUT)/bootloader.o
	# $(GCC) $(CFLAGS) -T $(LINK) -c idt.c -o $(OUT)/idt.o

link:
	$(GCC) $(LFLAGS) -T $(LINK) $(OUT)/bootloader.o $(OUT)/idt_asm.o -o $(OUT)/out.o

bootloader-obj:
	objcopy -O binary $(OUT)/out.o $(OUT)/bootloader.bin

img:
	dd if=/dev/zero of=$(OUT)/bootloader.img bs=1024 count=1440
	dd if=$(OUT)/stage0.bin of=$(OUT)/bootloader.img conv=notrunc
	dd if=$(OUT)/bootloader.bin of=$(OUT)/bootloader.img conv=notrunc seek=1

clean:
	rm $(OUT)/*.o
	rm $(OUT)/*.bin
	rm $(OUT)/*.img
