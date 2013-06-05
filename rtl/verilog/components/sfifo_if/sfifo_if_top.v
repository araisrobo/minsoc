//
// Bits of WISHBONE address used for partial decoding of SPI registers.
//
// Register Mapping wb_adr[5:2] (right offset by 2)
//
`define SFIFO_BP_TICK       5'h0
`define SFIFO_CTRL          5'h1
`define SFIFO_DI            5'h2    // FIFO-DATA-INPUT
`define MAILBOX_OBUF        5'h3    // 0x0C ~ 0x0F, output data buffer to MAILBOX
`define SFIFO_DIN_0         5'h4    // 0x10 ~ 0x13
`define SFIFO_DIN_1         5'h5    // 0x14 ~ 0x17
`define SFIFO_DIN_2         5'h6    // 0x18 ~ 0x1B
`define SFIFO_DOUT_0        5'h7    // 0x1C ~ 0x1F
`define SFIFO_ADC_BASE      5'b01??? // 0x20 ~ 0x3F, ADC Ch0 ~ Ch15
`define SFIFO_ADC_01        3'h0    
`define SFIFO_ADC_23        3'h1 
`define SFIFO_ADC_45        3'h2 
`define SFIFO_ADC_67        3'h3 
`define SFIFO_ADC_89        3'h4 
`define SFIFO_ADC_AB        3'h5 
`define SFIFO_ADC_CD        3'h6 
`define SFIFO_ADC_EF        3'h7 
`define SFIFO_RT_CMD        5'h10   // 0x40 ~ 0x43
`define SFIFO_ESTOP_OUT_0   5'h12   // 0x48 ~ 0x4B

module sfifo_if_top
#(
  parameter           WB_AW         = 0,    // lower address bits
  parameter           WB_DW         = 32,
  parameter           WOU_DW        = 0,
  parameter           SFIFO_DW      = 16,   // data width for SYNC_FIFO
  // fixed 64-IN, 32-OUT
  // parameter           DIN_W         = 0,
  // parameter           DOUT_W        = 0,
  parameter           ADC_W         = 0     // width for ADC value
)
(
  // WISHBONE Interface
  output  reg [WB_DW-1:0]           wb_dat_o,
  output  reg                       wb_ack_o,
  input                             wb_clk_i,
  input                             wb_rst_i,
  input                             wb_cyc_i,
  input   [3:0]			    wb_sel_i,
  input   [WB_AW-1:2]               wb_adr_i,   // lower address bits
  input   [WB_DW-1:0]               wb_dat_i,   // data from wb_master
  input                             wb_we_i,
  input                             wb_stb_i,

  // SFIFO Interface (clk_500)
  output  reg                       sfifo_rd_o,
  input                             sfifo_full_i,
  input                             sfifo_empty_i,
  input   [SFIFO_DW-1:0]            sfifo_di,

  // MAILBOX Interface (clk_500)
  output                            mbox_wr_o,
  output  [WOU_DW-1:0]              mbox_do_o,
  input                             mbox_full_i,
  input                             mbox_afull_i,
  input                             mbox_empty_i,

  // SFIFO_CTRL Interface (clk_250)
  input                             sfifo_bp_tick_i,

  // RT_CMD Interface (clk_250)
  output                            rt_cmd_rst_o,
  input   [WB_DW-1:0]               rt_cmd_i,

  // GPIO Interface (clk_250)
  // SYNC_DOUT
  output  reg [WB_DW-1:0]           dout_0_o,   // may support up to 32-bits of DOUT
  input                             alarm_i,

  // SYNC_DIN
  input       [WB_DW-1:0]           din_0_i,  // may support up to 64-bits of DIN
  input       [WB_DW-1:0]           din_1_i,  
  input       [     15:0]           din_2_i,  
  
  // ADC_SPI value (clk_250)
  input       [ADC_W-1:0]           adc_0_i,
  input       [ADC_W-1:0]           adc_1_i,
  input       [ADC_W-1:0]           adc_2_i,
  input       [ADC_W-1:0]           adc_3_i,
  input       [ADC_W-1:0]           adc_4_i,
  input       [ADC_W-1:0]           adc_5_i,
  input       [ADC_W-1:0]           adc_6_i,
  input       [ADC_W-1:0]           adc_7_i,
  input       [ADC_W-1:0]           adc_8_i,
  input       [ADC_W-1:0]           adc_9_i,
  input       [ADC_W-1:0]           adc_10_i,
  input       [ADC_W-1:0]           adc_11_i,
  input       [ADC_W-1:0]           adc_12_i,
  input       [ADC_W-1:0]           adc_13_i,
  input       [ADC_W-1:0]           adc_14_i,
  input       [ADC_W-1:0]           adc_15_i
);

wire                rt_cmd_sel;
reg                 rt_cmd_sel_s;
reg [WB_DW-1:0]     rt_cmd_s;

reg                 sfifo_bp_tick_s;
wire                bp_pulser;
reg                 bp_tick_n;
reg [WB_DW-1:0]     bp_tick_cnt;
wire                sfifo_di_sel;

// signals for SYNC_DOUT
wire                dout_0_wr_sel;
reg [WB_DW-1:0]     estop_out_0; // output value for ESTOP
wire                estop_out_0_wr_sel;

// signals for ADC input
reg [ADC_W-1:0]   adc_lo;
reg [ADC_W-1:0]   adc_hi;

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

initial begin
    // initialized value right after FPGA configuration
    estop_out_0 = 0;
    dout_0_o = 0;
    //obsolete: r_out = 8'h00;
end

// Address decoder
assign sfifo_di_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DI);
// wb_sel_i[3]: byte 0
assign estop_out_0_wr_sel = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_ESTOP_OUT_0);
assign dout_0_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT_0);
assign mbox_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `MAILBOX_OBUF);
assign rt_cmd_sel   = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_RT_CMD);

