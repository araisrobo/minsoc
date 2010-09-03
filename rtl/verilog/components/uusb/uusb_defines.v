//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uusb_defines.v                                              ////
////                                                              ////
////                                                              ////
////  This file is part of the "UUSB 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  Defines of the Core                                         ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None                                                        ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.13  2003/06/11 16:37:47  gorban
// This fixes errors in some cases when data is being read and put to the FIFO at the same time. Patch is submitted by Scott Furman. Update is very recommended.
//
// Revision 1.12  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UUSB_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.10  2001/12/11 08:55:40  mohor
// Scratch register define added.
//

`define UUSB_ADDR_WIDTH 5
`define UUSB_DATA_WIDTH 32

// Register addresses
`define UUSB_REG_RB	`UUSB_ADDR_WIDTH'd0	// receiver buffer
`define UUSB_REG_TR     `UUSB_ADDR_WIDTH'd0	// transmitter
`define UUSB_REG_FC     `UUSB_ADDR_WIDTH'd2	// FIFO control

// Line Control register bits
`define UUSB_LC_BITS	1:0	// bits in character
`define UUSB_LC_SB	2	// stop bits
`define UUSB_LC_PE	3	// parity enable
`define UUSB_LC_EP	4	// even parity
`define UUSB_LC_SP	5	// stick parity
`define UUSB_LC_BC	6	// Break control
`define UUSB_LC_DL	7	// Divisor Latch access bit

// FIFO parameter defines

`define VERBOSE_WB  0           // All activity on the WISHBONE is recorded
`define VERBOSE_LINE_STATUS 0   // Details about the lsr (line status register)
`define FAST_TEST   1           // 64/1024 packets are sent
