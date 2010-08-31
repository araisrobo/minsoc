include ../support/Makefile.inc

cases = pid-nocache-O0 
	# pid-nocache-O2 

# common = ../support/except.o ../support/libsupport.a 

all: $(cases)

sim: $(cases)
	or32-elf-sim -f or1ksim-subsoc.cfg $?.or32

# cbasic-nocache-O0: cbasic-O0.o ../support/reset-nocache.o $(common)
pid-nocache-O0: pid-O0.o 
	# $(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -T ../support/orp.ld $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-gcc --verbose $(GCC_OPT) $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


pid-nocache-O2: pid-O2.o ../support/reset-nocache.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

pid-O0.o: pid.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O0 -c $?  -o $@

pid-O2.o: pid.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 $? -c -o $@

