//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uusb_top.v                                                  ////
////                                                              ////
////                                                              ////
////  This file is part of the "UUSB 16550 compatible" project    ////
////  http://www.opencores.org/cores/uusb16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uusb16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UUSB core top level.                                        ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Note that transmitter and receiver instances are inside     ////
////  the uusb_regs.v file.                                       ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing so far.                                             ////
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
// Revision 1.18  2002/07/22 23:02:23  gorban
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
// Revision 1.17  2001/12/19 08:40:03  mohor
// Warnings fixed (unused signals removed).
//
// Revision 1.16  2001/12/06 14:51:04  gorban
// Bug in LSR[0] is fixed.
// All WISHBONE signals are now sampled, so another wait-state is introduced on all transfers.
//
// Revision 1.15  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.14  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.13  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.12  2001/08/25 15:46:19  gorban
// Modified port names again
//
// Revision 1.11  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.10  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uusb_defines.v"

module uusb_top	(
	wb_clk_i, 
	
	// Wishbone signals
        wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i,
        wb_cyc_i, wb_ack_o, wb_sel_i, // int_o, // interrupt request

	// UUSB	signals
	// serial input/output
	uusb_dat_o, uusb_dat_i
	);

parameter 			uusb_data_width = `UUSB_DATA_WIDTH;
parameter 		        uusb_addr_width = `UUSB_ADDR_WIDTH;

input 				wb_clk_i;

// WISHBONE interface
input 				wb_rst_i;
input [uusb_addr_width-1:0]     wb_adr_i;
input [uusb_data_width-1:0] 	wb_dat_i;
output reg [uusb_data_width-1:0] 	wb_dat_o;
input 				wb_we_i;
input 				wb_stb_i;
input 				wb_cyc_i;
input [3:0]			wb_sel_i;
output 				wb_ack_o;
// output 				int_o;

// UUSB	signals
output reg [7:0]                uusb_dat_o;
input 	[7:0]			uusb_dat_i;

//
// MODULE INSTANCES
//

// assign uusb_dat_o = wb_dat_i[7:0];
// assign wb_dat_o[7:0] = uusb_dat_i;

always @ (posedge wb_clk_i)
  if (wb_rst_i)
    uusb_dat_o <= 0;
  else 
    uusb_dat_o <= wb_dat_i[7:0];

always @ (posedge wb_clk_i)
  if (wb_rst_i)
    wb_dat_o[7:0] <= 0;
  else 
    wb_dat_o[7:0] <= uusb_dat_i;

initial
begin
    $display("(%m) UUSB INFO: Data bus width is 32.\n");
end

endmodule
