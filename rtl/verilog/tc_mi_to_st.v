// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "tc_defines.v"

//
// Multiple initiator to single target
//
module tc_mi_to_st (
	wb_clk_i,
	wb_rst_i,

	//obsolete: i0_wb_cyc_i,
	//obsolete: i0_wb_stb_i,
	//obsolete: i0_wb_adr_i,
	//obsolete: i0_wb_sel_i,
	//obsolete: i0_wb_we_i,
	//obsolete: i0_wb_dat_i,
	//obsolete: i0_wb_dat_o,
	//obsolete: i0_wb_ack_o,
	//obsolete: i0_wb_err_o,

	//obsolete: i1_wb_cyc_i,
	//obsolete: i1_wb_stb_i,
	//obsolete: i1_wb_adr_i,
	//obsolete: i1_wb_sel_i,
	//obsolete: i1_wb_we_i,
	//obsolete: i1_wb_dat_i,
	//obsolete: i1_wb_dat_o,
	//obsolete: i1_wb_ack_o,
	//obsolete: i1_wb_err_o,

	//obsolete: i2_wb_cyc_i,
	//obsolete: i2_wb_stb_i,
	//obsolete: i2_wb_adr_i,
	//obsolete: i2_wb_sel_i,
	//obsolete: i2_wb_we_i,
	//obsolete: i2_wb_dat_i,
	//obsolete: i2_wb_dat_o,
	//obsolete: i2_wb_ack_o,
	//obsolete: i2_wb_err_o,

	//obsolete: i3_wb_cyc_i,
	//obsolete: i3_wb_stb_i,
	//obsolete: i3_wb_adr_i,
	//obsolete: i3_wb_sel_i,
	//obsolete: i3_wb_we_i,
	//obsolete: i3_wb_dat_i,
	//obsolete: i3_wb_dat_o,
	//obsolete: i3_wb_ack_o,
	//obsolete: i3_wb_err_o,

	i4_wb_cyc_i,
	i4_wb_stb_i,
	i4_wb_adr_i,
	i4_wb_sel_i,
	i4_wb_we_i,
	i4_wb_dat_i,
	i4_wb_dat_o,
	i4_wb_ack_o,
	i4_wb_err_o,

	i5_wb_cyc_i,
	i5_wb_stb_i,
	i5_wb_adr_i,
	i5_wb_sel_i,
	i5_wb_we_i,
	i5_wb_dat_i,
	i5_wb_dat_o,
	i5_wb_ack_o,
	i5_wb_err_o,

	//obsolete: i6_wb_cyc_i,
	//obsolete: i6_wb_stb_i,
	//obsolete: i6_wb_adr_i,
	//obsolete: i6_wb_sel_i,
	//obsolete: i6_wb_we_i,
	//obsolete: i6_wb_dat_i,
	//obsolete: i6_wb_dat_o,
	//obsolete: i6_wb_ack_o,
	//obsolete: i6_wb_err_o,

	//obsolete: i7_wb_cyc_i,
	//obsolete: i7_wb_stb_i,
	//obsolete: i7_wb_adr_i,
	//obsolete: i7_wb_sel_i,
	//obsolete: i7_wb_we_i,
	//obsolete: i7_wb_dat_i,
	//obsolete: i7_wb_dat_o,
	//obsolete: i7_wb_ack_o,
	//obsolete: i7_wb_err_o,

	t0_wb_cyc_o,
	t0_wb_stb_o,
	t0_wb_adr_o,
	t0_wb_sel_o,
	t0_wb_we_o,
	t0_wb_dat_o,
	t0_wb_dat_i,
	t0_wb_ack_i,
	t0_wb_err_i

);

//
// Parameters
//
parameter		t0_addr_w = 2;
parameter		t0_addr = 2'b00;
parameter		multitarg = 1'b0;
parameter		t17_addr_w = 2;
parameter		t17_addr = 2'b00;

//
// I/O Ports
//
input			wb_clk_i;
input			wb_rst_i;

