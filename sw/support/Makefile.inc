# File to be included in all makefiles

OR32_TOOL_PREFIX=or32-elf

# GCC_LIB_OPTS= -lgcc -liberty

# GCC_OPT=-mhard-mul -g 
# GCC_OPT=-msoft-mul -g 
#for newlib: 
GCC_OPT=-msoft-mul -mor32-newlib

ifdef UART_PRINTF
GCC_OPT += -DUART_PRINTF
endif

FLASH_MEM_HEX_FILE_SUFFIX=-twobyte-sizefirst
SRAM_MEM_HEX_FILE_SUFFIX=-fourbyte


# Global clean rule
clean:
	@echo "Cleaning `pwd`"
	@rm -f *.o *.or32 *.log *.bin *.srec *.hex *.log stdout.txt *.vmem *.asm *.a stdout.txt
