ENTRY(_begin)

SECTIONS
{
    . = 0x7C00;
    .text : {
        /* Place the code in hw.o before all other code */
        /* stage0.o(.text); */
        *(.text);
    }

    /* Place the data after the code */
    .data : SUBALIGN(2) {
        *(.data);
        *(.rodata*);
    }

    /* Place the boot signature at LMA/VMA 0x7DFE */
    /* .sig 0x7DFE : {
        SHORT(0xaa55);
    } */

     /* Place the uninitialised data in the area after our bootloader
     * The BIOS only reads the 512 bytes before this into memory */
    /* .bss : SUBALIGN(4) {
        __bss_start = .;
        *(COMMON);
        *(.bss)
        . = ALIGN(4);
        __bss_end = .;
    }
    __bss_sizeb = SIZEOF(.bss); */

    /* Remove sections that won't be relevant to us */
    /* /DISCARD/ : {
        *(.eh_frame);
        *(.comment);
    } */
}