//**********************************************************************************
// Code for simulation purposes only 
//**********************************************************************************
//synopsys translate_off

wire adc_rd_sel;
assign adc_rd_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1] == 1'b1);

//synopsys translate_on
//**********************************************************************************
// End of simulation code.
//**********************************************************************************



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
  casez ({wb_adr_i[WB_AW-2:2]})  // synopsys parallel_case
    `SFIFO_ADC_01:  begin adc_lo <= adc_0_i;  adc_hi <= adc_1_i;  end
    `SFIFO_ADC_23:  begin adc_lo <= adc_2_i;  adc_hi <= adc_3_i;  end
    `SFIFO_ADC_45:  begin adc_lo <= adc_4_i;  adc_hi <= adc_5_i;  end
    `SFIFO_ADC_67:  begin adc_lo <= adc_6_i;  adc_hi <= adc_7_i;  end
    `SFIFO_ADC_89:  begin adc_lo <= adc_8_i;  adc_hi <= adc_9_i;  end
    `SFIFO_ADC_AB:  begin adc_lo <= adc_10_i; adc_hi <= adc_11_i; end
    `SFIFO_ADC_CD:  begin adc_lo <= adc_12_i; adc_hi <= adc_13_i; end
    `SFIFO_ADC_EF:  begin adc_lo <= adc_14_i; adc_hi <= adc_15_i; end
    default:        begin adc_lo <= 'bx;      adc_hi <= 'bx; end
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
      `SFIFO_CTRL:      wb_dat_o  <= {27'd0, mbox_empty_i, mbox_afull_i, mbox_full_i, sfifo_full_i, sfifo_empty_i};
      `SFIFO_DI:        wb_dat_o  <= {sfifo_di, 16'd0}; 
      `SFIFO_DIN_0:     wb_dat_o  <= {din_0_i};
      `SFIFO_DIN_1:     wb_dat_o  <= {din_1_i};
      `SFIFO_DIN_2:     wb_dat_o  <= {16'd0, din_2_i};
      `SFIFO_DOUT_0:    wb_dat_o  <= {dout_0_o};
      `SFIFO_ADC_BASE:  wb_dat_o  <= {{(16-ADC_W){1'b0}}, adc_lo, {(16-ADC_W){1'b0}}, adc_hi};
      `SFIFO_RT_CMD:    wb_dat_o  <= rt_cmd_s;
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
        rt_cmd_s        <= 0;
    else 
        rt_cmd_s        <= rt_cmd_i;

// generate rt_cmd reset signal from clk_500 to clk_250
assign rt_cmd_rst_o = rt_cmd_sel | rt_cmd_sel_s;
always @ (posedge wb_clk_i)
    if (wb_rst_i)
        rt_cmd_sel_s    <= 0;
    else 
        rt_cmd_sel_s    <= rt_cmd_sel;

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

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_0_o[7:0]       <= 0;
    else if (alarm_i)
        dout_0_o[7:0]       <= estop_out_0[7:0];
    else if (dout_0_wr_sel & wb_sel_i[0]) begin
        dout_0_o[7:0]       <= wb_dat_i[7:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_0_o[15:8]      <= 0;
    else if (alarm_i)
        dout_0_o[15:8]      <= estop_out_0[15:8];
    else if (dout_0_wr_sel & wb_sel_i[1]) begin
        dout_0_o[15:8]      <= wb_dat_i[15:8];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_0_o[23:16]     <= 0;
    else if (alarm_i)
        dout_0_o[23:16]     <= estop_out_0[23:16];
    else if (dout_0_wr_sel & wb_sel_i[2]) begin
        dout_0_o[23:16]     <= wb_dat_i[23:16];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_0_o[31:24]     <= 0;
    else if (alarm_i)
        dout_0_o[31:24]     <= estop_out_0[31:24];
    else if (dout_0_wr_sel & wb_sel_i[3]) begin
        dout_0_o[31:24]     <= wb_dat_i[31:24];
    end

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

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        estop_out_0[7:0]     <= 0;
    else if (estop_out_0_wr_sel & wb_sel_i[0]) begin
        estop_out_0[7:0]     <= wb_dat_i[7:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        estop_out_0[15:8]     <= 0;
    else if (estop_out_0_wr_sel & wb_sel_i[1]) begin
        estop_out_0[15:8]     <= wb_dat_i[15:8];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        estop_out_0[23:16]     <= 0;
    else if (estop_out_0_wr_sel & wb_sel_i[2]) begin
        estop_out_0[23:16]     <= wb_dat_i[23:16];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        estop_out_0[31:24]     <= 0;
    else if (estop_out_0_wr_sel & wb_sel_i[3]) begin
        estop_out_0[31:24]     <= wb_dat_i[31:24];
    end


endmodule
