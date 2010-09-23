`include "subsoc_defines.v"
`include "or1200_defines.v"

module subsoc_top 
#(
  parameter           SFIFO_DW        = 16,   // data width for SYNC_FIFO
  parameter           WB_SSIF_AW      = 0,
  parameter           WB_DW           = 0
)
(
  input               clk,
  input               reset,

  // or32 PROG interface
  input               or32_en_i,          // (1)enable (0)reset OR32
  input   [31:0]      or32_prog_addr_i,   // addr for OR32_PROG
  input   [31:0]      or32_prog_data_i,   // data for OR32_PROG
  input               or32_prog_en_i      // (1)prog addr,data to OR32
  
  //
  // SPI controller external i/f wires
  //
`ifdef START_UP
  ,
  output              spi_flash_mosi,
  input               spi_flash_miso,
  output              spi_flash_sclk,
  output [1:0]        spi_flash_ss
`endif

//
// UART
//
`ifdef UART
  ,
  output [7:0]        uusb_dat_o,
  input  [7:0]        uusb_dat_i 
`endif

//
// SFIFO_IF (sync fofo interface)
//
`ifdef SFIFO_IF
  ,
  output                    sfifo_rd_o,
  input                     sfifo_empty_i,
  input   [SFIFO_DW-1:0]    sfifo_di,
  input                     sfifo_bp_tick_i,
  // GPIO Interface (clk_250)
  // SYNC_DOUT
  output  [7:0]             dout_set_o,
  output  [7:0]             dout_rst_o,
  // SYNC_DIN
  input   [15:0]            din_i
`endif

//
// SSIF (Servo/Stepper InterFace)
//
`ifdef SSIF
  ,
  // WISHBONE Interface 1
  output                    wb_ssif_stb_o,
  output                    wb_ssif_cyc_o,
  output  [WB_SSIF_AW-1:2]  wb_ssif_adr_o,
  output  [WB_DW-1:0]       wb_ssif_dat_o,
  output  [WB_DW/8-1:0]     wb_ssif_sel_o,
  output                    wb_ssif_we_o,
  input   [WB_DW-1:0]       wb_ssif_dat_i,
  input                     wb_ssif_ack_i,
  input                     wb_ssif_err_i
`endif

);

//
// Internal wires
//

//
// Debug core master i/f wires
//
wire 	[31:0]		wb_dm_adr_o;
wire 	[31:0] 		wb_dm_dat_i;
wire 	[31:0] 		wb_dm_dat_o;
wire 	[3:0]		wb_dm_sel_o;
wire			wb_dm_we_o;
wire 			wb_dm_stb_o;
wire			wb_dm_cyc_o;
wire			wb_dm_ack_i;
wire			wb_dm_err_i;

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
wire			wb_rim_err_i;
wire			wb_rim_rty_i = 1'b0;
wire			wb_rim_we_o;
wire			wb_rim_stb_o;
wire	[31:0]		wb_rif_dat_i;
wire			wb_rif_ack_i;
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
wire			wb_rdm_err_i;
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
// Flash controller slave i/f wires
//
wire 	[31:0]		wb_fs_dat_i;
wire 	[31:0]		wb_fs_dat_o;
wire 	[31:0]		wb_fs_adr_i;
wire 	[3:0]		wb_fs_sel_i;
wire			wb_fs_we_i;
wire			wb_fs_cyc_i;
wire			wb_fs_stb_i;
wire			wb_fs_ack_o;
wire			wb_fs_err_o;

//
// SPI controller slave i/f wires
//
wire 	[31:0]		wb_sp_dat_i;
wire 	[31:0]		wb_sp_dat_o;
wire 	[31:0]		wb_sp_adr_i;
wire 	[3:0]		wb_sp_sel_i;
wire			wb_sp_we_i;
wire			wb_sp_cyc_i;
wire			wb_sp_stb_i;
wire			wb_sp_ack_o;
wire			wb_sp_err_o;

//
// SPI controller external i/f wires
//
wire spi_flash_mosi;
wire spi_flash_miso;
wire spi_flash_sclk;
wire [1:0] spi_flash_ss;

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
wire			wb_ss_err_o;

