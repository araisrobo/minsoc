//////////////////////////////////////////////////////////////////////
////                                                              ////
//// 	     Wishbone Single-Port Synchronous RAM 		  ////
////	      	    	Memory Model 		                  ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/minsoc/  		  ////
////                                                              ////
////  Description                                                 ////
////  This Wishbone controller connects to the wrapper of         ////
////  the single-port synchronous memory interface.               ////
////  Besides universal memory due to onchip_ram it provides a    ////
////  generic way to set the depth of the memory.                 ////
////                                                              ////
////  To Do:                                                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Raul Fajardo, rfajardo@gmail.com	                  ////
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
// Revision 1.0 2009/08/18 15:15:00   fajardo
// Created interface and tested
//


module subsoc_onchip_ram_top ( 
  wb_clk_i, wb_rst_i, 
 
  wb_dat_i, wb_dat_o, wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, 
  wb_stb_i, wb_ack_o, /* wb_err_o,*/
  
  // OR32 PROG interface
  prog_addr_i,    // addr for OR32_PROG
  prog_data_i,    // data for OR32_PROG
  prog_en_i       // (1)write addr/data to OR32

); 
 
// 
// Parameters 
//
parameter   RAM_AW = 2;
parameter   RAM_DW = 32;
 
// 
// I/O Ports 
// 
input      wb_clk_i; 
input      wb_rst_i; 
 
// 
// WB slave i/f 
// 
input  [31:0]   wb_dat_i; 
output [31:0]   wb_dat_o; 
input  [31:0]   wb_adr_i; 
input  [3:0]    wb_sel_i; 
input           wb_we_i; 
input           wb_cyc_i; 
input           wb_stb_i; 
output reg      wb_ack_o; 
//bypass_wb_err: output reg      wb_err_o; 
  
// OR32 PROG interface
input  [RAM_AW+1:2]   prog_addr_i;      // addr for OR32_PROG
input  [RAM_DW-1:0]   prog_data_i;      // data for OR32_PROG
input                 prog_en_i;        // (1)write addr/data to OR32
 
// 
// Internal regs and wires 
// 
wire        we; 
wire [3:0]  be_i; 
wire [31:0] wb_dat_o; 
// reg    ack_we; 
// reg    ack_re; 
wire        wb_ack;
//bypass wb_err: wire        wb_err;

// 
// Aliases and simple assignments 
// 
// assign wb_ack_o = ack_re | ack_we; 
// assign wb_err_o = wb_cyc_i & wb_stb_i & (|wb_adr_i[23:RAM_AW+2]);  // If Access to > (8-bit leading prefix ignored) 
assign we = wb_cyc_i & wb_stb_i & wb_we_i & (|wb_sel_i[3:0]); 
assign be_i[0] = wb_cyc_i & wb_stb_i & wb_sel_i[0]; 
assign be_i[1] = wb_cyc_i & wb_stb_i & wb_sel_i[1]; 
assign be_i[2] = wb_cyc_i & wb_stb_i & wb_sel_i[2]; 
assign be_i[3] = wb_cyc_i & wb_stb_i & wb_sel_i[3]; 

//bypass_wb_err: // 
//bypass_wb_err: // WB error
//bypass_wb_err: // 
//bypass_wb_err: assign wb_err = wb_cyc_i & wb_stb_i & (|wb_adr_i[23:RAM_AW+2]);  // If Access to > (8-bit leading prefix ignored) 
//bypass_wb_err: always @ (posedge wb_clk_i) 
//bypass_wb_err: begin 
//bypass_wb_err: if (wb_rst_i) 
//bypass_wb_err:     wb_err_o <= 1'b0; 
//bypass_wb_err: else
//bypass_wb_err:     wb_err_o <= #1 (wb_err); 
//bypass_wb_err: end 
 
// 
// WB acknowledge 
// 
assign wb_ack = (wb_cyc_i & wb_stb_i /* & ~wb_err */ & ~wb_ack_o);
always @ (posedge wb_clk_i) 
begin 
if (wb_rst_i) 
    wb_ack_o <= 1'b0; 
else
    wb_ack_o <= #1 (wb_ack); 
end 

    subsoc_onchip_ram #(
        .AW(RAM_AW)
    ) block_ram_0 ( 
        .clk    (wb_clk_i), 
        .rst    (wb_rst_i),
        
        // Port A
        .addr   (wb_adr_i[RAM_AW+1:2]), 
        .di     (wb_dat_i[7:0]), 
        .doq    (wb_dat_o[7:0]), 
        .we     (we), 
        .oe     (1'b1),
        .ce     (be_i[0]),
        
        // Port B
        .addr_b (prog_addr_i), 
        .di_b   (prog_data_i[7:0]), 
        .doq_b  (), 
        .we_b   (prog_en_i), 
        .oe_b   (1'b1),
        .ce_b   (prog_en_i)
    ); 

    subsoc_onchip_ram #(
        .AW(RAM_AW)
    ) block_ram_1 ( 
        .clk    (wb_clk_i), 
        .rst    (wb_rst_i),
        
        // Port A
        .addr   (wb_adr_i[RAM_AW+1:2]), 
        .di     (wb_dat_i[15:8]), 
        .doq    (wb_dat_o[15:8]), 
        .we     (we), 
        .oe     (1'b1),
        .ce     (be_i[1]),
        
        // Port B
        .addr_b (prog_addr_i), 
        .di_b   (prog_data_i[15:8]), 
        .doq_b  (), 
        .we_b   (prog_en_i), 
        .oe_b   (1'b1),
        .ce_b   (prog_en_i)
    ); 

    subsoc_onchip_ram #(
        .AW(RAM_AW)
    ) block_ram_2 ( 
        .clk    (wb_clk_i), 
        .rst    (wb_rst_i),
        
        // Port A
        .addr   (wb_adr_i[RAM_AW+1:2]), 
        .di     (wb_dat_i[23:16]), 
        .doq    (wb_dat_o[23:16]), 
        .we     (we), 
        .oe     (1'b1),
        .ce     (be_i[2]),
        
        // Port B
        .addr_b (prog_addr_i), 
        .di_b   (prog_data_i[23:16]), 
        .doq_b  (), 
        .we_b   (prog_en_i), 
        .oe_b   (1'b1),
        .ce_b   (prog_en_i)
    ); 
    
    subsoc_onchip_ram #(
        .AW(RAM_AW)
    ) block_ram_3 ( 
        .clk    (wb_clk_i), 
        .rst    (wb_rst_i),
        
        // Port A
        .addr   (wb_adr_i[RAM_AW+1:2]), 
        .di     (wb_dat_i[31:24]), 
        .doq    (wb_dat_o[31:24]), 
        .we     (we), 
        .oe     (1'b1),
        .ce     (be_i[3]),
        
        // Port B
        .addr_b (prog_addr_i), 
        .di_b   (prog_data_i[31:24]), 
        .doq_b  (), 
        .we_b   (prog_en_i), 
        .oe_b   (1'b1),
        .ce_b   (prog_en_i)
    ); 

endmodule 