//obsolete: //
//obsolete: // WB slave i/f connecting initiator 0
//obsolete: //
//obsolete: input			i0_wb_cyc_i;
//obsolete: input			i0_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i0_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i0_wb_sel_i;
//obsolete: input			i0_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i0_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i0_wb_dat_o;
//obsolete: output			i0_wb_ack_o;
//obsolete: output			i0_wb_err_o;
//obsolete: 
//obsolete: //
//obsolete: // WB slave i/f connecting initiator 1
//obsolete: //
//obsolete: input			i1_wb_cyc_i;
//obsolete: input			i1_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i1_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i1_wb_sel_i;
//obsolete: input			i1_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i1_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i1_wb_dat_o;
//obsolete: output			i1_wb_ack_o;
//obsolete: output			i1_wb_err_o;
//obsolete: 
//obsolete: //
//obsolete: // WB slave i/f connecting initiator 2
//obsolete: //
//obsolete: input			i2_wb_cyc_i;
//obsolete: input			i2_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i2_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i2_wb_sel_i;
//obsolete: input			i2_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i2_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i2_wb_dat_o;
//obsolete: output			i2_wb_ack_o;
//obsolete: output			i2_wb_err_o;
//obsolete: 
//obsolete: //
//obsolete: // WB slave i/f connecting initiator 3
//obsolete: //
//obsolete: input			i3_wb_cyc_i;
//obsolete: input			i3_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i3_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i3_wb_sel_i;
//obsolete: input			i3_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i3_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i3_wb_dat_o;
//obsolete: output			i3_wb_ack_o;
//obsolete: output			i3_wb_err_o;

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
output			i4_wb_err_o;

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
output			i5_wb_err_o;

//obsolete: //
//obsolete: // WB slave i/f connecting initiator 6
//obsolete: //
//obsolete: input			i6_wb_cyc_i;
//obsolete: input			i6_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i6_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i6_wb_sel_i;
//obsolete: input			i6_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i6_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i6_wb_dat_o;
//obsolete: output			i6_wb_ack_o;
//obsolete: output			i6_wb_err_o;
//obsolete: 
//obsolete: //
//obsolete: // WB slave i/f connecting initiator 7
//obsolete: //
//obsolete: input			i7_wb_cyc_i;
//obsolete: input			i7_wb_stb_i;
//obsolete: input	[`TC_AW-1:0]	i7_wb_adr_i;
//obsolete: input	[`TC_BSW-1:0]	i7_wb_sel_i;
//obsolete: input			i7_wb_we_i;
//obsolete: input	[`TC_DW-1:0]	i7_wb_dat_i;
//obsolete: output	[`TC_DW-1:0]	i7_wb_dat_o;
//obsolete: output			i7_wb_ack_o;
//obsolete: output			i7_wb_err_o;

//
// WB master i/f connecting target
//
output			t0_wb_cyc_o;
output			t0_wb_stb_o;
output	[`TC_AW-1:0]	t0_wb_adr_o;
output	[`TC_BSW-1:0]	t0_wb_sel_o;
output			t0_wb_we_o;
output	[`TC_DW-1:0]	t0_wb_dat_o;
input	[`TC_DW-1:0]	t0_wb_dat_i;
input			t0_wb_ack_i;
input			t0_wb_err_i;

//
// Internal wires & registers
//
//obsolete: wire	[`TC_IIN_W-1:0]	i0_in, i1_in,
//obsolete: 			i2_in, i3_in,
//obsolete: 			i4_in, i5_in,
//obsolete: 			i6_in, i7_in;
//obsolete: wire	[`TC_TIN_W-1:0]	i0_out, i1_out,
//obsolete: 			i2_out, i3_out,
//obsolete: 			i4_out, i5_out,
//obsolete: 			i6_out, i7_out;
wire	[`TC_IIN_W-1:0]	i4_in, i5_in;
wire	[`TC_TIN_W-1:0]	i4_out, i5_out;
wire	[`TC_IIN_W-1:0]	t0_out;
wire	[`TC_TIN_W-1:0]	t0_in;
//obsolete: wire	[7:0]		req_i;
wire	[5:4]		req_i;
wire	[2:0]		req_won;
reg			req_cont;
reg	[2:0]		req_r;

