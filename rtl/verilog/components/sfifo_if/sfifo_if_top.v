//
// Bits of WISHBONE address used for partial decoding of SPI registers.
//
// Register Mapping wb_adr[5:2] (right offset by 2)
//
`define SFIFO_BP_TICK       4'h0
`define SFIFO_CTRL          4'h1
`define SFIFO_DI            4'h2
`define MAILBOX_OBUF        4'h3    // 0x0C ~ 0x0F, output data buffer to MAILBOX
`define SFIFO_DIN_0         4'b0100 // 0x10 ~ 0x13
`define SFIFO_DIN_1         4'b0101 // 0x14 ~ 0x17
`define SFIFO_DOUT          4'b0110 // 0x18 ~ 0x1B
`define SFIFO_ADC_BASE      4'b1??? // 0x20 ~ 0x3F, ADC Ch0 ~ Ch15
// For SFIFO_ADC_?: 
// ignore MSB of WB_ADR[] since it must be '1'
// add detection for wb_sel_i[1] for REG16() accessing
`define SFIFO_ADC_0         4'h0    
`define SFIFO_ADC_1         4'h1 
`define SFIFO_ADC_2         4'h2 
`define SFIFO_ADC_3         4'h3 
`define SFIFO_ADC_4         4'h4 
`define SFIFO_ADC_5         4'h5 
`define SFIFO_ADC_6         4'h6 
`define SFIFO_ADC_7         4'h7 
`define SFIFO_ADC_8         4'h8 
`define SFIFO_ADC_9         4'h9 
`define SFIFO_ADC_10        4'ha
`define SFIFO_ADC_11        4'hb
`define SFIFO_ADC_12        4'hc
`define SFIFO_ADC_13        4'hd
`define SFIFO_ADC_14        4'he
`define SFIFO_ADC_15        4'hf

module sfifo_if_top
#(
  parameter           WB_AW           = 0,    // lower address bits
  parameter           WB_DW           = 32,
  parameter           WOU_DW          = 0,
  parameter           SFIFO_DW        = 16,   // data width for SYNC_FIFO
  // parameter           DIN_W           = 0,
  parameter           DOUT_W          = 0,
  parameter           ADC_W           = 0     // width for ADC value
)
(
  // WISHBONE Interface
  output  reg [WB_DW-1:0]             wb_dat_o,
  output  reg                         wb_ack_o,
  input                               wb_clk_i,
  input                               wb_rst_i,
  input                               wb_cyc_i,
  input   [3:0]			      wb_sel_i,
  input   [WB_AW-1:2]                 wb_adr_i,   // lower address bits
  input   [WB_DW-1:0]                 wb_dat_i,   // data from wb_master
  input                               wb_we_i,
  input                               wb_stb_i,

  // SFIFO Interface (clk_500)
  output  reg                         sfifo_rd_o,
  input                               sfifo_full_i,
  input                               sfifo_empty_i,
  input   [SFIFO_DW-1:0]              sfifo_di,

  // MAILBOX Interface (clk_500)
  output                              mbox_wr_o,
  output  [WOU_DW-1:0]                mbox_do_o,
  input                               mbox_full_i,
  input                               mbox_afull_i,

  // SFIFO_CTRL Interface (clk_250)
  input                               sfifo_bp_tick_i,

  // GPIO Interface (clk_250)
  // SYNC_DOUT
  output  reg [DOUT_W-1:0]            dout_o,   // may support up to 32-bits of DOUT
  output  reg                         dout_we_o,
  input       [DOUT_W-1:0]            dout_i,
  // SYNC_DIN
  input       [31:0]                  din_0_i,  // may support up to 64-bits of DIN
  input       [31:0]                  din_1_i,  
  
  // ADC_SPI value (clk_250)
  input       [ADC_W-1:0]             adc_0_i,
  input       [ADC_W-1:0]             adc_1_i,
  input       [ADC_W-1:0]             adc_2_i,
  input       [ADC_W-1:0]             adc_3_i,
  input       [ADC_W-1:0]             adc_4_i,
  input       [ADC_W-1:0]             adc_5_i,
  input       [ADC_W-1:0]             adc_6_i,
  input       [ADC_W-1:0]             adc_7_i,
  input       [ADC_W-1:0]             adc_8_i,
  input       [ADC_W-1:0]             adc_9_i,
  input       [ADC_W-1:0]             adc_10_i,
  input       [ADC_W-1:0]             adc_11_i,
  input       [ADC_W-1:0]             adc_12_i,
  input       [ADC_W-1:0]             adc_13_i,
  input       [ADC_W-1:0]             adc_14_i,
  input       [ADC_W-1:0]             adc_15_i
);

