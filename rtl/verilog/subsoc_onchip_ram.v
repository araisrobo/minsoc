//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Single-Port Synchronous RAM                         ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/minsoc/ 		  ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common single-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  single-port synchronous RAM.                                ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Single-Port Sync RAM                              ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage Single-Port Sync RAM                               ////
////  - Virtual Silicon Single-Port Sync RAM                      ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Xilinx Virtex RAMB16                                      ////
////  - Xilinx Virtex RAMB4                                       ////
////  - Altera LPM                                                ////
////                                                              ////
////  To Do:                                                      ////
////   - fix avant! two-port ram                                  ////
////   - add additional RAMs                                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Raul Fajardo, rfajardo@gmail.com	                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
//// from http://www.gnu.org/licenses/lgpl.html                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// Revision History
//
//
// Revision 2.1 2009/08/23 16:41:00   fajardo
// Sensitivity of addr_reg and memory write changed back to posedge clk for GENERIC_MEMORY
// This actually models appropriately the behavior of the FPGA internal RAMs
//
// Revision 2.0 2009/09/10 11:30:00   fajardo
// Added tri-state buffering for altera output
// Sensitivity of addr_reg and memory write changed to negedge clk for GENERIC_MEMORY
//
// Revision 1.9 2009/08/18 15:15:00   fajardo
// Added tri-state buffering for xilinx and generic memory output
//
// $Log: not supported by cvs2svn $
// Revision 1.8  2004/06/08 18:15:32  lampret
// Changed behavior of the simulation generic models
//
// Revision 1.7  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.3.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.3  2003/04/07 01:19:07  lampret
// Added Altera LPM RAMs. Changed generic RAM output when OE inactive.
//
// Revision 1.2  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/11/02 18:57:14  lampret
// Modified virtual silicon instantiations.
//
// Revision 1.7  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

module subsoc_onchip_ram #(
  //
  // Default address and data buses width
  //
  parameter AW = 11,
  parameter DW = 8
) (
  //
  // Generic synchronous dual-port RAM interface
  //
  input			  clk,	    // Clock
  input			  rst,	    // Reset
  
  // Port A
  input			  ce,	    // Chip enable input
  input			  we,	    // Write enable input
  input			  oe,	    // Output enable input
  input       [AW-1:0]	  addr,	    // address bus inputs
  input	      [DW-1:0]	  di,	    // input data bus
  output  reg [DW-1:0]	  doq,	    // output data bus
  
  // Port B
  input			  ce_b,	    // Chip enable input
  input			  we_b,	    // Write enable input
  input			  oe_b,	    // Output enable input
  input       [AW-1:0]	  addr_b,   // address bus inputs
  input	      [DW-1:0]	  di_b,	    // input data bus
  output  reg [DW-1:0]	  doq_b     // output data bus
);


//
// Internal wires and registers
//

//
// Generic single-port synchronous RAM model
//

//
// Generic RAM's registers and wires
//
reg	[DW-1:0]	mem [(1<<AW)-1:0];	// RAM content

// //  The following code is only necessary if you wish to initialize the RAM 
// //  contents via an external file (use $readmemb for binary data)
// initial
//    $readmemh("<data_file_name>", <rom_name>, <begin_address>, <end_address>);

always @(posedge clk)
   if (ce) begin
      if (we)
         mem[addr] <= di;
      doq <= mem[addr];
   end

always @(posedge clk)
   if (ce_b) begin
      if (we_b)
         mem[addr_b] <= di_b;
      doq_b <= mem[addr_b];
   end

endmodule
