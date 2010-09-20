#ifndef __subsoc_regs_h__
#define __subsoc_regs_h__

/**
 * refer to stdint.h:
 * The ISO C99 standard specifies that in C++ implementations these
 * macros should only be defined if explicitly requested.
 * the following checking is for C only
 **/
#if !defined __cplusplus
#if !defined(UINT8_MAX) || !defined(UINT16_MAX) || !defined(INT32_MAX)
#error "Must include <inttypes.h> or <stdint.h> before any customized header."
#endif
#endif

// SFIFO register space:
#define SFIFO_BASE        0x9D000000
// offset to SFIFO registers
#define SFIFO_BP_TICK         0x0000  // base period tick
#define SFIFO_CTRL            0x0004  // SFIFO ctrl register
#define SFIFO_DI              0x0008  // SFIFO data input
// masks to SFIFO registers
#define SFIFO_EMPTY_MASK  0x00000001  // 0x0004.0: set to 1 if SFIFO is empty

#endif // __subsoc_regs_h__
