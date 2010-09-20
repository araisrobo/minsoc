//
// Bits of WISHBONE address used for partial decoding of SPI registers.
//
`define SFIFO_OFS_BITS	    4:2

//
// Register offset
//
`define SFIFO_BP_TICK       0
`define SFIFO_CTRL          1
`define SFIFO_DI            2

module sfifo_if_top
#(
  parameter           WB_LAW          = 5,    // lower address bits
  parameter           WB_DW           = 32,
  parameter           SFIFO_DW        = 16    // data width for SYNC_FIFO
)
(
  // WISHBONE Interface
  output  reg [WB_DW-1:0]             wb_dat_o,
  output  reg                         wb_ack_o,
  input                               wb_clk_i,
  input                               wb_rst_i,
  input                               wb_cyc_i,
  input   [3:0]			      wb_sel_i,
  input   [WB_LAW-1:0]                wb_adr_i,   // lower address bits
  input   [WB_DW-1:0]                 wb_dat_i,   // data from wb_master
  input                               wb_we_i,
  input                               wb_stb_i,

  // SFIFO Interface (clk_500)
  output  reg                         sfifo_rd_o,
  input                               sfifo_empty_i,
  input   [SFIFO_DW-1:0]              sfifo_di,

  // SFIFO_CTRL Interface (clk_250)
  input                               sfifo_bp_tick_i
);

reg               sfifo_bp_tick_s;
wire              bp_pulser;
reg               bp_tick_n;
reg [WB_DW-1:0]   bp_tick_cnt;
wire              bp_tick_sel;

wire              sfifo_di_sel;

// Address decoder
assign bp_tick_sel  = wb_cyc_i & wb_stb_i & (wb_adr_i[`SFIFO_OFS_BITS] == `SFIFO_BP_TICK);
assign sfifo_di_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[`SFIFO_OFS_BITS] == `SFIFO_DI);
   
// Wb acknowledge
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_ack_o <= 1'b0;
  else
    wb_ack_o <= wb_cyc_i & wb_stb_i & ~wb_ack_o 
                // block wb_ack_o if (sfifo_di_sel && sfifo_empty) 
                & ~(sfifo_di_sel & sfifo_empty_i);
end
   
// Read from registers
// Wb data out
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_dat_o <= 32'b0;
  else
    case (wb_adr_i[`SFIFO_OFS_BITS])  // synopsys parallel_case
      `SFIFO_BP_TICK:   wb_dat_o  <= {bp_tick_cnt};
      `SFIFO_CTRL:      wb_dat_o  <= {31'd0, sfifo_empty_i};
      `SFIFO_DI:        wb_dat_o  <= {16'd0, sfifo_di}; 
      default:          wb_dat_o  <= 'bx;
    endcase
end

always @(posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_rd_o <= 0;
  else
    sfifo_rd_o <= sfifo_di_sel & (~sfifo_empty_i);

// sync from clk_250 to clk_500
always @ (posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_bp_tick_s <= 0;
  else 
    sfifo_bp_tick_s <= sfifo_bp_tick_i;

// pulser for bp_tick
assign bp_pulser = sfifo_bp_tick_s & bp_tick_n;
always @ (posedge wb_clk_i)
  if (wb_rst_i)
    bp_tick_n <= 1;
  else
    bp_tick_n <= ~sfifo_bp_tick_s;

always @ (posedge wb_clk_i)
  if (wb_rst_i)
    bp_tick_cnt <= 0;
  else if (bp_pulser)
    bp_tick_cnt <= bp_tick_cnt + 1;

endmodule