/* Test basic c functionality.  */

#define DEBUG 1 
#define DBGFINE 0

#include "../support/subsoc.h"

#include <string.h>
#include <stdint.h>

#define NOP_REPORT      0x0002      /* Simple report */

/* print long */
void report(unsigned long value)
{
  asm("l.addi\tr3,%0,0": :"r" (value));
  asm("l.nop %0": :"K" (NOP_REPORT));
}

int main()
{	
	signed long result1 = 0;
	signed long result2 = 0;
	signed long result3 = 0;

        uint32_t bp_tick;
        
        while (!sfifo_bp_tick()) {};


#if 0
        {
          /* test malloc() and free() */
          unsigned char *buf;
          buf = malloc (2048);
          free (buf);
        }
#endif // malloc()
        
// #if DEBUG
// 	printf("Start...\n");
// #endif
// 	result1 = test_cond(1);
// 	result2 = test_cond(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_cond:   0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 
// 	result1 = test_loops(1);
// 	result2 = test_loops(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_loops:  0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 
// 	result1 = test_arith(1);
// 	result2 = test_arith(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_arith:  0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 
// 	result1 = test_bitop(1);
// 	result2 = test_bitop(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_bitop:  0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 
// 	result1 = test_types(1);
// 	result2 = test_types(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_types:  0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 	result1 = test_array(1);
// 	result2 = test_array(-1);
// 	result3 -= result1 + result2;
// 	report(result2);
// #if DEBUG
// 	printf("After test_array:  0x%.8lx  0x%.8lx\n", result1, result2);
// #endif
// 
// 	printf("RESULT: %.8lx\n", result3-0x6cdd479d);
//         report(result3-0x6cdd401e);
	// or32_exit(result3-0x6cdd401e);
     return 0;
}
