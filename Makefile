AS=nasm
ASFLAGS=

bootloader: 
	$(AS) $(ASFLAGS) -f bin -o ./build/bootloader.bin stage0.asm
