//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xess Traffic Cop                                            ////
////                                                              ////
////  This file is part of the OR1K test application              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  This block connectes the RISC and peripheral controller     ////
////  cores together.                                             ////
////                                                              ////
////  To Do:                                                      ////
////   - nothing really                                           ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 OpenCores                                 ////
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
// $Log: tc_top.v,v $
// Revision 1.4  2004/04/05 08:44:34  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2  2002/03/29 20:57:30  lampret
// Removed unused ports wb_clki and wb_rst_i
//
// Revision 1.1.1.1  2002/03/21 16:55:44  lampret
// First import of the "new" XESS XSV environment.
//
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "tc_defines.v"

//
// Traffic Cop Top
//
module subsoc_tc_top (
	wb_clk_i,
	wb_rst_i,

	i4_wb_cyc_i,
	i4_wb_stb_i,
	i4_wb_adr_i,
	i4_wb_sel_i,
	i4_wb_we_i,
	i4_wb_dat_i,
	i4_wb_dat_o,
	i4_wb_ack_o,

	i5_wb_cyc_i,
	i5_wb_stb_i,
	i5_wb_adr_i,
	i5_wb_sel_i,
	i5_wb_we_i,
	i5_wb_dat_i,
	i5_wb_dat_o,
	i5_wb_ack_o,

	t0_wb_cyc_o,
	t0_wb_stb_o,
	t0_wb_adr_o,
	t0_wb_sel_o,
	t0_wb_we_o,
	t0_wb_dat_o,
	t0_wb_dat_i,
	t0_wb_ack_i,
	
        t1_wb_cyc_o,
	t1_wb_stb_o,
	t1_wb_adr_o,
	t1_wb_sel_o,
	t1_wb_we_o,
	t1_wb_dat_o,
	t1_wb_dat_i,
	t1_wb_ack_i,

	t2_wb_cyc_o,
	t2_wb_stb_o,
	t2_wb_adr_o,
	t2_wb_sel_o,
	t2_wb_we_o,
	t2_wb_dat_o,
	t2_wb_dat_i,
	t2_wb_ack_i
);

//
// Parameters
//
parameter               addr_prefix_w = 0;
parameter               addr_suffix_w = 0;
parameter    	        t0_addr_prefix = 0;
parameter    	        accel_addr_prefix = 0;
parameter    	        t1_addr_suffix = 0;
parameter    	        t2_addr_suffix = 0;

//
// I/O Ports
//
input			wb_clk_i;
input			wb_rst_i;

//
// WB slave i/f connecting initiator 4
//
input			i4_wb_cyc_i;
input			i4_wb_stb_i;
input	[`TC_AW-1:0]	i4_wb_adr_i;
input	[`TC_BSW-1:0]	i4_wb_sel_i;
input			i4_wb_we_i;
input	[`TC_DW-1:0]	i4_wb_dat_i;
output	[`TC_DW-1:0]	i4_wb_dat_o;
output			i4_wb_ack_o;

//
// WB slave i/f connecting initiator 5
//
input			i5_wb_cyc_i;
input			i5_wb_stb_i;
input	[`TC_AW-1:0]	i5_wb_adr_i;
input	[`TC_BSW-1:0]	i5_wb_sel_i;
input			i5_wb_we_i;
input	[`TC_DW-1:0]	i5_wb_dat_i;
output	[`TC_DW-1:0]	i5_wb_dat_o;
output			i5_wb_ack_o;

//
// WB master i/f connecting target 0
//
output			t0_wb_cyc_o;
output			t0_wb_stb_o;
output	[`TC_AW-1:0]	t0_wb_adr_o;
output	[`TC_BSW-1:0]	t0_wb_sel_o;
output			t0_wb_we_o;
output	[`TC_DW-1:0]	t0_wb_dat_o;
input	[`TC_DW-1:0]	t0_wb_dat_i;
input			t0_wb_ack_i;

//
// WB master i/f connecting target 1
//
output			t1_wb_cyc_o;
output			t1_wb_stb_o;
output	[`TC_AW-1:0]	t1_wb_adr_o;
output	[`TC_BSW-1:0]	t1_wb_sel_o;
output			t1_wb_we_o;
output	[`TC_DW-1:0]	t1_wb_dat_o;
input	[`TC_DW-1:0]	t1_wb_dat_i;
input			t1_wb_ack_i;

//
// WB master i/f connecting target 2
//
output			t2_wb_cyc_o;
output			t2_wb_stb_o;
output	[`TC_AW-1:0]	t2_wb_adr_o;
output	[`TC_BSW-1:0]	t2_wb_sel_o;
output			t2_wb_we_o;
output	[`TC_DW-1:0]	t2_wb_dat_o;
input	[`TC_DW-1:0]	t2_wb_dat_i;
input			t2_wb_ack_i;