//
// Ethernet core master i/f wires
//
wire 	[31:0]		wb_em_adr_o;
wire 	[31:0] 		wb_em_dat_i;
wire 	[31:0] 		wb_em_dat_o;
wire 	[3:0]		wb_em_sel_o;
wire			wb_em_we_o;
wire 			wb_em_stb_o;
wire			wb_em_cyc_o;
wire			wb_em_ack_i;
wire			wb_em_err_i;

//
// Ethernet core slave i/f wires
//
wire	[31:0]		wb_es_dat_i;
wire	[31:0]		wb_es_dat_o;
wire	[31:0]		wb_es_adr_i;
wire	[3:0]		wb_es_sel_i;
wire			wb_es_we_i;
wire			wb_es_cyc_i;
wire			wb_es_stb_i;
wire			wb_es_ack_o;
wire			wb_es_err_o;

//
// Ethernet external i/f wires
//
wire			eth_mdo;
wire			eth_mdoe;

//
// UART16550 core slave i/f wires
//
wire	[31:0]		wb_us_dat_i;
wire	[31:0]		wb_us_dat_o;
wire	[31:0]		wb_us_adr_i;
wire	[3:0]		wb_us_sel_i;
wire			wb_us_we_i;
wire			wb_us_cyc_i;
wire			wb_us_stb_i;
wire			wb_us_ack_o;
wire			wb_us_err_o;

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
wire			wb_sfifos_err_o;

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
// Unused WISHBONE signals
//
assign wb_us_err_o = 1'b0;
assign wb_fs_err_o = 1'b0;
assign wb_sp_err_o = 1'b0;
assign wb_sfifos_err_o = 1'b0;

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
// RISC Instruction address for Flash
//
// Until first access to real Flash area,
// CPU instruction is fixed to jump to the Flash area.
// After Flash area is accessed, CPU instructions 
// come from the tc_top (wishbone "switch").
//
`ifdef START_UP
reg jump_flash;
reg [3:0] rif_counter;
reg [31:0] rif_dat_int;
reg rif_ack_int;

always @(posedge wb_clk or negedge rstn)
begin
	if (!rstn) begin
		jump_flash <= #1 1'b1;
		rif_counter <= 4'h0;
		rif_ack_int <= 1'b0;
	end
	else begin
		rif_ack_int <= 1'b0;

		if (wb_rim_cyc_o && (wb_rim_adr_o[31:32-`APP_ADDR_DEC_W] == `APP_ADDR_FLASH))
			jump_flash <= #1 1'b0;
		
		if ( jump_flash == 1'b1 ) begin
			if ( wb_rim_cyc_o && wb_rim_stb_o && ~wb_rim_we_o ) begin
				rif_counter <= rif_counter + 1'b1;
				rif_ack_int <= 1'b1;
			end
		end
	end
end

always @ (rif_counter)
begin
	case ( rif_counter )
		4'h0: rif_dat_int = { `OR1200_OR32_MOVHI , 5'h01 , 4'h0 , 1'b0 , `APP_ADDR_FLASH , 8'h00 };
		4'h1: rif_dat_int = { `OR1200_OR32_ORI , 5'h01 , 5'h01 , 16'h0000 };
		4'h2: rif_dat_int = { `OR1200_OR32_JR , 10'h000 , 5'h01 , 11'h000 };
		4'h3: rif_dat_int = { `OR1200_OR32_NOP , 10'h000 , 16'h0000 };
		default: rif_dat_int = 32'h0000_0000;
	endcase
end

assign wb_rif_dat_i = jump_flash ? rif_dat_int : wb_rim_dat_i;

assign wb_rif_ack_i = jump_flash ? rif_ack_int : wb_rim_ack_i;

