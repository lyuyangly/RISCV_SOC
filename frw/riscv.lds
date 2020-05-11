OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x0, LENGTH = 8K
}

STACK_SIZE  = 128;
HEAP_SIZE   = 128;

SECTIONS
{
    .text : ALIGN(4)
    {
        __start_addr = .;
        KEEP(*(.text.entry))
        . = ALIGN(4);
        *(.text*)
        . = ALIGN(4);
       __text_end = .;
    } > RAM

    .data :
    {
        __data_load = LOADADDR(.data);
        __rodata_start = .;
        *(.rodata*)
        . = ALIGN(4);
        __rodata_end = .;
        __data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM

    .sdata :
    {
        __sdata_load = LOADADDR(.sdata);
        __sdata_start = .;
        _gp = . + 0x100;
        *(.srodata*)
        *(.sdata*)
        __sdata_end = .;
    } > RAM

    .bss : ALIGN(4)
    {
        __bss_begin = .;
        *(.sbss*)
        *(.scommon)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM
    _end = .;

    .stack : ALIGN(4)
    {
        __stack_bottom = .;
        . += STACK_SIZE;
        __stack_top = .;
    } > RAM

    .heap : ALIGN(4)
    {
        __heap_begin = .;
        . += HEAP_SIZE;
        __heap_end = .;
    } > RAM
}

