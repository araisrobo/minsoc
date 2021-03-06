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
`define SFIFO_DIN_2         5'h6    // 0x18 ~ 0x1B 00110..
`define SFIFO_DIN_3         5'h7    // 0x1C ~ 0x1F 00111..
`define SFIFO_ADC_BASE      5'b01??? // 0x20 ~ 0x3F, ADC Ch0 ~ Ch15
`define SFIFO_ADC_01        3'h0    
`define SFIFO_ADC_23        3'h1 
`define SFIFO_ADC_45        3'h2 
`define SFIFO_ADC_67        3'h3 
`define SFIFO_ADC_89        3'h4 
`define SFIFO_ADC_AB        3'h5 
`define SFIFO_ADC_CD        3'h6 
`define SFIFO_ADC_EF        3'h7 
`define SFIFO_ADC_PRE_CMD   5'h10   // ADC_CMD(0x42 ~ 0x43)
`define SFIFO_ESTOP_OUT_0   5'h12   // 0x48 ~ 0x4B 100_10..

`define SFIFO_DAC_PREFIX    3'b101      // 0x50 ~ 0x5F, DAC Ch0 ~ Ch3
`define SFIFO_DAC_BASE      5'b101??    // 0x50 ~ 0x5F, DAC Ch0 ~ Ch3
`define SFIFO_DAC_0         2'h0        // for 0x50
`define SFIFO_DAC_1         2'h1        // for 0x54
`define SFIFO_DAC_2         2'h2        // for 0x58
`define SFIFO_DAC_3         2'h3        // for 0x5C

`define SFIFO_DOUT_0        5'h18   // 0x60 ~ 0x63 110_00..
`define SFIFO_DOUT_1        5'h19   // 0x64 ~ 0x67 110_01..
`define SFIFO_DOUT_2        5'h1A   // 0x68 ~ 0x6B 110_10..

`define SFIFO_PWM_PREFIX    3'b111      // 0x70 ~ 0x7F, PWM Ch0 ~ Ch3
`define SFIFO_PWM_BASE      5'b111??    // 0x70 ~ 0x7F, PWM Ch0 ~ Ch3
`define SFIFO_PWM_0         2'h0        // for 0x70
`define SFIFO_PWM_1         2'h1        // for 0x74
`define SFIFO_PWM_2         2'h2        // for 0x78
`define SFIFO_PWM_3         2'h3        // for 0x7C

module sfifo_if_top
#(
  parameter           WB_AW         = 0,    // lower address bits
  parameter           WB_DW         = 32,
  parameter           WOU_DW        = 0,
  parameter           SFIFO_DW      = 16,   // data width for SYNC_FIFO
  parameter           PWM_NUM       = 0,    // number of PWM port
  parameter           ADC_CMD_W     = 0,    // width for ADC PREAMBLE and CMD
  parameter           ADC_CH_W      = 0,
  parameter           ADC_W         = 0,    // width for ADC value
  parameter           DAC_W         = 0,    // width for DAC command
  parameter           DAC_CH_W      = 0     // width for DAC_CH
)
(
  input                             clk_250,
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
  input                             sfifo_full_i,   // connects to JFIFO.BURST_RD_RDY
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

  // ADC_CMD registers (clk_250)
  output  reg                       adc_cmd_wr_o,
  output  reg [ADC_CMD_W-1:0]       adc_cmd_o,  // ADC_CMD

  // GPIO Interface (clk_250)
  // PWM
  output      [PWM_NUM-1:0]         pwm_o,

  // SYNC_DOUT
  output  reg [WB_DW-1:0]           dout_0_o,   // [7:0]=>AR11.EXT, [31:8]=>internal-register-map
  output  reg [WB_DW-1:0]           dout_1_o,   // [63:32]=>AR15
  output  reg [WB_DW-1:0]           dout_2_o,   // [95:64]=>AR15
  input                             alarm_i,

  // SYNC_DIN
  input       [WB_DW-1:0]           din_0_i,    
  input       [WB_DW-1:0]           din_1_i,  
  input       [WB_DW-1:0]           din_2_i,    
  input       [WB_DW-1:0]           din_3_i,    // support up to 128-bits of DIN
  
  // ADC_SPI value (clk_250)
  input       [ADC_W-1:0]           adc_lo_i,
  input       [ADC_W-1:0]           adc_hi_i,
  output      [ADC_CH_W-2:0]        adc_ch_sel_o,
  
  // DAC_SPI CMD (clk_250)
  output  reg [DAC_W-1:0]           dac_0_o,
  output  reg [DAC_W-1:0]           dac_1_o,
  output  reg [DAC_W-1:0]           dac_2_o,
  output  reg [DAC_W-1:0]           dac_3_o
);

wire                adc_pre_cmd_sel;

