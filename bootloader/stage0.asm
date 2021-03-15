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
    lidt [idt]          ; Load IDT

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

    ; remap PICs
    ; https://en.wikibooks.org/wiki/X86_Assembly/Programmable_Interrupt_Controller
    ; https://wiki.osdev.org/PIC
    ; http://www.brokenthorn.com/Resources/OSDevPic.html
    ; ICW 1
    mov al, 0x11        ; restart vector
    out 0x20, al        ; restart master PIC
    out 0xa0, al        ; restart slave PIC

    ; ICW 2
    mov al, 0x20        ; interrupts offset 32..39
    out 0x21, al        ; make master PIC vector offset to 0x20 (32)
    mov al, 0x28        ; interrupts offset 40..47
    out 0xa1, al        ; make slave PIC vector offset to 0x28 (40)

    ; ICW 3 setup PIC cascading
    mov al, 0x04        ; make IRQ2 to be connected to slave 0b100
    out 0x21, al        ; write it to master PIC
    mov al, 0x02        ; the 80x86 architecture uses IRQ line 2 to connect the master PIC to the slave PIC.
    out 0xa1, al        ; write it to slave PIC

    ; ICW 4
    mov al, 0x01        ; put PIC in x86 mode
    out 0x21, al        ; write to master PIC
    out 0xa1, al        ; write to slave PIC

    ; call cbootloader
    call bmain
stop:
    hlt
    jmp stop

isr0:
    ret

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

align 8
idt_base:
irq0:
      dw isr0
      dw 0x0008
      db 0x00
      db 10101110b
      dw 0x0000
idt:
    dw idt - idt_base - 1
    dd idt_base


times 510 - ($ - $$)  db 0  ; Zerofill up to 510 bytes
dw 0xaa55                   ; Boot Sector signature