//obsolete: //
//obsolete: // Group WB initiator 0 i/f inputs and outputs
//obsolete: //
//obsolete: assign i0_in = {i0_wb_cyc_i, i0_wb_stb_i, i0_wb_adr_i,
//obsolete: 		i0_wb_sel_i, i0_wb_we_i, i0_wb_dat_i};
//obsolete: assign {i0_wb_dat_o, i0_wb_ack_o, i0_wb_err_o} = i0_out;
//obsolete: 
//obsolete: //
//obsolete: // Group WB initiator 1 i/f inputs and outputs
//obsolete: //
//obsolete: assign i1_in = {i1_wb_cyc_i, i1_wb_stb_i, i1_wb_adr_i,
//obsolete: 		i1_wb_sel_i, i1_wb_we_i, i1_wb_dat_i};
//obsolete: assign {i1_wb_dat_o, i1_wb_ack_o, i1_wb_err_o} = i1_out;
//obsolete: 
//obsolete: //
//obsolete: // Group WB initiator 2 i/f inputs and outputs
//obsolete: //
//obsolete: assign i2_in = {i2_wb_cyc_i, i2_wb_stb_i, i2_wb_adr_i,
//obsolete: 		i2_wb_sel_i, i2_wb_we_i, i2_wb_dat_i};
//obsolete: assign {i2_wb_dat_o, i2_wb_ack_o, i2_wb_err_o} = i2_out;
//obsolete: 
//obsolete: //
//obsolete: // Group WB initiator 3 i/f inputs and outputs
//obsolete: //
//obsolete: assign i3_in = {i3_wb_cyc_i, i3_wb_stb_i, i3_wb_adr_i,
//obsolete: 		i3_wb_sel_i, i3_wb_we_i, i3_wb_dat_i};
//obsolete: assign {i3_wb_dat_o, i3_wb_ack_o, i3_wb_err_o} = i3_out;

//
// Group WB initiator 4 i/f inputs and outputs
//
assign i4_in = {i4_wb_cyc_i, i4_wb_stb_i, i4_wb_adr_i,
		i4_wb_sel_i, i4_wb_we_i, i4_wb_dat_i};
assign {i4_wb_dat_o, i4_wb_ack_o, i4_wb_err_o} = i4_out;

//
// Group WB initiator 5 i/f inputs and outputs
//
assign i5_in = {i5_wb_cyc_i, i5_wb_stb_i, i5_wb_adr_i,
		i5_wb_sel_i, i5_wb_we_i, i5_wb_dat_i};
assign {i5_wb_dat_o, i5_wb_ack_o, i5_wb_err_o} = i5_out;

//obsolete: //
//obsolete: // Group WB initiator 6 i/f inputs and outputs
//obsolete: //
//obsolete: assign i6_in = {i6_wb_cyc_i, i6_wb_stb_i, i6_wb_adr_i,
//obsolete: 		i6_wb_sel_i, i6_wb_we_i, i6_wb_dat_i};
//obsolete: assign {i6_wb_dat_o, i6_wb_ack_o, i6_wb_err_o} = i6_out;
//obsolete: 
//obsolete: //
//obsolete: // Group WB initiator 7 i/f inputs and outputs
//obsolete: //
//obsolete: assign i7_in = {i7_wb_cyc_i, i7_wb_stb_i, i7_wb_adr_i,
//obsolete: 		i7_wb_sel_i, i7_wb_we_i, i7_wb_dat_i};
//obsolete: assign {i7_wb_dat_o, i7_wb_ack_o, i7_wb_err_o} = i7_out;

//
// Group WB target 0 i/f inputs and outputs
//
assign {t0_wb_cyc_o, t0_wb_stb_o, t0_wb_adr_o,
		t0_wb_sel_o, t0_wb_we_o, t0_wb_dat_o} = t0_out;
assign t0_in = {t0_wb_dat_i, t0_wb_ack_i, t0_wb_err_i};

//
// Assign to WB initiator i/f outputs
//
// Either inputs from the target are assigned or zeros.
//
//obsolete: assign i0_out = (req_won == 3'd0) ? t0_in : {`TC_TIN_W{1'b0}};
//obsolete: assign i1_out = (req_won == 3'd1) ? t0_in : {`TC_TIN_W{1'b0}};
//obsolete: assign i2_out = (req_won == 3'd2) ? t0_in : {`TC_TIN_W{1'b0}};
//obsolete: assign i3_out = (req_won == 3'd3) ? t0_in : {`TC_TIN_W{1'b0}};
assign i4_out = (req_won == 3'd4) ? t0_in : {`TC_TIN_W{1'b0}};
assign i5_out = (req_won == 3'd5) ? t0_in : {`TC_TIN_W{1'b0}};
//obsolete: assign i6_out = (req_won == 3'd6) ? t0_in : {`TC_TIN_W{1'b0}};
//obsolete: assign i7_out = (req_won == 3'd7) ? t0_in : {`TC_TIN_W{1'b0}};

