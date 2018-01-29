`include "subsoc_defines.v"
`include "or1200_defines.v"

module subsoc_top
#(
  parameter           SFIFO_DW        = 16,   // data width for SYNC_FIFO
  parameter           WB_SSIF_AW      = 0,
  parameter           WB_DW           = 0,
  parameter           WOU_DW          = 0,
  parameter           ADC_CMD_W       = 0,
  parameter           ADC_CH_W        = 0,
  parameter           ADC_W           = 0,
  parameter           DAC_W           = 0
)
(
  input               clk,
  input               reset,

  // or32 PROG interface
  input               or32_en_i,          // (1)enable (0)reset OR32
  input   [31:0]      or32_prog_addr_i,   // addr for OR32_PROG
  input   [31:0]      or32_prog_data_i,   // data for OR32_PROG
  input               or32_prog_en_i,     // (1)prog addr,data to OR32

  output                    sfifo_rd_o,
  input                     sfifo_full_i,   // connects to JFIFO.BURST_RD_RDY
  input                     sfifo_empty_i,
  input   [SFIFO_DW-1:0]    sfifo_di,
  input                     sfifo_bp_tick_i,

//rt_cmd:  // RT_CMD Interface (clk_250)
//rt_cmd:  output                    rt_cmd_rst_o,
//rt_cmd:  input   [WB_DW-1:0]       rt_cmd_i,

  // GPIO Interface (clk_250)
  // SYNC_DOUT
  output  [WB_DW-1:0]       dout_0_o,
  output  [WB_DW-1:0]       dout_1_o,
  output  [WB_DW-1:0]       dout_2_o,
  input                     alarm_i,
  // SYNC_DIN
  input   [WB_DW-1:0]       din_0_i,
  input   [WB_DW-1:0]       din_1_i,
  input   [WB_DW-1:0]       din_2_i,
  input   [WB_DW-1:0]       din_3_i,

  // Aanlog to Digital Converter Inputs
  input   [ADC_W-1:0]       adc_lo_i,
  input   [ADC_W-1:0]       adc_hi_i,
  output  [ADC_CH_W-2:0]    adc_ch_sel_o,
  output                    adc_cmd_wr_o,
  output  [ADC_CMD_W-1:0]   adc_cmd_o,  // ADC_CMD
  
  // Digital to Analog Converter Outputs
  output  [DAC_W-1:0]       dac_0_o,
  output  [DAC_W-1:0]       dac_1_o,
  output  [DAC_W-1:0]       dac_2_o,
  output  [DAC_W-1:0]       dac_3_o,

  // MAILBOX Interface (clk_500)
  output                    mbox_wr_o,
  output  [WOU_DW-1:0]      mbox_do_o,
  input                     mbox_full_i,
  input                     mbox_afull_i,
  input                     mbox_empty_i,

  //
  // SSIF (Servo/Stepper InterFace)
  // WISHBONE Interface 1
  output                    wb_ssif_stb_o,
  output                    wb_ssif_cyc_o,
  output  [WB_SSIF_AW-1:2]  wb_ssif_adr_o,
  output  [WB_DW-1:0]       wb_ssif_dat_o,
  output  [WB_DW/8-1:0]     wb_ssif_sel_o,
  output                    wb_ssif_we_o,
  input   [WB_DW-1:0]       wb_ssif_dat_i,
  input                     wb_ssif_ack_i
);

//
// Internal wires
//

//
// Debug <-> RISC wires
//
wire	[3:0]		dbg_lss;
wire	[1:0]		dbg_is;
wire	[10:0]		dbg_wp;
wire			dbg_bp;
wire	[31:0]		dbg_dat_dbg;
wire	[31:0]		dbg_dat_risc;
wire	[31:0]		dbg_adr;
wire			dbg_ewt;
wire			dbg_stall;
wire                    dbg_we;
wire                    dbg_stb;
wire                    dbg_ack;

