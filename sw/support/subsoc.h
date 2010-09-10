#ifndef _SUBSOC_H_
#define _SUBSOC_H_


#define IN_CLK  	50000000    /*50 MHz*/

// /* device address mapping */
// #define SFIFO_BASE  	0xB0000000
// #define UART_BASE  	0xC0000000

/* Register access macros */
#define REG8(add) (*((volatile unsigned char *)(add)))
#define REG16(add) (*((volatile unsigned short *)(add)))
#define REG32(add) (*((volatile unsigned long *)(add)))

#endif
