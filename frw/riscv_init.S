# Initialize ASM For RISC-V

.section .text.entry
.option norvc
.global _start

.macro push_reg
    addi sp, sp, -32*4
    sw x1, 0 * 4(sp)
    sw x2, 1 * 4(sp)
    sw x3, 2 * 4(sp)
    sw x4, 3 * 4(sp)
    sw x5, 4 * 4(sp)
    sw x6, 5 * 4(sp)
    sw x7, 6 * 4(sp)
    sw x8, 7 * 4(sp)
    sw x9, 8 * 4(sp)
    sw x10, 9 * 4(sp)
    sw x11, 10 * 4(sp)
    sw x12, 11 * 4(sp)
    sw x13, 12 * 4(sp)
    sw x14, 13 * 4(sp)
    sw x15, 14 * 4(sp)
    sw x16, 15 * 4(sp)
    sw x17, 16 * 4(sp)
    sw x18, 17 * 4(sp)
    sw x19, 18 * 4(sp)
    sw x20, 19 * 4(sp)
    sw x21, 20 * 4(sp)
    sw x22, 21 * 4(sp)
    sw x23, 22 * 4(sp)
    sw x24, 23 * 4(sp)
    sw x25, 24 * 4(sp)
    sw x26, 25 * 4(sp)
    sw x27, 26 * 4(sp)
    sw x28, 27 * 4(sp)
    sw x29, 28 * 4(sp)
    sw x30, 29 * 4(sp)
    sw x31, 30 * 4(sp)
    csrr t0, mepc
    sw t0, 31 * 4(sp)
.endm

.macro pop_reg
    lw t0, 31 * 4(sp)
    csrw mepc, t0
    lw x1, 0 * 4(sp)
    lw x2, 1 * 4(sp)
    lw x3, 2 * 4(sp)
    lw x4, 3 * 4(sp)
    lw x5, 4 * 4(sp)
    lw x6, 5 * 4(sp)
    lw x7, 6 * 4(sp)
    lw x8, 7 * 4(sp)
    lw x9, 8 * 4(sp)
    lw x10, 9 * 4(sp)
    lw x11, 10 * 4(sp)
    lw x12, 11 * 4(sp)
    lw x13, 12 * 4(sp)
    lw x14, 13 * 4(sp)
    lw x15, 14 * 4(sp)
    lw x16, 15 * 4(sp)
    lw x17, 16 * 4(sp)
    lw x18, 17 * 4(sp)
    lw x19, 18 * 4(sp)
    lw x20, 19 * 4(sp)
    lw x21, 20 * 4(sp)
    lw x22, 21 * 4(sp)
    lw x23, 22 * 4(sp)
    lw x24, 23 * 4(sp)
    lw x25, 24 * 4(sp)
    lw x26, 25 * 4(sp)
    lw x27, 26 * 4(sp)
    lw x28, 27 * 4(sp)
    lw x29, 28 * 4(sp)
    lw x30, 29 * 4(sp)
    lw x31, 30 * 4(sp)
    addi sp, sp, 32*4
.endm

.option norvc

.org 0x200
_start:
    j handle_reset

trap_vector:
    j RVDefaultHandler
    j RVDefaultHandler   // 1
    j RVDefaultHandler   // 2
    j RVDefaultHandler   // 3
    j RVDefaultHandler   // 4
    j RVDefaultHandler   // 5
    j RVDefaultHandler   // 6
    j RVDefaultHandler   // 7
    j RVDefaultHandler   // 8
    j RVDefaultHandler   // 9
    j RVDefaultHandler   // 10
    j RVDefaultHandler   // 11
    j RVDefaultHandler   // 12
    j RVDefaultHandler   // 13
    j RVDefaultHandler   // 14
    j RVDefaultHandler   // 15
    j RVDefaultHandler   // 16
    j RVDefaultHandler   // 17
    j RVDefaultHandler   // 18
    j RVDefaultHandler   // 19
    j RVDefaultHandler   // 20
    j RVDefaultHandler   // 21
    j RVDefaultHandler   // 22
    j RVDefaultHandler   // 23
    j RVDefaultHandler   // 24
    j RVDefaultHandler   // 25

RVDefaultHandler:
    j RVDefaultHandler

.section .text
.option norvc

handle_reset:
    la t0, trap_vector
    addi t0, t0, 1
    csrw mtvec, t0
    csrwi mstatus, 0
    csrwi mie, 0
    la gp, _gp
    la sp, __stack_top

# clear bss section
clear_bss:
    la t0, __bss_begin
    la t1, __bss_end
    li t2, 0x00000000

clear_bss_loop:
    sw      t2, (t0)
    addi    t0, t0, 4
    blt     t0, t1, clear_bss_loop

##load data to RAM
#    la t0, __load_start
#    la t1, __data_start
#    la t2, __data_end
#    beq t1, t2, jump_to_main
#
#load_data_loop:
#    lw t3, (t0)
#    sw t3, (t1)
#    addi t0,t0,4
#    addi t1,t1,4
#    blt t1, t2, load_data_loop

jump_to_main:
    j main