//
// Assign to WB target i/f outputs
//
// Assign inputs from initiator to target outputs according to
// which initiator has won. If there is no request for the target,
// assign zeros.
//
//obsolete: assign t0_out = (req_won == 3'd0) ? i0_in :
//obsolete: 		(req_won == 3'd1) ? i1_in :
//obsolete: 		(req_won == 3'd2) ? i2_in :
//obsolete: 		(req_won == 3'd3) ? i3_in :
//obsolete: 		(req_won == 3'd4) ? i4_in :
//obsolete: 		(req_won == 3'd5) ? i5_in :
//obsolete: 		(req_won == 3'd6) ? i6_in :
//obsolete: 		(req_won == 3'd7) ? i7_in : {`TC_IIN_W{1'b0}};
assign t0_out = (req_won == 3'd4) ? i4_in : 
            	(req_won == 3'd5) ? i5_in : {`TC_IIN_W{1'b0}};

//
// Determine if an initiator has address of the target.
//
//obsolete: assign req_i[0] = i0_wb_cyc_i &
//obsolete: 	((i0_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[1] = i1_wb_cyc_i &
//obsolete: 	((i1_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i1_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[2] = i2_wb_cyc_i &
//obsolete: 	((i2_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i2_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[3] = i3_wb_cyc_i &
//obsolete: 	((i3_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i3_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[4] = i4_wb_cyc_i &
//obsolete: 	((i4_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i4_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[5] = i5_wb_cyc_i &
//obsolete: 	((i5_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i5_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[6] = i6_wb_cyc_i &
//obsolete: 	((i6_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i6_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
//obsolete: assign req_i[7] = i7_wb_cyc_i &
//obsolete: 	((i7_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
//obsolete: 	 multitarg & (i7_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[4] = i4_wb_cyc_i &
	          ((i4_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	            multitarg & (i4_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[5] = i5_wb_cyc_i &
	          ((i5_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	            multitarg & (i5_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));

//
// Determine who gets current access to the target.
//
// If current initiator still asserts request, do nothing
// (keep current initiator).
// Otherwise check each initiator's request, starting from initiator 0
// (highest priority).
// If there is no requests from initiators, park initiator 0.
//
//orig: assign req_won = req_cont ? req_r :
//orig: 		 req_i[0] ? 3'd0 :
//orig: 		 req_i[1] ? 3'd1 :
//orig: 		 req_i[2] ? 3'd2 :
//orig: 		 req_i[3] ? 3'd3 :
//orig: 		 req_i[4] ? 3'd4 :
//orig: 		 req_i[5] ? 3'd5 :
//orig: 		 req_i[6] ? 3'd6 :
//orig: 		 req_i[7] ? 3'd7 : 3'd0;

//obsolete: always @(*)
//obsolete:   casez ({req_cont, req_i}) // synopsys parallel_case
//obsolete:     9'b1????????:  req_won <= req_r;
//obsolete:     9'b0???????1:  req_won <= 3'd0;
//obsolete:     9'b0??????10:  req_won <= 3'd1;
//obsolete:     9'b0?????100:  req_won <= 3'd2;
//obsolete:     9'b0????1000:  req_won <= 3'd3;
//obsolete:     9'b0???10000:  req_won <= 3'd4;
//obsolete:     9'b0??100000:  req_won <= 3'd5;
//obsolete:     9'b0?1000000:  req_won <= 3'd6;
//obsolete:     9'b010000000:  req_won <= 3'd7;
//obsolete:     default:       req_won <= 3'd0;
//obsolete:   endcase
assign req_won = req_cont ? req_r :
		 req_i[4] ? 3'd4  : 
       	         req_i[5] ? 3'd5  : 3'd0;
//
// Check if current initiator still wants access to the target and if
// it does, assert req_cont.
//
//obsolete: always @(req_r or req_i)
//obsolete: 	case (req_r)	// synopsys parallel_case
//obsolete: 		3'd0: req_cont <= req_i[0];
//obsolete: 		3'd1: req_cont <= req_i[1];
//obsolete: 		3'd2: req_cont <= req_i[2];
//obsolete: 		3'd3: req_cont <= req_i[3];
//obsolete: 		3'd4: req_cont <= req_i[4];
//obsolete: 		3'd5: req_cont <= req_i[5];
//obsolete: 		3'd6: req_cont <= req_i[6];
//obsolete: 		3'd7: req_cont <= req_i[7];
//obsolete: 	endcase
always @(req_r or req_i)
	case (req_r)	// synopsys parallel_case
		3'd4: req_cont <= req_i[4];
		3'd5: req_cont <= req_i[5];
             default: req_cont <= 0;
	endcase


//
// Register who has current access to the target.
//
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		req_r <= #1 3'd0;
	else
		req_r <= #1 req_won;

endmodule	


