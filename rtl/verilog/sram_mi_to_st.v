// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "tc_defines.v"

//
// Multiple initiator to single target
//
module sram_mi_to_st (
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
parameter               addr_prefix_w = 0;
parameter    	        t0_addr_prefix = 0;

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
wire	[`TC_IIN_W-1:0]	i4_in, i5_in;
wire	[`TC_TIN_W-1:0]	i4_out, i5_out;
wire	[`TC_IIN_W-1:0]	t0_out;
wire	[`TC_TIN_W-1:0]	t0_in;
//obsolete: wire	[7:0]		req_i;
wire	[5:4]		req_i;
wire	[2:0]		req_won;
reg			req_cont;
reg	[2:0]		req_r;

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
assign i4_out = (req_won == 3'd4) ? t0_in : {`TC_TIN_W{1'b0}};
assign i5_out = (req_won == 3'd5) ? t0_in : {`TC_TIN_W{1'b0}};

//
// Assign to WB target i/f outputs
//
// Assign inputs from initiator to target outputs according to
// which initiator has won. If there is no request for the target,
// assign zeros.
//
assign t0_out = (req_won == 3'd4) ? i4_in : 
            	(req_won == 3'd5) ? i5_in : {`TC_IIN_W{1'b0}};

//
// Determine if an initiator has address of the target.
//
assign req_i[4] = i4_wb_cyc_i &
	          (i4_wb_adr_i[`TC_AW-1:`TC_AW-addr_prefix_w] == t0_addr_prefix);
assign req_i[5] = i5_wb_cyc_i &
	          (i5_wb_adr_i[`TC_AW-1:`TC_AW-addr_prefix_w] == t0_addr_prefix);

//
// Determine who gets current access to the target.
//
// If current initiator still asserts request, do nothing
// (keep current initiator).
// Otherwise check each initiator's request, starting from initiator 0
// (highest priority).
// If there is no requests from initiators, park initiator 0.
//
assign req_won = req_cont ? req_r :
		 req_i[4] ? 3'd4  : 
       	         req_i[5] ? 3'd5  : 3'd0;
//
// Check if current initiator still wants access to the target and if
// it does, assert req_cont.
//
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


