include ../support/Makefile.inc

cases = sfifo

# common = ../support/except.o ../support/libsupport.a 
common = ../support/libsubsoc.a 

all: $(cases)

sim: $(cases)
	or32-elf-sim -f or1ksim-subsoc.cfg $?.or32

# sfifo-nocache-O0: sfifo-O0.o ../support/reset-nocache.o $(common)
sfifo: sfifo.o $(common)
	# $(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -T ../support/orp.ld $? -o $@.or32 $(GCC_LIB_OPTS) 
	# $(OR32_TOOL_PREFIX)-gcc --verbose $(GCC_OPT) $? -o $@.or32 -Wl,-u,free $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-gcc --verbose $(GCC_OPT) $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

%.o: %.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $? -c -o $@

