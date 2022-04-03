OUTPUT_ARCH( "riscv" )
ENTRY(_start)

STACK_SIZE = DEFINED(__stack_size__) ? __stack_size__ : 0x10000;

MEMORY {
    STACK (rw) : ORIGIN = 0x00000000, LENGTH = 64K
    ROM (rx)  : ORIGIN = 0x00010000, LENGTH = 256K
    RAM (rwx) : ORIGIN = 0x00080000, LENGTH = 256K
}

/* TODO: use STACK_SIZE to setup STACK(LENGTH) */
/* TODO: check topology with the STACK_SIZE and ROM(LENGTH) */

SECTIONS
{

   .stack (NOLOAD): {   /* Stack section */
      . = ALIGN(4);
      _sstack = .;      /* Start of stack section */
      . = . + STACK_SIZE;
      . = ALIGN(4);
      _estack = .;      /* End of stack section */
   } >STACK

    .text.init : {      /* C runtime startup code (crt0.S) */
        . = ALIGN(4);
        _stextinit = .; /* Start of text.init section */
        *(.text.init)
        . = ALIGN(4);
        _etextinit = .; /* End of text.init section */
    } >ROM

    _main_start = .;    /* define a global symbol where the program will be booted */

    .text : {           /* Program code */
        . = ALIGN(4);
        _stext = .;     /* Start of text section */
        *(.text)        /* C main() code */
        . = ALIGN(4);
        _etext = .;     /* End of text section */
    } >ROM

    .data : {           /* Initialized global and static variables */
        . = ALIGN(4);
        _sdata = .;     /* Start of data section */
        *(.data)
        . = ALIGN(4);
        _edata = .;     /* End of data section */
    } >RAM

    .bss : {            /* Uninitialized global and static variables */
        . = ALIGN(4);
        _sbss = .;      /* Start of bss section */
        *(.bss)
        . = ALIGN(4);
        _ebss = .;      /* End of bss section */
    } >RAM

}