//
// Internal wires & registers
//

//
// Outputs for initiators from both mi_to_st blocks
//
wire	[`TC_DW-1:0]	xi4_wb_dat_o;
wire			xi4_wb_ack_o;
wire	[`TC_DW-1:0]	yi4_wb_dat_o;
wire			yi4_wb_ack_o;

//
// Outputs for initiators are ORed from both mi_to_st blocks
//
assign i4_wb_dat_o = xi4_wb_dat_o | yi4_wb_dat_o;
assign i4_wb_ack_o = xi4_wb_ack_o | yi4_wb_ack_o;

//
// From initiators to target 0 (SRAM)
//
sram_mi_to_st 
        #(
        .addr_prefix_w      (addr_prefix_w), 
        .t0_addr_prefix     (t0_addr_prefix)
        ) 
        t0_ch
        (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),

	.i4_wb_cyc_i(i4_wb_cyc_i),  // rdm -- RISC DATA MASTER
	.i4_wb_stb_i(i4_wb_stb_i),
	.i4_wb_adr_i(i4_wb_adr_i),
	.i4_wb_sel_i(i4_wb_sel_i),
	.i4_wb_we_i (i4_wb_we_i),
	.i4_wb_dat_i(i4_wb_dat_i),
	.i4_wb_dat_o(xi4_wb_dat_o),
	.i4_wb_ack_o(xi4_wb_ack_o),

	.i5_wb_cyc_i(i5_wb_cyc_i),  // rim -- RISC INSTRUCTION MASTER
	.i5_wb_stb_i(i5_wb_stb_i),
	.i5_wb_adr_i(i5_wb_adr_i),
	.i5_wb_sel_i(i5_wb_sel_i),
	.i5_wb_we_i (i5_wb_we_i),
	.i5_wb_dat_i(i5_wb_dat_i),
	.i5_wb_dat_o(i5_wb_dat_o),
	.i5_wb_ack_o(i5_wb_ack_o),

	.t0_wb_cyc_o(t0_wb_cyc_o),  // SRAM -- dual port memory
	.t0_wb_stb_o(t0_wb_stb_o),
	.t0_wb_adr_o(t0_wb_adr_o),
	.t0_wb_sel_o(t0_wb_sel_o),
	.t0_wb_we_o (t0_wb_we_o),
	.t0_wb_dat_o(t0_wb_dat_o),
	.t0_wb_dat_i(t0_wb_dat_i),
	.t0_wb_ack_i(t0_wb_ack_i)
);

//
// From rdm (RISC DATA MASTER) to targets 1 or 2 (SFIFO/SSIF)
//
si_to_2t 
#(
    .addr_prefix_w      (addr_prefix_w),
    .addr_suffix_w      (addr_suffix_w),
    .addr_prefix        (accel_addr_prefix),
    .t0_addr_suffix     (t1_addr_suffix),
    .t1_addr_suffix     (t2_addr_suffix)
)
si_to_accels 
(
    .i0_wb_cyc_i(i4_wb_cyc_i),
    .i0_wb_stb_i(i4_wb_stb_i),
    .i0_wb_adr_i(i4_wb_adr_i),
    .i0_wb_sel_i(i4_wb_sel_i),
    .i0_wb_we_i (i4_wb_we_i),
    .i0_wb_dat_i(i4_wb_dat_i),
    .i0_wb_dat_o(yi4_wb_dat_o),
    .i0_wb_ack_o(yi4_wb_ack_o),

    .t0_wb_cyc_o(t1_wb_cyc_o),
    .t0_wb_stb_o(t1_wb_stb_o),
    .t0_wb_adr_o(t1_wb_adr_o),
    .t0_wb_sel_o(t1_wb_sel_o),
    .t0_wb_we_o (t1_wb_we_o),
    .t0_wb_dat_o(t1_wb_dat_o),
    .t0_wb_dat_i(t1_wb_dat_i),
    .t0_wb_ack_i(t1_wb_ack_i),

    .t1_wb_cyc_o(t2_wb_cyc_o),
    .t1_wb_stb_o(t2_wb_stb_o),
    .t1_wb_adr_o(t2_wb_adr_o),
    .t1_wb_sel_o(t2_wb_sel_o),
    .t1_wb_we_o (t2_wb_we_o),
    .t1_wb_dat_o(t2_wb_dat_o),
    .t1_wb_dat_i(t2_wb_dat_i),
    .t1_wb_ack_i(t2_wb_ack_i)
);

endmodule

