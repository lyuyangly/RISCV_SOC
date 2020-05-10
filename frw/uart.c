#include <stdint.h>
#include <stdlib.h>
#include "board.h"

// Programmer's Model
// 0x00 R     RXD[7:0]    Received Data
//      W     TXD[7:0]    Transmit data
// 0x04 RW    STAT[3:0]
//              [3] RX buffer overrun (write 1 to clear)
//              [2] TX buffer overrun (write 1 to clear)
//              [1] RX buffer full (Read only)
//              [0] TX buffer full (Read only)
// 0x08 RW    CTRL[3:0]   TxIntEn, RxIntEn, TxEn, RxEn
//              [6] High speed test mode Enable
//              [5] RX overrun interrupt enable
//              [4] TX overrun interrupt enable
//              [3] RX Interrupt Enable
//              [2] TX Interrupt Enable
//              [1] RX Enable
//              [0] TX Enable
// 0x0C R/Wc  intr_status/INTCLEAR
//              [3] RX overrun interrupt
//              [2] TX overrun interrupt
//              [1] RX interrupt
//              [0] TX interrupt
// 0x10 RW    BAUDDIV[19:0] Baud divider
//            (minimum value is 16)
// 0x3E0 - 0x3FC  ID registers
//-------------------------------------

void uart_init(uint32_t baudrate)
{
    *((volatile uint32_t *)(UART_BASE + 0x08)) = 0x03;
    *((volatile uint32_t *)(UART_BASE + 0x10)) = baudrate;
    *((volatile uint32_t *)(UART_BASE + 0x04)) = 0x0a;
}

void uart_tx_byte(uint8_t ch)
{
    uint8_t tmp;

    do {
        tmp = *((volatile uint32_t *)(UART_BASE + 0x04));
    } while((tmp & 0x01) == 0x01);

    *((volatile uint32_t *)(UART_BASE)) = ch;
}

uint8_t uart_rx_byte(void)
{
    uint8_t tmp;

    do {
        tmp = *((volatile uint32_t *)(UART_BASE + 0x04));
    } while((tmp & 0x08) == 0x08);

    return (*((volatile uint32_t *)(UART_BASE)));
}

void uart_puts(const char *str)
{
    while(*str) {
        uart_tx_byte(*str++);
    }
}

