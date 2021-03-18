ENTRY(bmain)

SECTIONS
{
    . = 0x7e00;

    /* .text BLOCK(4K) : ALIGN(4K)
	{
		*(.text)
	} */
 
	/* Read-only data. */
	/* .rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
	} */
 
	/* Read-write data (initialized) */
	/* .data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
	} */
 
	/* Read-write data (uninitialized) and stack */
	/* .bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
	} */

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
