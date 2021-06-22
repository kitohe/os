[org 0x7c00]
[bits 16]

entry:
    xchg bx, bx
    cli                 ; disable interrupts
    cld                 ; clear direction flag | lowest to highest 

    ; Setup a20 https://wiki.osdev.org/A20_Line
    in al, 0x92
    or al, 2
    out 0x92, al

    xor ax, ax
    mov ds, ax

    ; The first volume descriptor is the 17th sector of the disk.
    ; per Joilet format specification:
    ; https://docs.microsoft.com/en-us/windows/win32/imapi/disc-formats#joliet
    mov byte [bootdrive], dl        ; save bootdrive
    mov word [sector_size], 0x800   ; assume that sector is 2048 bytes (CD-ROM/DVD)
    mov eax, 0x10                    ; 17th sector, this is where Joiliet header should be located

get_next_desc:
    mov dword [desc_sector], eax    ; save currently processed sector
    mov bx, 0x1000                  ; segment selector
    mov cx, 0x1                     ; amount of sectors to load (1)

    call read_sectors
    jmp done_reading

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
    mov dl, byte [bootdrive]                    ; get bootdrive index to di
    int 0x13                                    ; fetch data from bootdrive
    jc pause                                    ; stop on error

    inc dword [disk_address_packet + 8]         ; move to next sector
    mov ax, word [sector_size]                  ; get sector size
    shr ax, 0x4                                 ; divide by 0x10
    add word [disk_address_packet + 6], ax      ; write new segment to DAP moved 0x800
    cmp cx, 0x1b2
    je tt
after_tt:
    loop read_one_sector
    ret

tt:
    ;nop
    xchg bx, bx
    jmp after_tt

done_reading:
    mov si, cd_signature            ; get address of cd_signature constant
    mov di, 0x1000                  ; load segment to search
    mov cx, 0x6                     ; load counter, 6
    repe cmpsb

    je found_desc                   ; if we've found correct description we continue
    cmp byte [es:0x1000], 0xff
    jmp next_desc

found_desc:
    mov si, joilet_signature        ; load Joliet signature to si
    mov di, 0x1058                  ; segment that we are searching
    mov cx, 0x3                     ; load counter, 3
    repe cmpsb
    jne next_desc                   ; we didn't find correct description, continue searching...

    ; at this point we have correct session, we can start downloading code
    mov si, done
    call print_string
    ; ----
    ; Primary Volume Descriptor begins at offset 156 (0x9c),
    ; First bit (156th) is directory entry length
    ; Second bit (157th) is extended attribute record length
    ; Next byte (158-165) is Location of file
    ; Byte after that (166-173) is file size
    ; where file happens to be root directory
    ; https://slideplayer.com/slide/1518077/5/images/27/Figure+The+ISO+9660+directory+entry..jpg
    mov eax, dword [es:0x109e]              ; find root directory start
    mov dword [root_directory_start], eax   ; save it to variable
    mov eax, dword [es:0x10a6]              ; find root directory size
    mov dword [root_directory_size], eax    ; save it to variable

    ; now we have to calculate number of sectors that we will download to memory
    movzx ebx, word [sector_size]           ; get sector size
    div ebx                                 ; root_directory_size / sector_size; store remainder in edx
    cmp edx, 0x0                            ; check if remainder is 0, if it is continue if not increase sector that have to loaded
    je no_remainder
    inc eax

no_remainder:
    mov word [root_directory_sectors], ax   ; save number of sectors to load, to variable
    mov eax, [root_directory_start]         ; set initial sector to load
    mov bx, 0x1000                          ; load it at 0x1000
    mov cx, [root_directory_sectors]        ; amount of sectors to load
    call read_sectors                       ; load sectors
    ; at this point we have loaded at 0x1000, root directory
    ;-----
    ;-----
    ;xchg bx, bx
    mov di, 0x1000
search_file:
    add di, 25                              ; there should be File Flags field
    cmp byte [es:di], 0                     ; check if this is file @ 0x1025
    jne next_entry                          ; if not search for next entry in root folder

    ; at this point we've found something that could be our file
    ;xchg bx, bx
    push di                                 ; save di
    add di, 8                               ; byte 33 in directory entry is File Identifier, so we need to check if this is what we are looking for
    mov si, img_filename
    mov cx, 0x1b
    repe cmpsb
    pop di
    je found_file

