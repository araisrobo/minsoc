include Makefile.inc

#minsoc: all: libsupport.a reset-nocache.o reset-ic.o reset-dc.o reset-icdc.o
#minsoc: 
#minsoc: libsupport.a: support.o int.o except.o uart.o vfnprintf.o
#minsoc: 	$(OR32_TOOL_PREFIX)-ar cru libsupport.a support.o except.o int.o uart.o vfnprintf.o
#minsoc: 	$(OR32_TOOL_PREFIX)-ranlib libsupport.a
#minsoc: 
#minsoc: support.o: support.c
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?
#minsoc: 
#minsoc: reset-nocache.o: reset.S
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=0 -DDC=0 -o $@ $?
#minsoc: 
#minsoc: reset-dc.o: reset.S
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=0 -DDC=1 -o $@ $?
#minsoc: 
#minsoc: reset-ic.o: reset.S
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=1 -DDC=0 -o $@ $?
#minsoc: 
#minsoc: reset-icdc.o: reset.S
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -DIC=1 -DDC=1 -o $@ $?
#minsoc: 
#minsoc: except.o: except.S
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?
#minsoc: 
#minsoc: uart.o: uart.c
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?
#minsoc: 
#minsoc: #snprintf.o: snprintf.c
#minsoc: #	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -o $@ $?
#minsoc: 
#minsoc: vfnprintf.o: vfnprintf.c
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?
#minsoc: 
#minsoc: int.o: int.c
#minsoc: 	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?


# for subsoc:
all: libsubsoc.a

libsubsoc.a: sfifo.o
	$(OR32_TOOL_PREFIX)-ar cru libsubsoc.a sfifo.o
	$(OR32_TOOL_PREFIX)-ranlib libsubsoc.a

# Makefile rules:
# http://www.cyut.edu.tw/~dywang/linuxProgram/node36.html
%.o: %.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -c -o $@ $?
