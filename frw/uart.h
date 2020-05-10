#ifndef UART_H
#define UART_H

#include <stdint.h>

extern void uart_init(uint32_t);
extern void uart_tx_byte(uint8_t);
extern uint8_t uart_rx_byte(void);
extern void uart_puts(const char *);

#endif
