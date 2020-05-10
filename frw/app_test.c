#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "board.h"
#include "uart.h"

extern int xmodemReceive(unsigned char*, int);

typedef void (*p_func)(void);

#define LOAD_BASE 0x1000

void delay(unsigned int t)
{
	volatile uint32_t i, j;
	for(i = 0; i < t; i++)
		for(j = 0; j < 1024; j++);
}

int main(void)
{
    int st = -1;
    volatile uint32_t num;
    p_func boot_main=(p_func)(LOAD_BASE);

    // GPIO
	*((volatile uint32_t *)(GPIO_BASE)) = 0x5;
	*((volatile uint32_t *)(GPIO_BASE)) = 0xa;

    // UART 115200 8N1
    uart_init(6944);
    uart_puts("RISC-V Boot ...\r\n");
    uart_puts("Receive Program by Xmodem in 10s ...\r\n");
    delay(10000);

	*((volatile uint32_t *)(GPIO_BASE)) = 0x5;

    st = xmodemReceive((unsigned char *)(LOAD_BASE), 8192);

	*((volatile uint32_t *)(GPIO_BASE)) = 0xa;

    if(st < 0) {
        uart_puts("Xmodem Receive FAIL.\r\n");
    	while(1) {
    		*((volatile uint32_t *)(LOAD_BASE + 0x10)) = 0xaa;
    		num = *((volatile uint32_t *)(LOAD_BASE + 0x10));
    		*((volatile uint32_t *)(GPIO_BASE)) = num;
    		delay(1000);
    		*((volatile uint32_t *)(LOAD_BASE + 0x10)) = 0x55;
    		num = *((volatile uint32_t *)(LOAD_BASE + 0x10));
            *((volatile uint32_t *)(GPIO_BASE)) = num;
      		delay(1000);
    	}
    } else {
        uart_puts("Start from LOAD_BASE ...\r\n");
        boot_main();
    }

	return 0;
}

