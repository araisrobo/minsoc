// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "tc_defines.v"

//
// Single initiator to 2 targets
//
module si_to_2t (

	i0_wb_cyc_i,
	i0_wb_stb_i,
	i0_wb_adr_i,
	i0_wb_sel_i,
	i0_wb_we_i,
	i0_wb_dat_i,
	i0_wb_dat_o,
	i0_wb_ack_o,

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
	t1_wb_ack_i
);

//
// Parameters
//
parameter       addr_prefix_w       = 0;
parameter       addr_suffix_w       = 0;
parameter       addr_prefix         = 0;
parameter       t0_addr_suffix      = 0;
parameter       t1_addr_suffix      = 0;

//
// I/O Ports
//

//
// WB slave i/f connecting initiator 0
//
input			i0_wb_cyc_i;
input			i0_wb_stb_i;
input	[`TC_AW-1:0]	i0_wb_adr_i;
input	[`TC_BSW-1:0]	i0_wb_sel_i;
input			i0_wb_we_i;
input	[`TC_DW-1:0]	i0_wb_dat_i;
output	[`TC_DW-1:0]	i0_wb_dat_o;
output			i0_wb_ack_o;

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
// Internal wires & registers
//
wire	[`TC_IIN_W-1:0]	i0_in;
wire	[`TC_TIN_W-1:0]	i0_out;
wire	[`TC_IIN_W-1:0]	t0_out, t1_out;
wire	[`TC_TIN_W-1:0]	t0_in, t1_in;
wire	[1:0]		req_t;
wire                    accel_sel;

//
// Group WB initiator 0 i/f inputs and outputs
//
assign i0_in = {i0_wb_cyc_i, i0_wb_stb_i, i0_wb_adr_i,
		i0_wb_sel_i, i0_wb_we_i, i0_wb_dat_i};
assign {i0_wb_dat_o, i0_wb_ack_o} = i0_out;

//
// Group WB target 0 i/f inputs and outputs
//
assign {t0_wb_cyc_o, t0_wb_stb_o, t0_wb_adr_o,
		t0_wb_sel_o, t0_wb_we_o, t0_wb_dat_o} = t0_out;
assign t0_in = {t0_wb_dat_i, t0_wb_ack_i};

//
// Group WB target 1 i/f inputs and outputs
//
assign {t1_wb_cyc_o, t1_wb_stb_o, t1_wb_adr_o,
		t1_wb_sel_o, t1_wb_we_o, t1_wb_dat_o} = t1_out;
assign t1_in = {t1_wb_dat_i, t1_wb_ack_i};

//
// Assign to WB target i/f outputs
//
// Either inputs from the initiator are assigned or zeros.
//
assign t0_out = req_t[0] ? i0_in : {`TC_IIN_W{1'b0}};
assign t1_out = req_t[1] ? i0_in : {`TC_IIN_W{1'b0}};

//
// Assign to WB initiator i/f outputs
//
// Assign inputs from target to initiator outputs according to
// which target is accessed. If there is no request for a target,
// assign zeros.
//

assign i0_out = t0_wb_ack_i ? t0_in :
		t1_wb_ack_i ? t1_in : {`TC_TIN_W{1'b0}};

//
// Determine which target is being accessed.
//

// the address prefix is 0x9.
assign accel_sel = (i0_wb_adr_i[`TC_AW-1:`TC_AW-addr_prefix_w] == addr_prefix);
assign req_t[0] = i0_wb_cyc_i & accel_sel & (i0_wb_adr_i[`TC_AW-addr_prefix_w-1:`TC_AW-addr_prefix_w-addr_suffix_w] == t0_addr_suffix);
assign req_t[1] = i0_wb_cyc_i & accel_sel & (i0_wb_adr_i[`TC_AW-addr_prefix_w-1:`TC_AW-addr_prefix_w-addr_suffix_w] == t1_addr_suffix);

endmodule	