reg                 sfifo_bp_tick_s;
wire                bp_pulser;
reg                 bp_tick_n;
reg [WB_DW-1:0]     bp_tick_cnt;
wire                sfifo_di_sel;

// signals for SYNC_DOUT
wire                dout_0_wr_sel;
wire                dout_1_wr_sel;
wire                dout_2_wr_sel;
//TODO: remove estop_out_0, which is replaced by RISC
reg [WB_DW-1:0]     estop_out_0; // output value for ESTOP
wire                estop_out_0_wr_sel;

// signals for DAC command
reg [DAC_W-1:0]     dac;  // reading
wire                dac_wr_sel;

// signals for PWM command
parameter integer   PWM_W = 32; // {freq[15:0], duty[15:0]}
wire                pwm_wr_sel;
reg [PWM_W-1:0]     pwm_0;      // {freq[15:0], duty[15:0]}
reg [PWM_W-1:0]     pwm_1;
reg [PWM_W-1:0]     pwm_2;
reg [PWM_W-1:0]     pwm_3;

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
    dout_1_o = 0;
    dout_2_o = 0;
end

// Address decoder
assign sfifo_di_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DI);
// wb_sel_i[3]: byte 0
// wb_sel_i[2]: byte 1
// wb_sel_i[1]: byte 2
// wb_sel_i[0]: byte 3
assign estop_out_0_wr_sel = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_ESTOP_OUT_0);
assign dout_0_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT_0);
assign dout_1_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT_1);
assign dout_2_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_DOUT_2);
assign mbox_wr_sel  = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:2] == `MAILBOX_OBUF);
assign dac_wr_sel   = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:4] == `SFIFO_DAC_PREFIX);
assign pwm_wr_sel   = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[WB_AW-1:4] == `SFIFO_PWM_PREFIX);

assign adc_pre_cmd_sel   = wb_cyc_i & wb_stb_i & (wb_adr_i[WB_AW-1:2] == `SFIFO_ADC_PRE_CMD);

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

assign adc_ch_sel_o = wb_adr_i[ADC_CH_W:2];

// mux for DAC commands, WB_AW is 7
always @(*)
begin
  casez ({wb_adr_i[WB_AW-4:2]})  // synopsys parallel_case
    `SFIFO_DAC_0:  begin dac <= dac_0_o; end
    `SFIFO_DAC_1:  begin dac <= dac_1_o; end
    `SFIFO_DAC_2:  begin dac <= dac_2_o; end
    `SFIFO_DAC_3:  begin dac <= dac_3_o; end
    default:       begin dac <= 'bx;     end
  endcase
end


