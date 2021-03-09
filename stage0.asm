[org 0x7c00]
[bits 16]

entry:
    cli                 ; disable interrupts
    cld                 ; clear direction flag | lowest to highest 

    ; Setup a20 https://wiki.osdev.org/A20_Line
    in al, 0x92
    or al, 2
    out 0x92, al

    xor ax, ax
    mov ds, ax

    lgdt [gdt]          ; Load GDT

    ; enter protected mode
	mov eax, cr0
	or  eax, (1 << 0)
	mov cr0, eax

    jmp 0x0018:segg    ; jmp far to load CS

[bits 32]
segg:
    ; Set segments
    mov ax, 0x20        ; Offset to DS
    mov es, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Setup stack
    cli                 ; disable interrupts while setting up stack
    mov esp, 0x7c00     ; advance stack 0x7c00 bytes 
    sti                 ; re-enable interrupts

    ; call kernel
    call kmain
stop:
    hlt
    jmp stop

align 8
gdt_base:
    dq 0x0000000000000000 ; 0x0000 | Null descriptor
    dq 0x00009a007c00ffff ; 0x0008 | CS | 16-bit code segment descriptor, segment present, base 0x7c00
    dq 0x000092000000ffff ; 0x0010 | DS | 16-bit data segment descriptor, segment present, base 0
    dq 0x00cf9a000000ffff ; 0x0018 | CS | 32-bit code segment descriptor, segment present, base 0
    dq 0x00cf92000000ffff ; 0x0020 | DS | 32-bit data segment descriptor, segment present, base 0
gdt:
    dw gdt - gdt_base - 1 ; For limit storage
    dd gdt_base

times 510 - ($ - $$)  db 0  ; Zerofill up to 510 bytes
dw 0xaa55                   ; Boot Sector signature
