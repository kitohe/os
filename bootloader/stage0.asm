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

    ; The first volume descriptor is the 17th sector of the disk. */
    mov byte [bootdrive], dl        ; save bootdrive
    mov word [sector_size], 0x800   ; assume that sector is 2048 bytes

get_next_desc:
    mov al, 0x10                    ; 17th sector
    mov byte [desc_sector], al

    mov bx, 0x1000                  ; segment selector
    mov es, bx                      ; to load es reg -> reg
    xor bx, bx                      ; contains offset
    mov cx, 0x1                     ; amount of sectors to load

    jmp read_sectors

done_reading:
    mov si, cd_signature            ; get address of cd_signature constant
    mov di, 0x1000                  ; load segment to search
    mov cx, 0x6                     ; load counter, 6 bytes
    repe cmpsb
    je found_desc
found_desc:
    jmp pause
;
; This function loads one or more sectors in memory.
;
; Parameters:
;	EAX		first sector to load.
; 	CX		number of sectors to load.
;	ES:BX	destination address.
;
read_sectors:
    mov byte [disk_address_packet], 0x10        ; DAP size
    mov byte [disk_address_packet + 1], 0x0     ; unused, should be 0
    mov word [disk_address_packet + 2], 0x1     ; number of sectors to be read
    mov word [disk_address_packet + 4], bx      ; segment:offset but offset comes first due to endianess
    mov word [disk_address_packet + 6], es      ; segment comes second
    mov dword [disk_address_packet + 8], eax    ; absolute number of the start of the sectors to be read
    mov dword [disk_address_packet + 12], 0x0

read_one_sector:
    mov ah, 0x42                                ; prepare for int 0x13, ah=0x42 - Extended Read Sectors From Drive
    xor al, al                                  ; clear al
    mov si, disk_address_packet                 ; get address of DAP to si
    mov di, word [bootdrive]                    ; get bootdrive index to di
    int 0x13                                    ; fetch data from bootdrive
    jc pause

    inc word [disk_address_packet + 8]         ; move to next sector
    mov ax, word [sector_size]                 ; get sector size
    shr ax, 0x4                                ; divide by 0x10
    add word [disk_address_packet + 6], ax     ; write new segment to DAP moved 0x800

    loop read_one_sector
    jmp done_reading

pause:
    jmp pause

    lgdt [gdt]          ; Load GDT

    ; enter protected mode
    cli
	mov eax, cr0
	or  eax, (1 << 0)
	mov cr0, eax

    jmp dword 0x0018:segg    ; jmp far to load CS

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

    ; call cbootloader
    call bmain



stop:
    cli
    hlt

align 8
gdt_base:
    dq 0x0000000000000000 ; 0x0000 | Null descriptor
    dq 0x00009a007c00ffff ; 0x0008 | CS | 16-bit code segment descriptor, segment present, base 0x7c00
    dq 0x000092000000ffff ; 0x0010 | DS | 16-bit data segment descriptor, segment present, base 0
    dq 0x00cf9a000000ffff ; 0x0018 | CS | 32-bit code segment descriptor, segment present, base 0
    dq 0x00cf92000000ffff ; 0x0020 | DS | 32-bit data segment descriptor, segment present, base 0
gdt:
    dw gdt - gdt_base - 1 ; For limit storage
    dd gdt_base           ; Start of GDT

bootdrive:              dw 0
sector_size:            dw 0
desc_sector:            db 0
disk_address_packet:    resb 16
cd_signature:           db 0x2, 'CD001'
joilet_signature:       db 0x25, 0x2f, 0x45

times 510 - ($ - $$)  db 0  ; Zerofill up to 510 bytes
dw 0xaa55                   ; Boot Sector signature
