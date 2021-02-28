[org 0x7c00]
[bits 16]

begin:
    ; setup a20 https://wiki.osdev.org/A20_Line
    in al, 0x92
    or al, 2
    out 0x92, al

    ; setup stack
    jmp short stack

    mov ax, 0xffff
    mov ds, ax
    mov ax, [ds:0x10]

loop:
    ; print a infinitely
    mov ah, 0xe
    mov al, 'a'
    int 0x10
    jmp loop

stack:
    cli             ; disable interrupts while setting up stack
    mov ax, 0x7c0   ; 0x7c00 / 0x10 = 0x7c0
    add ax, 20h     ; Effective Address = Segment * 16 (0x10) + Offset
    mov ss, ax      ; real address of ss = 0x7c0 * 0x10 + 0x0 = 0x7e00
    mov sp, 4096    ; advance stack 4096 bytes 
    sti             ; re-enable interrupts

    jmp short loop
 
times 510 - ($ - $$)  db 0  ; Zerofill up to 510 bytes
dw 0AA55h                   ; Boot Sector signature