// Read from registers
// Wb data out
always @(posedge wb_clk_i)
begin
  if (wb_rst_i)
    wb_dat_o <= 32'b0;
  else
    // sfifo_full_i: connects to JFIFO.BURST_RD_RDY 
    casez (wb_adr_i[WB_AW-1:2])  // synopsys parallel_case
      `SFIFO_BP_TICK:   wb_dat_o  <= {bp_tick_cnt};
      `SFIFO_CTRL:      wb_dat_o  <= {27'd0, mbox_empty_i, mbox_afull_i, mbox_full_i, sfifo_full_i, sfifo_empty_i};
      `SFIFO_DI:        wb_dat_o  <= {sfifo_di, 16'd0}; 
      `SFIFO_DIN_0:     wb_dat_o  <= {din_0_i};
      `SFIFO_DIN_1:     wb_dat_o  <= {din_1_i};
      `SFIFO_DIN_2:     wb_dat_o  <= {din_2_i};
      `SFIFO_DIN_3:     wb_dat_o  <= {din_3_i};
      `SFIFO_DOUT_0:    wb_dat_o  <= {dout_0_o};
      `SFIFO_DOUT_1:    wb_dat_o  <= {dout_1_o};
      `SFIFO_DOUT_2:    wb_dat_o  <= {dout_2_o};
      `SFIFO_ADC_BASE:  wb_dat_o  <= {{(16-ADC_W){adc_lo_i[ADC_W-1]}}, adc_lo_i, {(16-ADC_W){adc_hi_i[ADC_W-1]}}, adc_hi_i};
      `SFIFO_DAC_BASE:  wb_dat_o  <= {{(32-DAC_W){1'b0}}, dac};
//rt_cmd:      `SFIFO_RT_CMD:    wb_dat_o  <= rt_cmd_s;
      default:          wb_dat_o  <= 'bx;
    endcase
end

always @(posedge wb_clk_i)
  if (wb_rst_i)
    sfifo_rd_o <= 0;
  else
    sfifo_rd_o <= sfifo_di_sel & (~sfifo_empty_i) & ~wb_ack_o; // (~wb_ack_o): prevent from reading sfifo twice

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        adc_cmd_o[7:0]      <= 0;
    else if (adc_pre_cmd_sel & wb_sel_i[0]) begin   // 0x43->sel[0]
        adc_cmd_o[7:0]      <= wb_dat_i[7:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        adc_cmd_o[15:8]     <= 0;
    else if (adc_pre_cmd_sel & wb_sel_i[1]) begin   // 0x42->sel[1]
        adc_cmd_o[15:8]     <= wb_dat_i[15:8];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        adc_cmd_wr_o        <= 0;
    else 
        adc_cmd_wr_o        <= adc_pre_cmd_sel;

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

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_1_o[7:0]       <= 0;
    else if (dout_1_wr_sel & wb_sel_i[0]) begin
        dout_1_o[7:0]       <= wb_dat_i[7:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_1_o[15:8]      <= 0;
    else if (dout_1_wr_sel & wb_sel_i[1]) begin
        dout_1_o[15:8]      <= wb_dat_i[15:8];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_1_o[23:16]     <= 0;
    else if (dout_1_wr_sel & wb_sel_i[2]) begin
        dout_1_o[23:16]     <= wb_dat_i[23:16];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_1_o[31:24]     <= 0;
    else if (dout_1_wr_sel & wb_sel_i[3]) begin
        dout_1_o[31:24]     <= wb_dat_i[31:24];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_2_o[7:0]       <= 0;
    else if (dout_2_wr_sel & wb_sel_i[0]) begin
        dout_2_o[7:0]       <= wb_dat_i[7:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_2_o[15:8]      <= 0;
    else if (dout_2_wr_sel & wb_sel_i[1]) begin
        dout_2_o[15:8]      <= wb_dat_i[15:8];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_2_o[23:16]     <= 0;
    else if (dout_2_wr_sel & wb_sel_i[2]) begin
        dout_2_o[23:16]     <= wb_dat_i[23:16];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dout_2_o[31:24]     <= 0;
    else if (dout_2_wr_sel & wb_sel_i[3]) begin
        dout_2_o[31:24]     <= wb_dat_i[31:24];
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

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dac_0_o             <= 0;   // NOP
    else if (dac_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_DAC_0)) begin
        dac_0_o             <= wb_dat_i[DAC_W-1:0];
    end
  
always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dac_1_o             <= 0;   // NOP
    else if (dac_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_DAC_1)) begin
        dac_1_o             <= wb_dat_i[DAC_W-1:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dac_2_o             <= 0;   // NOP
    else if (dac_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_DAC_2)) begin
        dac_2_o             <= wb_dat_i[DAC_W-1:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        dac_3_o             <= 0;   // NOP
    else if (dac_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_DAC_3)) begin
        dac_3_o             <= wb_dat_i[DAC_W-1:0];
    end

    
always @ (posedge wb_clk_i)
    if (wb_rst_i)
        pwm_0               <= 0;   // NOP
    else if (pwm_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_PWM_0)) begin
        pwm_0               <= wb_dat_i[PWM_W-1:0];
    end
  
always @ (posedge wb_clk_i)
    if (wb_rst_i)
        pwm_1               <= 0;   // NOP
    else if (pwm_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_PWM_1)) begin
        pwm_1               <= wb_dat_i[PWM_W-1:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        pwm_2               <= 0;   // NOP
    else if (pwm_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_PWM_2)) begin
        pwm_2               <= wb_dat_i[PWM_W-1:0];
    end

always @ (posedge wb_clk_i)
    if (wb_rst_i)
        pwm_3               <= 0;   // NOP
    else if (pwm_wr_sel & (wb_adr_i[WB_AW-4:2] == `SFIFO_PWM_3)) begin
        pwm_3               <= wb_dat_i[PWM_W-1:0];
    end

pwm #(.PWM_W (PWM_W)) pwm0 (
    .clk        (clk_250), // clk_250, 25MHz
    .rst        (wb_rst_i),
    .pwm_o      (pwm_o[0]),
    .pwm_i      (pwm_0)     // pwm registers {freq[15:0], duty[15:0]}
);

pwm #(.PWM_W (PWM_W)) pwm1 (
    .clk        (clk_250), // clk_250, 25MHz
    .rst        (wb_rst_i),
    .pwm_o      (pwm_o[1]),
    .pwm_i      (pwm_1)     // pwm registers {freq[15:0], duty[15:0]}
);

pwm #(.PWM_W (PWM_W)) pwm2 (
    .clk        (clk_250), // clk_250, 25MHz
    .rst        (wb_rst_i),
    .pwm_o      (pwm_o[2]),
    .pwm_i      (pwm_2)     // pwm registers {freq[15:0], duty[15:0]}
);

pwm #(.PWM_W (PWM_W)) pwm3 (
    .clk        (clk_250), // clk_250, 25MHz
    .rst        (wb_rst_i),
    .pwm_o      (pwm_o[3]),
    .pwm_i      (pwm_3)     // pwm registers {freq[15:0], duty[15:0]}
);

endmodule