//
// RISC instruction master i/f wires
//
wire 	[31:0]		wb_rim_adr_o;
wire			wb_rim_cyc_o;
wire 	[31:0]		wb_rim_dat_i;
wire 	[31:0]		wb_rim_dat_o;
wire 	[3:0]		wb_rim_sel_o;
wire			wb_rim_ack_i;
wire			wb_rim_rty_i = 1'b0;
wire			wb_rim_we_o;
wire			wb_rim_stb_o;
`ifdef OR1200_WB_CAB
wire  			wb_rim_cab;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
wire  	[2:0]		wb_rim_cti;	// cycle type identifier
wire  	[1:0]		wb_rim_bte;	// burst type extension
`endif


//
// RISC data master i/f wires
//
wire 	[31:0]		wb_rdm_adr_o; // keep hierarchy for Xilinx XST
wire			wb_rdm_cyc_o;
wire 	[31:0]		wb_rdm_dat_i;
wire 	[31:0]		wb_rdm_dat_o;
wire 	[3:0]		wb_rdm_sel_o;
wire			wb_rdm_ack_i;
wire			wb_rdm_rty_i = 1'b0;
wire			wb_rdm_we_o;
wire			wb_rdm_stb_o;
`ifdef OR1200_WB_CAB
wire   		        wb_rdm_cab;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
wire  	[2:0]		wb_rdm_cti;	// cycle type identifier
wire  	[1:0]		wb_rdm_bte;	// burst type extension
`endif


