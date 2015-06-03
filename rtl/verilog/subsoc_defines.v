//
// Currently, it's for Xilinx SPARTAN3 FPGA only
// Define FPGA manufacturer
//`define GENERIC_FPGA
//`define ALTERA_FPGA
`define XILINX_FPGA

// 
// Define FPGA Model (comment all out for ALTERA)
//
//`define SPARTAN2
`define SPARTAN3
//`define SPARTAN3E
//`define SPARTAN3A
//`define VIRTEX
//`define VIRTEX2
//`define VIRTEX4
//`define VIRTEX5


//
// Memory
//
`define MEMORY_ADR_WIDTH   12	//MEMORY_ADR_WIDTH IS NOT ALLOWED TO BE LESS THAN 12, memory is composed by blocks of address width 11
			        //Address width of memory -> select memory depth, 2 powers MEMORY_ADR_WIDTH defines the memory depth 
				//the memory data width is 32 bit, memory amount in Bytes = 4*memory depth

//
// TAP selection
//
//`define GENERIC_TAP
`define FPGA_TAP

//
// Connected modules
//
`define UART
`define SFIFO_IF    // SYNC_FIFO InterFace
`define SSIF        // Servo/Stepper InterFace

//
// Interrupts
//
`define APP_INT_RES1	1:0
`define APP_INT_UART	2
`define APP_INT_RES2	3
`define APP_INT_ETH	4
`define APP_INT_PS2	5
`define APP_INT_RES3	19:6

//
// Address map
//
`define APP_ADDR_PREFIX_W	4
`define APP_ADDR_SUFFIX_W       4
`define APP_ADDR_PREFIX_SRAM	`APP_ADDR_PREFIX_W'h0   // SRAM for program and data
`define APP_ADDR_PREFIX_ACCEL   `APP_ADDR_PREFIX_W'h9   // Accel Components Address Prefix: 0x9[F~0]
`define ACCEL_ADDR_SUFFIX_SFIFO	`APP_ADDR_SUFFIX_W'hd   // SFIFO, SYNC_FIFO, 0x9d..
`define ACCEL_ADDR_SUFFIX_SSIF	`APP_ADDR_SUFFIX_W'he   // SSIF, Servo/Stepper InterFace, 0x9e..
// `define APP_ADDR_SPI	`APP_ADDR_DEC_W'h97
// `define APP_ADDR_ETH	`APP_ADDR_DEC_W'h92
// `define APP_ADDR_UART	`APP_ADDR_DEC_W'h90
// `define APP_ADDR_PS2	`APP_ADDR_DEC_W'h94
// `define APP_ADDR_RES2	`APP_ADDR_DEC_W'h9f
