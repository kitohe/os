AS=nasm
ASFLAGS=-Wall

CC=i686-elf-gcc
CFLAGS=-std=gnu99 -ffreestanding -O0 -Wall -Wextra

LFLAGS=-ffreestanding -O0 -nostdlib -lgcc
LINK=../link.ld

BOOTLOADER_ENTRY=0x7e00
OUT=../build

C_SRCS := $(wildcard *.c) # find all C files
C_OBJS := $(patsubst %.c, %.o, $(C_SRCS)) # substitue all .c files to .o

AS_SRCS := $(wildcard *.asm)
AS_SRSC := $(filter-out stage0.asm, $(AS_SRCS))
AS_OBJS := $(patsubst %.asm, %.o, $(AS_SRCS)) # substitue all .c files to .o
AS_OBJS := $(filter-out stage0.o, $(AS_OBJS))

OBJS := $(C_OBJS) $(AS_OBJS)
OBJS := $(addprefix $(OUT)/, $(OBJS))

.PHONY: all clean

all: stage0 $(C_OBJS) $(AS_OBJS) link bootloader-obj img iso clean

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $(OUT)/$@

%.o: %.asm
	$(AS) $(ASFLAGS) -f elf32 $< -o $(OUT)/$@

stage0:
	$(AS) $(ASFLAGS) -f bin stage0.asm -o $(OUT)/stage0.bin -Dbmain=$(BOOTLOADER_ENTRY)

link:
	$(CC) $(LFLAGS) -T $(LINK) $(OBJS) -o $(OUT)/out.o

bootloader-obj:
	objcopy -O binary $(OUT)/out.o $(OUT)/bootloader.bin

img:
	dd if=/dev/zero of=$(OUT)/bootloader.img bs=1024 count=1440
	dd if=$(OUT)/stage0.bin of=$(OUT)/bootloader.img conv=notrunc
	dd if=$(OUT)/bootloader.bin of=$(OUT)/bootloader.img conv=notrunc seek=1

iso:
	cd ../build && genisoimage -no-emul-boot -boot-load-size 4 -input-charset iso8859-1 -o bootloader.iso -b bootloader.img .

clean:
	rm $(OUT)/*.o
	rm $(OUT)/*.bin
	rm $(OUT)/*.img