`else
assign wb_rif_dat_i = wb_rim_dat_i;
assign wb_rif_ack_i = wb_rim_ack_i;
`endif


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
assign wb_dm_cyc_o = 1'b0;
assign wb_dm_stb_o = 1'b0;
assign wb_dm_adr_o = 32'h0000_0000;
assign wb_dm_sel_o = 4'b0000;
assign wb_dm_we_o  = 1'b0;
assign wb_dm_dat_o = 32'h0000_0000;

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
	.iwb_dat_i	( wb_rif_dat_i ),
	.iwb_dat_o	( wb_rim_dat_o ),
	.iwb_sel_o	( wb_rim_sel_o ),
	.iwb_ack_i	( wb_rif_ack_i ),
	.iwb_err_i	( wb_rim_err_i ),
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
	.dwb_err_i	( wb_rdm_err_i ),
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
// Startup OR1k
//
`ifdef START_UP
OR1K_startup OR1K_startup0
(
    .wb_adr_i(wb_fs_adr_i[6:2]),
    .wb_stb_i(wb_fs_stb_i),
    .wb_cyc_i(wb_fs_cyc_i),
    .wb_dat_o(wb_fs_dat_o),
    .wb_ack_o(wb_fs_ack_o),
    .wb_clk(wb_clk),
    .wb_rst(wb_rst)
);

spi_flash_top #
(
   .divider(0),
   .divider_len(2)
)
spi_flash_top0
(
   .wb_clk_i(wb_clk), 
   .wb_rst_i(wb_rst),
   .wb_adr_i(wb_sp_adr_i[4:2]),
   .wb_dat_i(wb_sp_dat_i), 
   .wb_dat_o(wb_sp_dat_o),
   .wb_sel_i(wb_sp_sel_i),
   .wb_we_i(wb_sp_we_i),
   .wb_stb_i(wb_sp_stb_i), 
   .wb_cyc_i(wb_sp_cyc_i),
   .wb_ack_o(wb_sp_ack_o), 

   .mosi_pad_o(spi_flash_mosi),
   .miso_pad_i(spi_flash_miso),
   .sclk_pad_o(spi_flash_sclk),
   .ss_pad_o(spi_flash_ss)
);
`else
assign wb_fs_dat_o = 32'h0000_0000;
assign wb_fs_ack_o = 1'b0;
assign wb_sp_dat_o = 32'h0000_0000;
assign wb_sp_ack_o = 1'b0;
`endif

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
  .wb_err_o	( wb_ss_err_o ),

  // OR32 PROG interface
  .prog_addr_i  (or32_prog_addr_i[`MEMORY_ADR_WIDTH+1:2]),  // addr for OR32_PROG
  .prog_data_i  (or32_prog_data_i),     // data for OR32_PROG
  .prog_en_i    (or32_prog_en_i)        // (1)write addr/data to OR32

);