next_entry:
    add di, 7                               ; navigate to `Length of file identifier (file name)`
    movzx ax, byte [es:di]                  ; load this value to ax
    add di, ax                              ; move to last byte of the file name

increment:
    inc di                                  ; move over the last byte of file name, at this point new entry should start
    cmp byte [es:di], 0x0                   ; check if we are already at the byte that new entry starts
    je increment                            ; if we are not, continue moving one byte

    ; check if we have checked all entries of root directory
    mov eax, dword [root_directory_size]    ; get root directory size
    add eax, 0x1000                         ; add it do beggining of the root directory
    cmp di, ax                              ; if it's below we are not at the end
    jb search_file                          ; and it means we look further here

    jmp next_desc                           ; if its above, we need to look somewhere else

found_file:
    ; at this point we are at the correct file, and on the flags fields
    ;xchg bx, bx
    sub di, 25                              ; so we go to the beggining of this entry
    mov eax, dword [es:di+2]                ; get location of this entry
    mov dword [file_start], eax             ; save it to variable
    mov eax, dword [es:di+10]               ; get length of the entry
    mov dword [file_size], eax              ; save it to variable

    ; now we have to calculate number of sectors that we need to load
    movzx ebx, word [sector_size]           ; get sector size to ebx - zero extended
    div ebx                                 ; file_size / sector_size
    cmp edx, 0                              ; check if remainder = 0
    je no_remainder2                        ; if yes, jump
    inc eax                                 ; if no, increase number of sectors that we have to load
no_remainder2:
    mov word [file_sectors], ax             ; save number of sectors to variable
    mov eax, dword [file_start]

    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    xor ecx, ecx
    mov cx, word [file_sectors]
    xchg bx, bx
    call read_sectors
    hlt

next_desc:
    mov eax, dword [desc_sector]
    inc eax
    jmp get_next_desc

pause:
    mov si, done
    call print_string
    jmp pause

;     lgdt [gdt]          ; Load GDT

;     ; enter protected mode
;     cli
; 	mov eax, cr0
; 	or  eax, (1 << 0)
; 	mov cr0, eax

;     jmp dword 0x0018:segg    ; jmp far to load CS

print_string:
    lodsb       ; read a char
    cmp al, 0x0 ; check if it is null terminator
    je return   ; if yes, just return

    mov ah, 0x0e
    mov bx, 0x07
    int 0x10
    jmp print_string

return:
    ret

; [bits 32]
; segg:
;     ; Set segments
;     mov ax, 0x20        ; Offset to DS
;     mov es, ax
;     mov ds, ax
;     mov fs, ax
;     mov gs, ax
;     mov ss, ax

;     ; Setup stack
;     cli                 ; disable interrupts while setting up stack
;     mov esp, 0x7c00     ; advance stack 0x7c00 bytes 
;     sti                 ; re-enable interrupts

;     ; call cbootloader
;     call bmain

; stop:
;     cli
;     hlt

; align 8
; gdt_base:
;     dq 0x0000000000000000 ; 0x0000 | Null descriptor
;     dq 0x00009a007c00ffff ; 0x0008 | CS | 16-bit code segment descriptor, segment present, base 0x7c00
;     dq 0x000092000000ffff ; 0x0010 | DS | 16-bit data segment descriptor, segment present, base 0
;     dq 0x00cf9a000000ffff ; 0x0018 | CS | 32-bit code segment descriptor, segment present, base 0
;     dq 0x00cf92000000ffff ; 0x0020 | DS | 32-bit data segment descriptor, segment present, base 0
; gdt:
;     dw gdt - gdt_base - 1 ; For limit storage
;     dd gdt_base           ; Start of GDT

bootdrive:              db 0
sector_size:            dw 0
disk_address_packet:    resb 16
cd_signature:           db 0x2,'CD001'
joilet_signature:       db 0x25, 0x2f, 0x45
done:                   db "done", 0ah, 0
root_directory_start:   dd 0
root_directory_size:    dd 0
root_directory_sectors: dw 0
img_filename:           db 0,'b',0,'o',0,'o',0,'t',0,'l',0,'o',0,'a',0,'d',0,'e',0,'r',0,'.',0,'i',0,'m',0,'g'
desc_sector:            dd 0
file_start:             dd 0
file_size:              dd 0
file_sectors:           dw 0

times 510 - ($ - $$)  db 0  ; Zerofill up to 510 bytes
dw 0xaa55                   ; Boot Sector signature