//
// RISC misc
//
wire	[`OR1200_PIC_INTS-1:0]		pic_ints;
wire                                    sig_tick;

//
// SRAM controller slave i/f wires
//
wire 	[31:0]		wb_ss_dat_i;
wire 	[31:0]		wb_ss_dat_o;
wire 	[31:0]		wb_ss_adr_i;
wire 	[3:0]		wb_ss_sel_i;
wire			wb_ss_we_i;
wire			wb_ss_cyc_i;
wire			wb_ss_stb_i;
wire			wb_ss_ack_o;

//
// SFIFO_IF slave i/f wires (sfifoS: sfifo Slave)
//
wire	[31:0]		wb_sfifos_dat_i;
wire	[31:0]		wb_sfifos_dat_o;
wire	[31:0]		wb_sfifos_adr_i;
wire	[3:0]		wb_sfifos_sel_i;
wire			wb_sfifos_we_i;
wire			wb_sfifos_cyc_i;
wire			wb_sfifos_stb_i;
wire			wb_sfifos_ack_o;

// SSIF
wire    [31:0]          wb_ssif_adr;

//
// Global clock
//
wire			wb_clk;
wire                    wb_rst;

assign wb_clk = clk;
assign wb_rst = reset;

//
// Unused interrupts
//
assign pic_ints[`APP_INT_RES1] = 'b0;
assign pic_ints[`APP_INT_RES2] = 'b0;
assign pic_ints[`APP_INT_RES3] = 'b0;
assign pic_ints[`APP_INT_PS2] = 'b0;
  

// SSIF
assign wb_ssif_adr_o = wb_ssif_adr[WB_SSIF_AW-1:2];

//
// TAP<->dbg_interface
//      
wire jtag_tck;
wire debug_tdi;
wire debug_tdo;
wire capture_dr;
wire shift_dr;
wire pause_dr;
wire update_dr;   

wire debug_select;
wire test_logic_reset;

// unused debug signals
assign dbg_we = 0;
assign dbg_stb = 0;
assign dbg_stall = 0;

//
// Instantiation of the OR1200 RISC
//
or1200_top or1200_top (

	// Common
	.rst_i		( wb_rst | (~or32_en_i) ),
	.clk_i		( wb_clk ),
`ifdef OR1200_CLMODE_1TO2
	.clmode_i	( 2'b01 ),
`else
`ifdef OR1200_CLMODE_1TO4
	.clmode_i	( 2'b11 ),
`else
	.clmode_i	( 2'b00 ),
`endif
`endif
  
	// WISHBONE Instruction Master
	.iwb_clk_i	( wb_clk ),
	.iwb_rst_i	( wb_rst ),
	.iwb_cyc_o	( wb_rim_cyc_o ),
	.iwb_adr_o	( wb_rim_adr_o ),
	.iwb_dat_i	( wb_rim_dat_i ),
	.iwb_dat_o	( wb_rim_dat_o ),
	.iwb_sel_o	( wb_rim_sel_o ),
	.iwb_ack_i	( wb_rim_ack_i ),
	.iwb_rty_i	( wb_rim_rty_i ),
	.iwb_we_o	( wb_rim_we_o  ),
	.iwb_stb_o	( wb_rim_stb_o ),
`ifdef OR1200_WB_CAB
	.iwb_cab_o      ( wb_rim_cab   ),
`endif
`ifdef OR1200_WB_B3
	.iwb_cti_o      ( wb_rim_cti   ),
        .iwb_bte_o      ( wb_rim_bte   ),
`endif

	// WISHBONE Data Master
	.dwb_clk_i	( wb_clk ),
	.dwb_rst_i	( wb_rst ),
	.dwb_cyc_o	( wb_rdm_cyc_o ),
	.dwb_adr_o	( wb_rdm_adr_o ),
	.dwb_dat_i	( wb_rdm_dat_i ),
	.dwb_dat_o	( wb_rdm_dat_o ),
	.dwb_sel_o	( wb_rdm_sel_o ),
	.dwb_ack_i	( wb_rdm_ack_i ),
	.dwb_rty_i	( wb_rdm_rty_i ),
	.dwb_we_o	( wb_rdm_we_o  ),
	.dwb_stb_o	( wb_rdm_stb_o ),
`ifdef OR1200_WB_CAB
	.dwb_cab_o      ( wb_rdm_cab   ),
`endif
`ifdef OR1200_WB_B3
	.dwb_cti_o      ( wb_rdm_cti   ),
        .dwb_bte_o      ( wb_rdm_bte   ),
`endif

	// Debug
	.dbg_stall_i	( dbg_stall ),
	.dbg_dat_i	( dbg_dat_dbg ),
	.dbg_adr_i	( dbg_adr ),
	.dbg_ewt_i	( 1'b0 ),
	.dbg_lss_o	( dbg_lss ),
	.dbg_is_o	( dbg_is ),
	.dbg_wp_o	( dbg_wp ),
	.dbg_bp_o	( dbg_bp ),
	.dbg_dat_o	( dbg_dat_risc ),
	.dbg_ack_o	( dbg_ack ),
	.dbg_stb_i	( dbg_stb ),
	.dbg_we_i	( dbg_we ),

	// Power Management
	.pm_clksd_o	( ),
	.pm_cpustall_i	( 1'b0 ),
	.pm_dc_gate_o	( ),
	.pm_ic_gate_o	( ),
	.pm_dmmu_gate_o	( ),
	.pm_immu_gate_o	( ),
	.pm_tt_gate_o	( ),
	.pm_cpu_gate_o	( ),
	.pm_wakeup_o	( ),
	.pm_lvolt_o	( ),

	// Interrupts
	.pic_ints_i	( pic_ints ),
        .sig_tick       ( sig_tick )
);

//
// Instantiation of the SRAM controller
//
subsoc_onchip_ram_top # 
(
  .RAM_AW       (`MEMORY_ADR_WIDTH)     //16 blocks of 2048 bytes memory 32768
)
onchip_ram_top (

  // WISHBONE common
  .wb_clk_i	( wb_clk ),
  .wb_rst_i	( wb_rst ),

  // WISHBONE slave
  .wb_dat_i	( wb_ss_dat_i ),
  .wb_dat_o	( wb_ss_dat_o ),
  .wb_adr_i	( wb_ss_adr_i ),
  .wb_sel_i	( wb_ss_sel_i ),
  .wb_we_i	( wb_ss_we_i  ),
  .wb_cyc_i	( wb_ss_cyc_i ),
  .wb_stb_i	( wb_ss_stb_i ),
  .wb_ack_o	( wb_ss_ack_o ),
  
  // WISHBONE slave
  .wb_rim_dat_i	( wb_rim_dat_o ),
  .wb_rim_dat_o	( wb_rim_dat_i ),
  .wb_rim_adr_i	( wb_rim_adr_o ),
  .wb_rim_sel_i	( wb_rim_sel_o ),
  .wb_rim_we_i	( wb_rim_we_o  ),
  .wb_rim_cyc_i	( wb_rim_cyc_o ),
  .wb_rim_stb_i	( wb_rim_stb_o ),
  .wb_rim_ack_o	( wb_rim_ack_i ),

  // OR32 PROG interface
  .prog_addr_i  (or32_prog_addr_i[`MEMORY_ADR_WIDTH+1:2]),  // addr for OR32_PROG
  .prog_data_i  (or32_prog_data_i),     // data for OR32_PROG
  .prog_en_i    (or32_prog_en_i)        // (1)write addr/data to OR32

);

//
// Instantiation of the SFIFO_IF
//
sfifo_if_top #(
  .WB_AW              ( 7         ),  // lower address bits
  .WB_DW              ( 32        ),
  .WOU_DW             ( WOU_DW    ),  // WOU data bus width
  .SFIFO_DW           ( SFIFO_DW  ),  // data width for SYNC_FIFO
  .ADC_CMD_W          ( ADC_CMD_W ),  // ADC_PREAMBLE, ADC_CMD
  .ADC_CH_W           ( ADC_CH_W  ),  // width for ADC channel select signal
  .ADC_W              ( ADC_W     ),  // width for ADC value
  .DAC_W              ( DAC_W     )   // width for DAC command
) sfifo_if_top (

  // WISHBONE common
  .wb_clk_i	      ( wb_clk ), 
  .wb_rst_i	      ( wb_rst ),

  // WISHBONE slave
  .wb_adr_i	      ( wb_sfifos_adr_i[6:2] ),
  .wb_dat_i	      ( wb_sfifos_dat_i      ),
  .wb_dat_o	      ( wb_sfifos_dat_o      ),
  .wb_we_i	      ( wb_sfifos_we_i       ),
  .wb_stb_i	      ( wb_sfifos_stb_i      ),
  .wb_cyc_i	      ( wb_sfifos_cyc_i      ),
  .wb_ack_o	      ( wb_sfifos_ack_o      ),
  .wb_sel_i	      ( wb_sfifos_sel_i      ),

  // SFIFO Interface (clk_500)
  .sfifo_rd_o         ( sfifo_rd_o           ),
  .sfifo_full_i       ( sfifo_full_i         ), // connects to JFIFO.BURST_RD_RDY
  .sfifo_empty_i      ( sfifo_empty_i        ),
  .sfifo_di           ( sfifo_di             ),
  
  // MAILBOX Interface (clk_500)
  .mbox_wr_o          ( mbox_wr_o ),
  .mbox_do_o          ( mbox_do_o ),
  .mbox_full_i        ( mbox_full_i ),
  .mbox_afull_i       ( mbox_afull_i ),
  .mbox_empty_i       ( mbox_empty_i ),

  // SFIFO_CTRL Interface (clk_250)
  .sfifo_bp_tick_i    ( sfifo_bp_tick_i     ),

//rt_cmd:  // RT_CMD Interface (clk_250)
//rt_cmd:  .rt_cmd_rst_o       ( rt_cmd_rst_o        ),
//rt_cmd:  .rt_cmd_i           ( rt_cmd_i            ),
  
  // GPIO Interface (clk_250)
  // SYNC_DOUT
  .dout_0_o           ( dout_0_o ),
  .dout_1_o           ( dout_1_o ),
  .dout_2_o           ( dout_2_o ),
  .alarm_i            ( alarm_i ),
  // SYNC_DIN
  .din_0_i            ( din_0_i ),
  .din_1_i            ( din_1_i ),
  .din_2_i            ( din_2_i ),
  .din_3_i            ( din_3_i ),

  // ADC Input
  .adc_lo_i           ( adc_lo_i ),
  .adc_hi_i           ( adc_hi_i ),
  .adc_ch_sel_o       ( adc_ch_sel_o ),
  .adc_cmd_wr_o       ( adc_cmd_wr_o ),
  .adc_cmd_o          ( adc_cmd_o ),
  
  // DAC output
  .dac_0_o            ( dac_0_o ),
  .dac_1_o            ( dac_1_o ),
  .dac_2_o            ( dac_2_o ),
  .dac_3_o            ( dac_3_o )
);

// interrupt for UART
assign pic_ints[`APP_INT_UART] = 1'b0;
// interrupt for ETH
assign pic_ints[`APP_INT_ETH] = 1'b0;

//
// Instantiation of the Traffic COP
//
si_to_3t #(
          .addr_prefix_w    (`APP_ADDR_PREFIX_W       ),
          .addr_suffix_w    (`APP_ADDR_SUFFIX_W       ),
	  .t0_addr_prefix   (`APP_ADDR_PREFIX_SRAM    ),
	  .accel_addr_prefix(`APP_ADDR_PREFIX_ACCEL   ),
	  .t1_addr_suffix   (`ACCEL_ADDR_SUFFIX_SFIFO ),
	  .t2_addr_suffix   (`ACCEL_ADDR_SUFFIX_SSIF  )
	) tc_top (

	// WISHBONE Initiator 4   (rdm: or1200 data master)
	.i0_wb_cyc_i	( wb_rdm_cyc_o ),
	.i0_wb_stb_i	( wb_rdm_stb_o ),
	.i0_wb_adr_i	( wb_rdm_adr_o ),
	.i0_wb_sel_i	( wb_rdm_sel_o ),
	.i0_wb_we_i	( wb_rdm_we_o  ),
	.i0_wb_dat_i	( wb_rdm_dat_o ),
	.i0_wb_dat_o	( wb_rdm_dat_i ),
	.i0_wb_ack_o	( wb_rdm_ack_i ),

	// WISHBONE Target 0 (ss: sram controller, 0x00)
	.t0_wb_cyc_o	( wb_ss_cyc_i ),
	.t0_wb_stb_o	( wb_ss_stb_i ),
	.t0_wb_adr_o	( wb_ss_adr_i ),
	.t0_wb_sel_o	( wb_ss_sel_i ),
	.t0_wb_we_o	( wb_ss_we_i  ),
	.t0_wb_dat_o	( wb_ss_dat_i ),
	.t0_wb_dat_i	( wb_ss_dat_o ),
	.t0_wb_ack_i	( wb_ss_ack_o ),

	// WISHBONE Target 1 (sfifos: sync fifo slave, 0x9d)
	.t1_wb_cyc_o	( wb_sfifos_cyc_i ),
	.t1_wb_stb_o	( wb_sfifos_stb_i ),
	.t1_wb_adr_o	( wb_sfifos_adr_i ),
	.t1_wb_sel_o	( wb_sfifos_sel_i ),
	.t1_wb_we_o	( wb_sfifos_we_i  ),
	.t1_wb_dat_o	( wb_sfifos_dat_i ),
	.t1_wb_dat_i	( wb_sfifos_dat_o ),
	.t1_wb_ack_i	( wb_sfifos_ack_o ),
	
	// WISHBONE Target 2 (ssifs: SSIF Slave, 0x9e)
	.t2_wb_cyc_o	( wb_ssif_cyc_o ),
	.t2_wb_stb_o	( wb_ssif_stb_o ),
	.t2_wb_adr_o	( wb_ssif_adr   ),
	.t2_wb_sel_o	( wb_ssif_sel_o ),
	.t2_wb_we_o	( wb_ssif_we_o  ),
	.t2_wb_dat_o	( wb_ssif_dat_o ),
	.t2_wb_dat_i	( wb_ssif_dat_i ),
	.t2_wb_ack_i	( wb_ssif_ack_i )
);

//initial begin
//  $dumpvars(0);
//  $dumpfile("dump.vcd");
//end

endmodule