//
// Instantiation of the SFIFO_IF
//
`ifdef SFIFO_IF
sfifo_if_top #(
  .WB_AW              ( 5         ),  // lower address bits
  .WB_DW              ( 32        ),
  .SFIFO_DW           ( SFIFO_DW  )   // data width for SYNC_FIFO
) sfifo_if_top (

  // WISHBONE common
  .wb_clk_i	      ( wb_clk ), 
  .wb_rst_i	      ( wb_rst ),

  // WISHBONE slave
  .wb_adr_i	      ( wb_sfifos_adr_i[4:2] ),
  .wb_dat_i	      ( wb_sfifos_dat_i      ),
  .wb_dat_o	      ( wb_sfifos_dat_o      ),
  .wb_we_i	      ( wb_sfifos_we_i       ),
  .wb_stb_i	      ( wb_sfifos_stb_i      ),
  .wb_cyc_i	      ( wb_sfifos_cyc_i      ),
  .wb_ack_o	      ( wb_sfifos_ack_o      ),
  .wb_sel_i	      ( wb_sfifos_sel_i      ),

  // SFIFO Interface (clk_500)
  .sfifo_rd_o         ( sfifo_rd_o           ),
  .sfifo_empty_i      ( sfifo_empty_i        ),
  .sfifo_di           ( sfifo_di             ),

  // SFIFO_CTRL Interface (clk_250)
  .sfifo_bp_tick_i    ( sfifo_bp_tick_i     ),
  
  // GPIO Interface (clk_250)
  // SYNC_DOUT
  .dout_set_o         ( dout_set_o ),
  .dout_rst_o         ( dout_rst_o ),
  // SYNC_DIN
  .din_i              ( din_i )

);
`else
assign wb_sfifos_dat_o = 32'h0000_0000;
assign wb_sfifos_ack_o = 1'b0;
`endif

//
// Instantiation of the UART16550
//
`ifdef UART
uusb_top uusb_top (

	// WISHBONE common
	.wb_clk_i	( wb_clk ), 
	.wb_rst_i	( wb_rst ),

	// WISHBONE slave
	.wb_adr_i	( wb_us_adr_i[4:0] ),
	.wb_dat_i	( wb_us_dat_i ),
	.wb_dat_o	( wb_us_dat_o ),
	.wb_we_i	( wb_us_we_i  ),
	.wb_stb_i	( wb_us_stb_i ),
	.wb_cyc_i	( wb_us_cyc_i ),
	.wb_ack_o	( wb_us_ack_o ),
	.wb_sel_i	( wb_us_sel_i ),

	// UART signals
	// serial input/output
	.uusb_dat_o	( uusb_dat_o ),
	.uusb_dat_i	( uusb_dat_i )
);
// uart_top uart_top (
// 
// 	// WISHBONE common
// 	.wb_clk_i	( wb_clk ), 
// 	.wb_rst_i	( wb_rst ),
// 
// 	// WISHBONE slave
// 	.wb_adr_i	( wb_us_adr_i[4:0] ),
// 	.wb_dat_i	( wb_us_dat_i ),
// 	.wb_dat_o	( wb_us_dat_o ),
// 	.wb_we_i	( wb_us_we_i  ),
// 	.wb_stb_i	( wb_us_stb_i ),
// 	.wb_cyc_i	( wb_us_cyc_i ),
// 	.wb_ack_o	( wb_us_ack_o ),
// 	.wb_sel_i	( wb_us_sel_i ),
// 
// 	// Interrupt request
// 	.int_o		( pic_ints[`APP_INT_UART] ),
// 
// 	// UART signals
// 	// serial input/output
// 	.stx_pad_o	( uart_stx ),
// 	.srx_pad_i	( uart_srx ),
// 
// 	// modem signals
// 	.rts_pad_o	( ),
// 	.cts_pad_i	( 1'b0 ),
// 	.dtr_pad_o	( ),
// 	.dsr_pad_i	( 1'b0 ),
// 	.ri_pad_i	( 1'b0 ),
// 	.dcd_pad_i	( 1'b0 )
// );
`else
assign wb_us_dat_o = 32'h0000_0000;
assign wb_us_ack_o = 1'b0;

assign pic_ints[`APP_INT_UART] = 1'b0;
`endif

//
// Instantiation of the Ethernet 10/100 MAC
//
`ifdef ETHERNET
eth_top eth_top (

	// WISHBONE common
	.wb_clk_i	( wb_clk ),
	.wb_rst_i	( wb_rst ),

	// WISHBONE slave
	.wb_dat_i	( wb_es_dat_i ),
	.wb_dat_o	( wb_es_dat_o ),
	.wb_adr_i	( wb_es_adr_i[11:2] ),
	.wb_sel_i	( wb_es_sel_i ),
	.wb_we_i	( wb_es_we_i  ),
	.wb_cyc_i	( wb_es_cyc_i ),
	.wb_stb_i	( wb_es_stb_i ),
	.wb_ack_o	( wb_es_ack_o ),
	.wb_err_o	( wb_es_err_o ), 

	// WISHBONE master
	.m_wb_adr_o	( wb_em_adr_o ),
	.m_wb_sel_o	( wb_em_sel_o ),
	.m_wb_we_o	( wb_em_we_o  ), 
	.m_wb_dat_o	( wb_em_dat_o ),
	.m_wb_dat_i	( wb_em_dat_i ),
	.m_wb_cyc_o	( wb_em_cyc_o ), 
	.m_wb_stb_o	( wb_em_stb_o ),
	.m_wb_ack_i	( wb_em_ack_i ),
	.m_wb_err_i	( wb_em_err_i ), 

	// TX
	.mtx_clk_pad_i	( eth_tx_clk ),
	.mtxd_pad_o	( eth_txd ),
	.mtxen_pad_o	( eth_tx_en ),
	.mtxerr_pad_o	( eth_tx_er ),

	// RX
	.mrx_clk_pad_i	( eth_rx_clk ),
	.mrxd_pad_i	( eth_rxd ),
	.mrxdv_pad_i	( eth_rx_dv ),
	.mrxerr_pad_i	( eth_rx_er ),
	.mcoll_pad_i	( eth_col ),
	.mcrs_pad_i	( eth_crs ),
  
	// MIIM
	.mdc_pad_o	( eth_mdc ),
	.md_pad_i	( eth_mdio ),
	.md_pad_o	( eth_mdo ),
	.md_padoe_o	( eth_mdoe ),

	// Interrupt
	.int_o		( pic_ints[`APP_INT_ETH] )
);
`else
assign wb_es_dat_o = 32'h0000_0000;
assign wb_es_ack_o = 1'b0;
assign wb_es_err_o = 1'b0;

assign wb_em_adr_o = 32'h0000_0000;
assign wb_em_sel_o = 4'h0;
assign wb_em_we_o = 1'b0;
assign wb_em_dat_o = 32'h0000_0000;
assign wb_em_cyc_o = 1'b0;
assign wb_em_stb_o = 1'b0;

assign pic_ints[`APP_INT_ETH] = 1'b0;
`endif

//
// Instantiation of the Traffic COP
//
subsoc_tc_top #(
          .t0_addr_w    ( `APP_ADDR_DEC_W   ),
	  .t0_addr      ( `APP_ADDR_SRAM    ),
	  .t1_addr_w    ( `APP_ADDR_DEC_W   ),
	  .t1_addr      ( `APP_ADDR_FLASH   ),
	  .t28c_addr_w  ( `APP_ADDR_DECP_W  ),
	  .t28_addr     ( `APP_ADDR_PERIP   ),
	  .t28i_addr_w  ( `APP_ADDR_DEC_W   ),
	  .t2_addr      ( `APP_ADDR_SPI     ),
	  .t3_addr      ( `APP_ADDR_ETH     ),
	  .t4_addr      ( `APP_ADDR_SFIFO   ),
	  .t5_addr      ( `APP_ADDR_UART    ),
	  .t6_addr      ( `APP_ADDR_PS2     ),
	  .t7_addr      ( `APP_ADDR_SSIF    ),
	  .t8_addr      ( `APP_ADDR_RES2    )
	) tc_top (

	// WISHBONE common
	.wb_clk_i	( wb_clk ),
	.wb_rst_i	( wb_rst ),

	// WISHBONE Initiator 0
	.i0_wb_cyc_i	( 1'b0 ),
	.i0_wb_stb_i	( 1'b0 ),
	.i0_wb_adr_i	( 32'h0000_0000 ),
	.i0_wb_sel_i	( 4'b0000 ),
	.i0_wb_we_i	( 1'b0 ),
	.i0_wb_dat_i	( 32'h0000_0000 ),
	.i0_wb_dat_o	( ),
	.i0_wb_ack_o	( ),
	.i0_wb_err_o	( ),

	// WISHBONE Initiator 1   (em: Ethernet Master)
	.i1_wb_cyc_i	( wb_em_cyc_o ),
	.i1_wb_stb_i	( wb_em_stb_o ),
	.i1_wb_adr_i	( wb_em_adr_o ),
	.i1_wb_sel_i	( wb_em_sel_o ),
	.i1_wb_we_i	( wb_em_we_o  ),
	.i1_wb_dat_i	( wb_em_dat_o ),
	.i1_wb_dat_o	( wb_em_dat_i ),
	.i1_wb_ack_o	( wb_em_ack_i ),
	.i1_wb_err_o	( wb_em_err_i ),

	// WISHBONE Initiator 2
	.i2_wb_cyc_i	( 1'b0 ),
	.i2_wb_stb_i	( 1'b0 ),
	.i2_wb_adr_i	( 32'h0000_0000 ),
	.i2_wb_sel_i	( 4'b0000 ),
	.i2_wb_we_i	( 1'b0 ),
	.i2_wb_dat_i	( 32'h0000_0000 ),
	.i2_wb_dat_o	( ),
	.i2_wb_ack_o	( ),
	.i2_wb_err_o	( ),

	// WISHBONE Initiator 3   (dm: debug master)
	.i3_wb_cyc_i	( wb_dm_cyc_o ),
	.i3_wb_stb_i	( wb_dm_stb_o ),
	.i3_wb_adr_i	( wb_dm_adr_o ),
	.i3_wb_sel_i	( wb_dm_sel_o ),
	.i3_wb_we_i	( wb_dm_we_o  ),
	.i3_wb_dat_i	( wb_dm_dat_o ),
	.i3_wb_dat_o	( wb_dm_dat_i ),
	.i3_wb_ack_o	( wb_dm_ack_i ),
	.i3_wb_err_o	( wb_dm_err_i ),

	// WISHBONE Initiator 4   (rdm: or1200 data master)
	.i4_wb_cyc_i	( wb_rdm_cyc_o ),
	.i4_wb_stb_i	( wb_rdm_stb_o ),
	.i4_wb_adr_i	( wb_rdm_adr_o ),
	.i4_wb_sel_i	( wb_rdm_sel_o ),
	.i4_wb_we_i	( wb_rdm_we_o  ),
	.i4_wb_dat_i	( wb_rdm_dat_o ),
	.i4_wb_dat_o	( wb_rdm_dat_i ),
	.i4_wb_ack_o	( wb_rdm_ack_i ),
	.i4_wb_err_o	( wb_rdm_err_i ),

	// WISHBONE Initiator 5   (rim: or1200 instruction master)
	.i5_wb_cyc_i	( wb_rim_cyc_o ),
	.i5_wb_stb_i	( wb_rim_stb_o ),
	.i5_wb_adr_i	( wb_rim_adr_o ),
	.i5_wb_sel_i	( wb_rim_sel_o ),
	.i5_wb_we_i	( wb_rim_we_o  ),
	.i5_wb_dat_i	( wb_rim_dat_o ),
	.i5_wb_dat_o	( wb_rim_dat_i ),
	.i5_wb_ack_o	( wb_rim_ack_i ),
	.i5_wb_err_o	( wb_rim_err_i ),

	// WISHBONE Initiator 6
	.i6_wb_cyc_i	( 1'b0 ),
	.i6_wb_stb_i	( 1'b0 ),
	.i6_wb_adr_i	( 32'h0000_0000 ),
	.i6_wb_sel_i	( 4'b0000 ),
	.i6_wb_we_i	( 1'b0 ),
	.i6_wb_dat_i	( 32'h0000_0000 ),
	.i6_wb_dat_o	( ),
	.i6_wb_ack_o	( ),
	.i6_wb_err_o	( ),

	// WISHBONE Initiator 7
	.i7_wb_cyc_i	( 1'b0 ),
	.i7_wb_stb_i	( 1'b0 ),
	.i7_wb_adr_i	( 32'h0000_0000 ),
	.i7_wb_sel_i	( 4'b0000 ),
	.i7_wb_we_i	( 1'b0 ),
	.i7_wb_dat_i	( 32'h0000_0000 ),
	.i7_wb_dat_o	( ),
	.i7_wb_ack_o	( ),
	.i7_wb_err_o	( ),

	// WISHBONE Target 0 (ss: sram controller, 0x00)
	.t0_wb_cyc_o	( wb_ss_cyc_i ),
	.t0_wb_stb_o	( wb_ss_stb_i ),
	.t0_wb_adr_o	( wb_ss_adr_i ),
	.t0_wb_sel_o	( wb_ss_sel_i ),
	.t0_wb_we_o	( wb_ss_we_i  ),
	.t0_wb_dat_o	( wb_ss_dat_i ),
	.t0_wb_dat_i	( wb_ss_dat_o ),
	.t0_wb_ack_i	( wb_ss_ack_o ),
	.t0_wb_err_i	( wb_ss_err_o ),

	// WISHBONE Target 1  (fs: flash start, 0x04)
	.t1_wb_cyc_o	( wb_fs_cyc_i ),
	.t1_wb_stb_o	( wb_fs_stb_i ),
	.t1_wb_adr_o	( wb_fs_adr_i ),
	.t1_wb_sel_o	( wb_fs_sel_i ),
	.t1_wb_we_o	( wb_fs_we_i  ),
	.t1_wb_dat_o	( wb_fs_dat_i ),
	.t1_wb_dat_i	( wb_fs_dat_o ),
	.t1_wb_ack_i	( wb_fs_ack_o ),
	.t1_wb_err_i	( wb_fs_err_o ),

	// WISHBONE Target 2  (sp: spi flash)
	.t2_wb_cyc_o	( wb_sp_cyc_i ),
	.t2_wb_stb_o	( wb_sp_stb_i ),
	.t2_wb_adr_o	( wb_sp_adr_i ),
	.t2_wb_sel_o	( wb_sp_sel_i ),
	.t2_wb_we_o	( wb_sp_we_i  ),
	.t2_wb_dat_o	( wb_sp_dat_i ),
	.t2_wb_dat_i	( wb_sp_dat_o ),
	.t2_wb_ack_i	( wb_sp_ack_o ),
	.t2_wb_err_i	( wb_sp_err_o ),

	// WISHBONE Target 3  (es: ethernet slave)
	.t3_wb_cyc_o	( wb_es_cyc_i ),
	.t3_wb_stb_o	( wb_es_stb_i ),
	.t3_wb_adr_o	( wb_es_adr_i ),
	.t3_wb_sel_o	( wb_es_sel_i ),
	.t3_wb_we_o	( wb_es_we_i  ),
	.t3_wb_dat_o	( wb_es_dat_i ),
	.t3_wb_dat_i	( wb_es_dat_o ),
	.t3_wb_ack_i	( wb_es_ack_o ),
	.t3_wb_err_i	( wb_es_err_o ),

	// WISHBONE Target 4 (sfifos: sync fifo slave, 0x9d)
	.t4_wb_cyc_o	( wb_sfifos_cyc_i ),
	.t4_wb_stb_o	( wb_sfifos_stb_i ),
	.t4_wb_adr_o	( wb_sfifos_adr_i ),
	.t4_wb_sel_o	( wb_sfifos_sel_i ),
	.t4_wb_we_o	( wb_sfifos_we_i  ),
	.t4_wb_dat_o	( wb_sfifos_dat_i ),
	.t4_wb_dat_i	( wb_sfifos_dat_o ),
	.t4_wb_ack_i	( wb_sfifos_ack_o ),
	.t4_wb_err_i	( wb_sfifos_err_o ),
	
	// WISHBONE Target 5 (uart slave)
	.t5_wb_cyc_o	( wb_us_cyc_i ),
	.t5_wb_stb_o	( wb_us_stb_i ),
	.t5_wb_adr_o	( wb_us_adr_i ),
	.t5_wb_sel_o	( wb_us_sel_i ),
	.t5_wb_we_o	( wb_us_we_i  ),
	.t5_wb_dat_o	( wb_us_dat_i ),
	.t5_wb_dat_i	( wb_us_dat_o ),
	.t5_wb_ack_i	( wb_us_ack_o ),
	.t5_wb_err_i	( wb_us_err_o ),

	// WISHBONE Target 6 ()
	.t6_wb_cyc_o	( ),
	.t6_wb_stb_o	( ),
	.t6_wb_adr_o	( ),
	.t6_wb_sel_o	( ),
	.t6_wb_we_o	( ),
	.t6_wb_dat_o	( ),
	.t6_wb_dat_i	( 32'h0000_0000 ),
	.t6_wb_ack_i	( 1'b0 ),
	.t6_wb_err_i	( 1'b1 ),

	// WISHBONE Target 7 (ssifs: SSIF Slave, 0x9e)
	.t7_wb_cyc_o	( wb_ssif_cyc_o ),
	.t7_wb_stb_o	( wb_ssif_stb_o ),
	.t7_wb_adr_o	( wb_ssif_adr   ),
	.t7_wb_sel_o	( wb_ssif_sel_o ),
	.t7_wb_we_o	( wb_ssif_we_o  ),
	.t7_wb_dat_o	( wb_ssif_dat_o ),
	.t7_wb_dat_i	( wb_ssif_dat_i ),
	.t7_wb_ack_i	( wb_ssif_ack_i ),
	.t7_wb_err_i	( wb_ssif_err_i ),

	// WISHBONE Target 8 (0xf0)
	.t8_wb_cyc_o	( ),
	.t8_wb_stb_o	( ),
	.t8_wb_adr_o	( ),
	.t8_wb_sel_o	( ),
	.t8_wb_we_o	( ),
	.t8_wb_dat_o	( ),
	.t8_wb_dat_i	( 32'h0000_0000 ),
	.t8_wb_ack_i	( 1'b0 ),
	.t8_wb_err_i	( 1'b1 )
);

//initial begin
//  $dumpvars(0);
//  $dumpfile("dump.vcd");
//end

endmodule