reg               sfifo_bp_tick_s;
wire              bp_pulser;
reg               bp_tick_n;
reg [WB_DW-1:0]   bp_tick_cnt;
wire              sfifo_di_sel;

//not necessary: // to synchronize data from clk_250 to clk_500
//not necessary: reg [31:0]        din_s;
//not necessary: reg [ADC_W-1:0]   adc_s;

// signals for SYNC_DOUT
wire              dout_wr_sel;
reg [DOUT_W-1:0]  dout_tmp;   
reg               dout_we;

// signals for ADC input
reg [ADC_W-1:0]   adc;

// signals for MAILBOX
wire              mbox_wr_sel;
wire              mbox_busy;
reg [WB_DW-1:0]   next_mbox_buf;
reg [WB_DW-1:0]   mbox_buf;
reg [2:0]         mbox_shift;
reg               mbox_cs;
reg               mbox_ns;
parameter         MBOX_IDLE   = 1'b0,
                  MBOX_WR     = 1'b1;

// Address decoder
assign sfifo_di_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DI);
// wb_sel_i[3]: byte 0
assign dout_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT);
assign mbox_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `MAILBOX_OBUF);
   
// Wb acknowledge
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_ack_o <= 1'b0;
  else
    wb_ack_o <= wb_cyc_i & wb_stb_i & ~wb_ack_o 
                // block wb_ack_o if (sfifo_di_sel && sfifo_empty) 
                & ~(sfifo_di_sel & sfifo_empty_i)
                // block wb_ack_o if (mbox_wr_sel && ...) 
                & ~(mbox_wr_sel & (mbox_full_i | mbox_busy)) ;
end

// mux for ADC inputs
always @(*)
begin
  casez ({wb_adr_i[WB_AW-2:2], wb_sel_i[1]})  // synopsys parallel_case
    `SFIFO_ADC_0:     adc <= adc_0_i;
    `SFIFO_ADC_1:     adc <= adc_1_i;
    `SFIFO_ADC_2:     adc <= adc_2_i;
    `SFIFO_ADC_3:     adc <= adc_3_i;
    `SFIFO_ADC_4:     adc <= adc_4_i;
    `SFIFO_ADC_5:     adc <= adc_5_i;
    `SFIFO_ADC_6:     adc <= adc_6_i;
    `SFIFO_ADC_7:     adc <= adc_7_i;
    `SFIFO_ADC_8:     adc <= adc_8_i;
    `SFIFO_ADC_9:     adc <= adc_9_i;
    `SFIFO_ADC_10:    adc <= adc_10_i;
    `SFIFO_ADC_11:    adc <= adc_11_i;
    `SFIFO_ADC_12:    adc <= adc_12_i;
    `SFIFO_ADC_13:    adc <= adc_13_i;
    `SFIFO_ADC_14:    adc <= adc_14_i;
    `SFIFO_ADC_15:    adc <= adc_15_i;
    default:          adc <= 'bx;
  endcase
end

// Read from registers
// Wb data out
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_dat_o <= 32'b0;
  else
    casez (wb_adr_i[WB_AW-1:2])  // synopsys parallel_case
      `SFIFO_BP_TICK:   wb_dat_o  <= {bp_tick_cnt};
      `SFIFO_CTRL:      wb_dat_o  <= {28'd0, mbox_afull_i, mbox_full_i, sfifo_full_i, sfifo_empty_i};
      `SFIFO_DI:        wb_dat_o  <= {sfifo_di, 16'd0}; 
      `SFIFO_DOUT:      wb_dat_o  <= {{(32-DOUT_W){1'b0}}, dout_i};
      `SFIFO_DIN_0:     wb_dat_o  <= {din_0_i};
      `SFIFO_DIN_1:     wb_dat_o  <= {din_1_i};
      `SFIFO_ADC_BASE:  wb_dat_o  <= {{(16-ADC_W){1'b0}}, adc, 16'h00};
      default:          wb_dat_o  <= 'bx;
    endcase
end

always @(posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_rd_o <= 0;
  else
    sfifo_rd_o <= sfifo_di_sel & (~sfifo_empty_i) & ~wb_ack_o; // (~wb_ack_o): prevent from reading sfifo twice

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

// to synchronize DOUT with Base Period Pulser
always @ (posedge wb_clk_i)
  if (bp_pulser) begin
    dout_we_o   <= dout_we;
    dout_o      <= dout_tmp;
    // dout_set_o <= dout_set;
    // dout_rst_o <= dout_rst;
  end
  
always @ (posedge wb_clk_i)
  if (wb_rst_i | bp_pulser) begin
    dout_we       <= 0; // reset dout_we to 0 at each base-period
    dout_tmp      <= 0;
    // dout_set  <= 0;
    // dout_rst  <= 0;
  end else if (dout_wr_sel) begin
    dout_we       <= 1;
    dout_tmp      <= wb_dat_i[DOUT_W-1:0];
    // dout_set  <= dout_set | next_dout_set;
    // dout_rst  <= dout_rst | next_dout_rst;
  end

//obsolete: always @ (*) 
//obsolete: begin
//obsolete:     casez (wb_dat_i[31:24]) // synopsys parallel_case
//obsolete:       8'b1?000000: begin next_dout_set <= {7'h0,  wb_dat_i[30]      };  // dout[0]
//obsolete:                          next_dout_rst <= {7'h0, ~wb_dat_i[30]      }; end 
//obsolete:       8'b1?000001: begin next_dout_set <= {6'h0,  wb_dat_i[30], 1'h0}; // dout[1]
//obsolete:                          next_dout_rst <= {6'h0, ~wb_dat_i[30], 1'h0}; end 
//obsolete:       8'b1?000010: begin next_dout_set <= {5'h0,  wb_dat_i[30], 2'h0}; // dout[2]
//obsolete:                          next_dout_rst <= {5'h0, ~wb_dat_i[30], 2'h0}; end      
//obsolete:       8'b1?000011: begin next_dout_set <= {4'h0,  wb_dat_i[30], 3'h0}; // dout[3]
//obsolete:                          next_dout_rst <= {4'h0, ~wb_dat_i[30], 3'h0}; end      
//obsolete:       8'b1?000100: begin next_dout_set <= {3'h0,  wb_dat_i[30], 4'h0}; // dout[4]
//obsolete:                          next_dout_rst <= {3'h0, ~wb_dat_i[30], 4'h0}; end      
//obsolete:       8'b1?000101: begin next_dout_set <= {2'h0,  wb_dat_i[30], 5'h0}; // dout[5]
//obsolete:                          next_dout_rst <= {2'h0, ~wb_dat_i[30], 5'h0}; end      
//obsolete:       8'b1?000110: begin next_dout_set <= {1'h0,  wb_dat_i[30], 6'h0}; // dout[6]
//obsolete:                          next_dout_rst <= {1'h0, ~wb_dat_i[30], 6'h0}; end      
//obsolete:       8'b1?000111: begin next_dout_set <= {       wb_dat_i[30], 7'h0}; // dout[7]
//obsolete:                          next_dout_rst <= {      ~wb_dat_i[30], 7'h0}; end 
//obsolete:       default:     begin next_dout_set <= 8'h00;                       // Disable dout
//obsolete:                          next_dout_rst <= 8'h00;                       end
//obsolete:     endcase
//obsolete: end    

//not necessary: // to synchronize from clk_250 to clk_500
//not necessary: always @(posedge wb_clk_i)
//not necessary:   if (wb_rst_i) begin
//not necessary:     adc_s     <= 0;
//not necessary:     din_s     <= 0;
//not necessary:   end else begin
//not necessary:     adc_s     <= adc_i;
//not necessary:     din_s     <= din_i;
//not necessary:   end


// begin: write to MAILBOX
  
/**
 *  - to convert mbox_buf[] from big-endian to little-endian for WOU
 *
 **/
assign mbox_busy = (mbox_cs == MBOX_WR);
assign mbox_wr_o = (~mbox_full_i) & (mbox_cs == MBOX_WR);
assign mbox_do_o = mbox_buf[7:0]; // least-significant-byte first

always @(*)
  if (mbox_cs == MBOX_IDLE)
    next_mbox_buf <= wb_dat_i;
  else
    next_mbox_buf <= {8'h00, mbox_buf[31:8]};

always @(posedge wb_clk_i)
  if (wb_rst_i)
    mbox_buf    <= 0;
  else if (~mbox_full_i)
    mbox_buf    <= next_mbox_buf;

always @(posedge wb_clk_i)
  if (mbox_cs == MBOX_IDLE)
    mbox_shift  <= 3'b111;
  else if (~mbox_full_i)
    mbox_shift  <= {mbox_shift[1:0], 1'b0};

always @(posedge wb_clk_i)
  if (wb_rst_i)
    mbox_cs <= MBOX_IDLE;
  else
    mbox_cs <= mbox_ns;

always @(*)
begin
  case (mbox_cs) // synopsys parallel_case
    MBOX_IDLE: begin
      // load wb_dat_i into mbox_buf at this state 
      if (mbox_wr_sel & (~mbox_full_i))
        mbox_ns <= MBOX_WR;
      else
        mbox_ns <= MBOX_IDLE;
    end

    MBOX_WR: begin
      if ((mbox_shift[2] == 1'b0) & (~mbox_full_i))
        mbox_ns <= MBOX_IDLE;
      else
        mbox_ns <= MBOX_WR;
    end
    default: mbox_ns <= 'bx;
  endcase
end

// end: write to MAILBOX

endmodule
